//
//  ObservationEditViewDataStore.m
//  MAGE
//
//

#import "ObservationEditViewDataStore.h"
#import "ObservationEditTableViewCell.h"
#import "AttachmentEditTableViewCell.h"
#import "ObservationEditGeometryTableViewCell.h"
#import "ObservationFields.h"

#import <Server.h>
#import <Event.h>

static NSInteger const ATTACHMENT_SECTION = 0;
static NSInteger const COMMON_SECTION = 1;

@interface ObservationEditViewDataStore ()
@property (nonatomic, strong) NSDateFormatter *dateDisplayFormatter;
@property (nonatomic, strong) NSDateFormatter *dateParseFormatter;
@property (nonatomic, strong) NSArray *rowToCellType;
@property (nonatomic, strong) NSArray *rowToField;
@property (nonatomic, assign) NSInteger expandedRow;
@property (nonatomic, strong) NSNumber *eventId;
@property (nonatomic, strong) NSString *variantField;
@property (nonatomic, strong) NSMutableArray *invalidIndexPaths;
@property (nonatomic, strong) NSArray *forms;
@property (nonatomic, strong) NSArray *observationForms;
@property (strong, nonatomic) NSMutableArray *formFields;
@property (nonatomic, strong) NSString *primaryField;

@end

@implementation ObservationEditViewDataStore

- (BOOL) validate {
    self.invalidIndexPaths = [[NSMutableArray alloc] init];
    
//    for (NSInteger i = 0; i < [self.editTable numberOfRowsInSection:PROPERTIES_SECTION]; ++i) {
//        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:PROPERTIES_SECTION];
//        ObservationEditTableViewCell *cell = (ObservationEditTableViewCell *) [self tableView:self.editTable cellForRowAtIndexPath:indexPath];
//        if (![cell isValid]) {
//            [self.invalidIndexPaths addObject:indexPath];
//        }
//    }
//    
//    if ([self.invalidIndexPaths count] > 0) {
//        [self.editTable reloadRowsAtIndexPaths:self.invalidIndexPaths withRowAnimation:UITableViewRowAnimationNone];
//        [self.editTable scrollToRowAtIndexPath:[self.invalidIndexPaths firstObject] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
//        return NO;
//    }
    
    return YES;
}

- (NSArray *) forms {
    if (_forms != nil) {
        return _forms;
    }
    _forms = [Event getCurrentEventInContext:[NSManagedObjectContext MR_defaultContext]].forms;
    return _forms;
}

- (NSArray *) formFields {
    if (_formFields != nil && [[Server currentEventId] isEqualToNumber:self.eventId]) {
        return _formFields;
    }
    
    _formFields = [[NSMutableArray alloc] init];
    self.eventId = [Server currentEventId];
    
    
    for (NSDictionary *form in [self.observation.properties objectForKey:@"forms"]) {
        // TODO must be a better way through this
        NSDictionary *eventForm;
        for (NSDictionary *formCheck in self.forms) {
            if ([formCheck valueForKey:@"id"] == [form objectForKey:@"formId"]) {
                eventForm = formCheck;
            }
        }
        
        if (!self.primaryField) {
            self.primaryField = [eventForm objectForKey:@"primaryField"];
        }
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"archived = %@ AND hidden = %@ AND type IN %@", nil, nil, [ObservationFields fields]];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES];
        NSArray *fields = [[[eventForm objectForKey:@"fields"] filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:@[sortDescriptor]];
        [_formFields addObject:fields];
    }
    return _formFields;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == ATTACHMENT_SECTION) {
        return [self.observation.attachments count] > 0 ? 1 : 0;
    } else if (section == COMMON_SECTION) {
        return 2;
    } else {
        return [[self.formFields objectAtIndex:(section - 2)] count];
    }
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2 + [[self.observation.properties objectForKey:@"forms"] count];
}

- (NSString *) getCellTypeAtIndexPath:(NSIndexPath *) indexPath {
    if (indexPath.section == ATTACHMENT_SECTION) {
        return @"attachmentView";
    } else if (indexPath.section == COMMON_SECTION) {
        if (indexPath.row == 0) {
            return @"date";
        } else {
            return @"geometry";
        }
    } else {
        return  [[self fieldForIndexPath:indexPath] objectForKey:@"type"];
    }
}

- (NSDictionary *) fieldForIndexPath: (NSIndexPath *) indexPath {
    if ([indexPath section] > 1) {
        NSMutableDictionary *field = [[NSMutableDictionary alloc] initWithDictionary:[[self.formFields objectAtIndex:([indexPath section] - 2)] objectAtIndex:[indexPath row]]];
        [field setObject:[NSNumber numberWithInteger:([indexPath section]-2)] forKey: @"formIndex"];
        [field setObject:[NSNumber numberWithInteger:[indexPath row]] forKey:@"fieldRow"];
        return field;
    } else if ([indexPath section] == COMMON_SECTION) {
        NSMutableDictionary *field = [[NSMutableDictionary alloc] init];
        if ([indexPath row] == 0) {
            [field setObject:@"Date" forKey:@"title"];
            [field setObject:@"timestamp" forKey:@"name"];
        } else if ([indexPath row] == 1) {
            [field setObject:@"Location" forKey:@"title"];
            [field setObject:@"geometry" forKey:@"name"];
        }
        return field;
    }
    return nil;
}

- (id) valueForIndexPath: (NSIndexPath *) indexPath {
    if ([indexPath section] > 1) {
        id field = [self fieldForIndexPath:indexPath];
        id value = [[[self.observation.properties objectForKey:@"forms"] objectAtIndex:([indexPath section] - 2)] objectForKey:(NSString *)[field objectForKey:@"name"]];
        return value;
    } else if ([indexPath section] == COMMON_SECTION) {
        if ([indexPath row] == 0) {
            return [self.observation.properties objectForKey:@"timestamp"];
        } else if ([indexPath row] == 1) {
            return [self.observation getGeometry];
        }
    }
    return nil;
}

- (ObservationEditTableViewCell *) cellForFieldAtIndex: (NSIndexPath *) indexPath inTableView: (UITableView *) tableView {
    NSString *cellType = [self getCellTypeAtIndexPath:indexPath];
    ObservationEditTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellType];
    cell.fieldDefinition = [self fieldForIndexPath:indexPath];
    
    if ([cell isKindOfClass:[ObservationEditGeometryTableViewCell class]]) {
        ObservationEditGeometryTableViewCell *gcell = (ObservationEditGeometryTableViewCell *) cell;
        self.annotationChangedDelegate = gcell;
        gcell.forms = self.forms;
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id cell = [self cellForFieldAtIndex:indexPath inTableView:tableView];
    [cell setDelegate:self];
    
    if ([cell respondsToSelector:@selector(attachmentSelectionDelegate)]) {
        [cell setAttachmentSelectionDelegate:self.attachmentSelectionDelegate];
    }
    
    id value = [self valueForIndexPath:indexPath];
    [cell populateCellWithFormField:[self fieldForIndexPath:indexPath] andValue:value];
    [cell setValid:![self.invalidIndexPaths containsObject:indexPath]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ObservationEditTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell selectRow];
}

- (void) observationField:(id)field valueChangedTo:(id)value reloadCell:(BOOL)reload {
    
    NSIndexPath *indexPath;
    
    if ([[field objectForKey:@"name"] isEqualToString:@"geometry"]) {
        self.observation.geometry = value;
        indexPath = [NSIndexPath indexPathForRow:1 inSection:COMMON_SECTION];
    } else if ([[field objectForKey:@"name"] isEqualToString:@"timestamp"]) {
        [self.observation.properties setObject:value forKey:@"timestamp"];
        indexPath = [NSIndexPath indexPathForRow:0 inSection:COMMON_SECTION];
    } else {
        NSString *fieldKey = (NSString *)[field objectForKey:@"name"];
        NSNumber *number = [field objectForKey:@"formIndex"];
        NSUInteger formIndex = [number integerValue];
        NSMutableDictionary *newProperties = [[NSMutableDictionary alloc] initWithDictionary:self.observation.properties];
        NSMutableArray *forms = [newProperties objectForKey:@"forms"];
        NSMutableDictionary *newFormProperties = [[NSMutableDictionary alloc] initWithDictionary:[forms objectAtIndex:formIndex]];
        if (value == nil) {
            [newFormProperties removeObjectForKey:fieldKey];
        } else {
            [newFormProperties setObject:value forKey:fieldKey];
        }
        [forms replaceObjectAtIndex:formIndex withObject:newFormProperties];
        [newProperties setObject:forms forKey:@"forms"];
        
        indexPath = [NSIndexPath indexPathForRow:[[field objectForKey:@"fieldRow"] integerValue] inSection:(formIndex+2)];
        
        self.observation.properties = newProperties;
        
        if ([fieldKey isEqualToString:self.primaryField] && self.annotationChangedDelegate) {
            [self.annotationChangedDelegate typeChanged:self.observation];
        }
        if (self.variantField && [fieldKey isEqualToString:self.variantField] && self.annotationChangedDelegate) {
            [self.annotationChangedDelegate variantChanged:self.observation];
        }
    }
    
    if (reload == YES || [self.invalidIndexPaths containsObject:indexPath]) {
        [self.invalidIndexPaths removeObject:indexPath];
        
        id cell = [self.editTable cellForRowAtIndexPath:indexPath];
//        if ([indexPath section] > 1) {
            [cell populateCellWithFormField:field andValue:[self valueForIndexPath:indexPath]];
//        }
        [cell setValid:![self.invalidIndexPaths containsObject:indexPath]];
    }
    
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] init];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section != ATTACHMENT_SECTION && section != COMMON_SECTION) {
        NSDictionary *form = [[self.observation.properties objectForKey:@"forms"] objectAtIndex:(section - 2)];
        // TODO must be a better way through this
        for (NSDictionary *eventForm in self.forms) {
            if ([eventForm valueForKey:@"id"] == [form objectForKey:@"formId"]) {
                return [eventForm objectForKey:@"name"];
            }
        }
    }
    return nil;
}


@end
