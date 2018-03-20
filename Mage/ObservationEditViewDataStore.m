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
#import "ObservationTableHeaderView.h"

#import "Server.h"
#import "Event.h"

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
@property (strong, nonatomic) id<ObservationEditFieldDelegate> delegate;
@property (nonatomic) BOOL isNew;

@end

@implementation ObservationEditViewDataStore

- (instancetype) initWithObservation: (Observation *)observation andIsNew: (BOOL) isNew andDelegate: (id<ObservationEditFieldDelegate>) delegate andAttachmentSelectionDelegate: (id<AttachmentSelectionDelegate>) attachmentDelegate andEditTable: (UITableView *) tableView {
    self = [super init];
    if (!self) return nil;
    
    _observation = observation;
    _delegate = delegate;
    _attachmentSelectionDelegate = attachmentDelegate;
    _editTable = tableView;
    _isNew = isNew;
    
    return self;
}

- (BOOL) validate {
    self.invalidIndexPaths = [[NSMutableArray alloc] init];
    
    for (NSInteger section = 1; section < [self.editTable numberOfSections] - 1; section++) {
        for (NSInteger i = 0; i < [self.editTable numberOfRowsInSection:section]; ++i) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:section];
            ObservationEditTableViewCell *cell = (ObservationEditTableViewCell *) [self tableView:self.editTable cellForRowAtIndexPath:indexPath];
            if (![cell isValid]) {
                [self.invalidIndexPaths addObject:indexPath];
            }
        }
    }
    
    if ([self.invalidIndexPaths count] > 0) {
        [self.editTable reloadRowsAtIndexPaths:self.invalidIndexPaths withRowAnimation:UITableViewRowAnimationNone];
        [self.editTable scrollToRowAtIndexPath:[self.invalidIndexPaths firstObject] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        return NO;
    }
    
    return YES;
}

- (NSNumber *) eventId {
    return self.observation.eventId;
}

- (NSString *) primaryField {
    return [self.observation getPrimaryField];
}

- (NSArray *) forms {
    if (_forms != nil && [[Server currentEventId] isEqualToNumber:self.eventId]) {
        return _forms;
    }
    _forms = [Event getEventById:self.observation.eventId inContext:self.observation.managedObjectContext].forms;
    return _forms;
}

- (NSArray *) formFields {
    if (_formFields != nil && [[Server currentEventId] isEqualToNumber:self.eventId]) {
        return _formFields;
    }
    
    _formFields = [[NSMutableArray alloc] init];
    
    NSDictionary *eventForm = [self.observation getPrimaryForm];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"archived = %@ AND hidden = %@ AND type IN %@", nil, nil, [ObservationFields fields]];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES];
    NSArray *fields = [[[eventForm objectForKey:@"fields"] filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:@[sortDescriptor]];
    [_formFields addObject:fields];
    return _formFields;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == ATTACHMENT_SECTION) {
        return [self.observation.attachments count] > 0 ? 1 : 0;
    } else if (section == COMMON_SECTION) {
        return 2;
    } else if (section == [self numberOfSectionsInTableView:tableView] -1 ) {
        return (!self.isNew && [self.observation isDeletableByCurrentUser]) ? 1 : 0;
    } else {
        return [[self.formFields objectAtIndex:(section - 2)] count];
    }
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    NSUInteger formCount = [[self.observation.properties objectForKey:@"forms"] count];
    return 3 + formCount;
}

- (NSString *) getCellTypeAtIndexPath:(NSIndexPath *) indexPath {
    if (indexPath.section == ATTACHMENT_SECTION) {
        return @"attachment";
    } else if (indexPath.section == COMMON_SECTION) {
        if (indexPath.row == 0) {
            return @"date";
        } else {
            return @"geometry";
        }
    } else {
        NSString *type = [[self fieldForIndexPath:indexPath] objectForKey:@"type"];
        if ([type isEqualToString:@"radio"] || [type isEqualToString:@"multiselectdropdown"]) {
            type = @"dropdown";
        }
        return type;
    }
}

- (NSDictionary *) fieldForIndexPath: (NSIndexPath *) indexPath {
    if ([indexPath section] > 1) {
        if ([self.formFields count] > (indexPath.section - 2)) {
            NSMutableDictionary *field = [[NSMutableDictionary alloc] initWithDictionary:[[self.formFields objectAtIndex:([indexPath section] - 2)] objectAtIndex:[indexPath row]]];
            [field setObject:[NSNumber numberWithInteger:([indexPath section]-2)] forKey: @"formIndex"];
            [field setObject:[NSNumber numberWithInteger:[indexPath row]] forKey:@"fieldRow"];
            return field;
        } else {
            NSMutableDictionary *field = [[NSMutableDictionary alloc] init];
            [field setObject:@"delete" forKey:@"name"];
            [field setObject:@"deleteObservationCell" forKey:@"type"];
            return field;
        }
    } else if ([indexPath section] == COMMON_SECTION) {
        NSMutableDictionary *field = [[NSMutableDictionary alloc] init];
        if ([indexPath row] == 0) {
            [field setObject:@"Date" forKey:@"title"];
            [field setObject:[NSNumber numberWithBool:YES] forKey:@"required"];
            [field setObject:@"timestamp" forKey:@"name"];
            [field setObject:@"date" forKey:@"type"];
        } else if ([indexPath row] == 1) {
            [field setObject:@"Location" forKey:@"title"];
            [field setObject:[NSNumber numberWithBool:YES] forKey:@"required"];
            [field setObject:@"geometry" forKey:@"name"];
            [field setObject:@"geometry" forKey:@"type"];
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
            return [[NSDictionary alloc] initWithObjectsAndKeys:[self.observation getGeometry], @"geometry", self.observation, @"observation", self.forms, @"forms", nil];
        }
    } else if ([indexPath section] == ATTACHMENT_SECTION) {
        return self.observation;
    }
    return nil;
}

- (ObservationEditTableViewCell *) cellForFieldAtIndex: (NSIndexPath *) indexPath inTableView: (UITableView *) tableView {
    NSString *cellType = [self getCellTypeAtIndexPath:indexPath];
    if ([cellType isEqualToString:@"deleteObservationCell"]) {
        return [tableView dequeueReusableCellWithIdentifier:cellType];
    }
    ObservationEditTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellType];
    cell.fieldDefinition = [self fieldForIndexPath:indexPath];
    
    if ([cell isKindOfClass:[ObservationEditGeometryTableViewCell class]]) {
        ObservationEditGeometryTableViewCell *gcell = (ObservationEditGeometryTableViewCell *) cell;
        self.annotationChangedDelegate = gcell;
        gcell.observation = self.observation;
        gcell.forms = self.forms;
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id cell = [self cellForFieldAtIndex:indexPath inTableView:tableView];
    
    if ([cell respondsToSelector:@selector(setDelegate:)]) {
        [cell setDelegate:self];
    }
    
    if ([cell respondsToSelector:@selector(attachmentSelectionDelegate)]) {
        [cell setAttachmentSelectionDelegate:self.attachmentSelectionDelegate];
    }
    
    if ([cell respondsToSelector:@selector(populateCellWithFormField:andValue:)]) {
        id value = [self valueForIndexPath:indexPath];
        [cell populateCellWithFormField:[self fieldForIndexPath:indexPath] andValue:value];
        // recheck
        if ([self.invalidIndexPaths containsObject:indexPath]) {
            [cell setValid:[cell isValid]];
        }
//        [cell setValid:![self.invalidIndexPaths containsObject:indexPath]];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == [self numberOfSectionsInTableView:tableView]-1) {
        [self.delegate deleteObservation];
        return;
    }
    ObservationEditTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell selectRow];
    [self.delegate fieldSelected:[self fieldForIndexPath:indexPath]];
}

- (void) observationField:(id)field valueChangedTo:(id)value reloadCell:(BOOL)reload {
    
    NSIndexPath *indexPath;
    
    if ([[field objectForKey:@"name"] isEqualToString:@"geometry"]) {
        self.observation.geometry = [value objectForKey:@"geometry"];
        indexPath = [NSIndexPath indexPathForRow:1 inSection:COMMON_SECTION];
    } else if ([[field objectForKey:@"name"] isEqualToString:@"timestamp"]) {
        if (value == nil) {
            [self.observation.properties removeObjectForKey:@"timestamp"];
        } else {
            [self.observation.properties setObject:value forKey:@"timestamp"];
        }
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
        [cell populateCellWithFormField:field andValue:[self valueForIndexPath:indexPath]];
        [cell setValid:[cell isValid]];
    }
    
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if (section != ATTACHMENT_SECTION && section != COMMON_SECTION && section != ([self numberOfSectionsInTableView:tableView]-1)) {
        NSDictionary *form = [[self.observation.properties objectForKey:@"forms"] objectAtIndex:(section - 2)];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.id = %@", [form objectForKey:@"formId"]];
        NSArray *filteredArray = [self.forms filteredArrayUsingPredicate:predicate];
        return [[filteredArray firstObject] objectForKey:@"name"];
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == ATTACHMENT_SECTION || section == COMMON_SECTION) {
        return 15.0f;
    }
    return 48.0f;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *name = [self tableView:tableView titleForHeaderInSection:section];
    
    return [[ObservationTableHeaderView alloc] initWithName:name];
}

@end
