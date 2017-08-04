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
static NSInteger const PROPERTIES_SECTION = 1;

@interface ObservationEditViewDataStore ()
@property (nonatomic, strong) NSDateFormatter *dateDisplayFormatter;
@property (nonatomic, strong) NSDateFormatter *dateParseFormatter;
@property (nonatomic, strong) NSArray *rowToCellType;
@property (nonatomic, strong) NSArray *rowToField;
@property (nonatomic, strong) NSDictionary *fieldToRow;
@property (nonatomic, assign) NSInteger expandedRow;
@property (nonatomic, strong) NSNumber *eventId;
@property (nonatomic, strong) NSString *variantField;
@property (nonatomic, strong) NSMutableArray *invalidIndexPaths;
@end

@implementation ObservationEditViewDataStore

- (BOOL) validate {
    self.invalidIndexPaths = [[NSMutableArray alloc] init];
    
    for (NSInteger i = 0; i < [self.editTable numberOfRowsInSection:PROPERTIES_SECTION]; ++i) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:PROPERTIES_SECTION];
        ObservationEditTableViewCell *cell = (ObservationEditTableViewCell *) [self tableView:self.editTable cellForRowAtIndexPath:indexPath];
        if (![cell isValid]) {
            [self.invalidIndexPaths addObject:indexPath];
        }
    }
    
    if ([self.invalidIndexPaths count] > 0) {
        [self.editTable reloadRowsAtIndexPaths:self.invalidIndexPaths withRowAnimation:UITableViewRowAnimationNone];
        [self.editTable scrollToRowAtIndexPath:[self.invalidIndexPaths firstObject] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        return NO;
    }
    
    return YES;
}

- (NSArray *) rowToCellType {
    if (_rowToCellType != nil && [[Server currentEventId] isEqualToNumber:self.eventId]) {
        return _rowToCellType;
    }
    
    Event *event = [Event MR_findFirstByAttribute:@"remoteId" withValue:[Server currentEventId]];
    NSDictionary *form = [event formForObservation:self.observation];
    self.eventId = [Server currentEventId];
    self.variantField = [form objectForKey:@"variantField"];
    
    NSMutableArray *cells = [[NSMutableArray alloc] init];
    NSMutableArray *rowToField = [[NSMutableArray alloc] init];
    NSMutableDictionary *fieldToRowMap = [[NSMutableDictionary alloc] init];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"archived = %@ AND hidden = %@ AND type IN %@", nil, nil, [ObservationFields fields]];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES];
    NSArray *fields = [[[form objectForKey:@"fields"] filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:@[sortDescriptor]];
    
    // run through the form and map the row indexes to fields
    for (id field in fields) {
        [fieldToRowMap setObject:[NSNumber numberWithInteger:rowToField.count] forKey:[field objectForKey:@"id"]];
        [cells addObject:[field objectForKey:@"type"]];
        [rowToField addObject:field];
    }
    
    self.fieldToRow = fieldToRowMap;
    self.rowToField = rowToField;
    _rowToCellType = cells;

    return _rowToCellType;
}

- (NSArray *) rowToField {
    if (_rowToField != nil) {
        return _rowToField;
    }
    
    [self rowToCellType];
    return _rowToField;
}

- (NSDictionary *) fieldToRow {
    if (!_fieldToRow) {
        _fieldToRow = [[NSDictionary alloc] init];
    }
    
    return _fieldToRow;
}

- (id) valueForIndexPath: (NSIndexPath *) indexPath {
    id field = [self rowToField][indexPath.row];
    id value = [self.observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]];
    return value;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == ATTACHMENT_SECTION) {
        return [self.observation.attachments count] > 0 ? 1 : 0;
    } else {
        return [self rowToField].count;
    }
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *) getCellTypeAtIndexPath:(NSIndexPath *) indexPath {
    return indexPath.section == ATTACHMENT_SECTION ? @"attachmentView" : [self rowToCellType][indexPath.row];
}

- (ObservationEditTableViewCell *) cellForFieldAtIndex: (NSIndexPath *) indexPath inTableView: (UITableView *) tableView {
    NSString *cellType = [self getCellTypeAtIndexPath:indexPath];
    ObservationEditTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellType];
    cell.fieldDefinition = [self rowToField][indexPath.row];
    
    if ([cell isKindOfClass:[ObservationEditGeometryTableViewCell class]]) {
        self.annotationChangedDelegate = (ObservationEditGeometryTableViewCell *) cell;
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id cell = [self cellForFieldAtIndex:indexPath inTableView:tableView];
    id field = [self rowToField][indexPath.row];
    [cell setDelegate:self];
    
    if ([cell respondsToSelector:@selector(attachmentSelectionDelegate)]) {
        [cell setAttachmentSelectionDelegate:self.attachmentSelectionDelegate];
    }
    
    [cell populateCellWithFormField:field andObservation:self.observation];
    [cell setValid:![self.invalidIndexPaths containsObject:indexPath]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ObservationEditTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell selectRow];
}

- (void) observationField:(id)field valueChangedTo:(id)value reloadCell:(BOOL)reload {
    
    NSString *fieldKey = (NSString *)[field objectForKey:@"name"];
    
    if ([[field objectForKey:@"name"] isEqualToString:@"geometry"]) {
        // Geometry is not stored in properties
        self.observation.geometry = value;
    } else {
        NSMutableDictionary *newProperties = [[NSMutableDictionary alloc] initWithDictionary:self.observation.properties];
        
        if (value == nil) {
            [newProperties removeObjectForKey:fieldKey];
        } else {
            [newProperties setObject:value forKey:fieldKey];
        }
        
        self.observation.properties = newProperties;
    }
    
    NSInteger row = [[[self fieldToRow] objectForKey:[field objectForKey:@"id"]] integerValue];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem: row inSection:PROPERTIES_SECTION];
    
    if (reload == YES || [self.invalidIndexPaths containsObject:indexPath]) {
        [self.invalidIndexPaths removeObject:indexPath];
        
        id cell = [self.editTable cellForRowAtIndexPath:indexPath];
        [cell populateCellWithFormField:field andObservation:self.observation];
        [cell setValid:![self.invalidIndexPaths containsObject:indexPath]];
    }
    
    if ([fieldKey isEqualToString:@"type"] && self.annotationChangedDelegate) {
        [self.annotationChangedDelegate typeChanged:self.observation];
    }
    
    if (self.variantField && [fieldKey isEqualToString:self.variantField] && self.annotationChangedDelegate) {
        [self.annotationChangedDelegate variantChanged:self.observation];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] init];
}


@end
