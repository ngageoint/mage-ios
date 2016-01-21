//
//  ObservationEditViewDataStore.m
//  MAGE
//
//

#import "ObservationEditViewDataStore.h"
#import "ObservationEditTableViewCell.h"
#import "ObservationEditGeometryTableViewCell.h"
#import <Server+helper.h>
#import <Event+helper.h>

@interface ObservationEditViewDataStore ()
@property (nonatomic, strong) NSDateFormatter *dateDisplayFormatter;
@property (nonatomic, strong) NSDateFormatter *dateParseFormatter;
@property (nonatomic, strong) NSArray *rowToCellType;
@property (nonatomic, strong) NSArray *rowToField;
@property (nonatomic, strong) NSDictionary *fieldToRow;
@property (nonatomic, assign) NSInteger expandedRow;
@property (nonatomic, assign) NSNumber *eventId;
@property (nonatomic, strong) NSMutableArray *invalidFields;
@property (nonatomic, strong) NSString *variantField;
@end

@implementation ObservationEditViewDataStore


- (void) addInvalidFields:(NSArray *) invalidFields {
    _invalidFields = [invalidFields mutableCopy];
    
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    for (id field in invalidFields) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:[[_fieldToRow objectForKey:[field objectForKey:@"id"]] integerValue] inSection:0]];
    }
    
    if ([indexPaths count] > 0) {
        [_editTable reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
        [self.editTable scrollToRowAtIndexPath:[indexPaths firstObject] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

- (NSArray *) rowToCellType {
    if (_rowToCellType != nil && [[Server currentEventId] isEqualToNumber:self.eventId]) {
        return _rowToCellType;
    }
    
    Event *event = [Event MR_findFirstByAttribute:@"remoteId" withValue:[Server currentEventId]];
    self.eventId = [Server currentEventId];
    self.variantField = [event.form objectForKey:@"variantField"];
    
    NSMutableArray *cells = [[NSMutableArray alloc] init];
    NSMutableArray *rowToField = [[NSMutableArray alloc] init];
    NSMutableDictionary *fieldToRowMap = [[NSMutableDictionary alloc] init];
    // add the attachment cell first and then do the other fields
    [fieldToRowMap setObject:[NSNumber numberWithInteger:rowToField.count] forKey:@"attachments"];
    [cells addObject:@"observationEdit-attachmentView"];
    [rowToField addObject:@{}];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"archived = %@", nil];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES];
    NSArray *fields = [[[event.form objectForKey:@"fields"] filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:@[sortDescriptor]];
    
    // run through the form and map the row indexes to fields
    for (id field in fields) {
        NSString *type = [field objectForKey:@"type"];
        if (![type isEqualToString:@"hidden"]) {
            [fieldToRowMap setObject:[NSNumber numberWithInteger:rowToField.count] forKey:[field objectForKey:@"id"]];
            [cells addObject:[NSString stringWithFormat: @"observationEdit-%@", type]];
            [rowToField addObject:field];
        }
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
    return [self rowToField].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (ObservationEditTableViewCell *) cellForFieldAtIndex: (NSIndexPath *) indexPath inTableView: (UITableView *) tableView {
    NSString *cellType = (NSString *)[self rowToCellType][indexPath.row];
    id field = [self rowToField][indexPath.row];
    
    ObservationEditTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"observationEdit-generic"];
    }
    cell.fieldDefinition = field;
    
    if ([cell isKindOfClass:[ObservationEditGeometryTableViewCell class]]) {
        self.annotationChangedDelegate = (ObservationEditGeometryTableViewCell *) cell;
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ObservationEditTableViewCell *cell = [self cellForFieldAtIndex:indexPath inTableView:tableView];
    id field = [self rowToField][indexPath.row];
    cell.delegate = self;
    cell.attachmentSelectionDelegate = self.attachmentSelectionDelegate;
    [cell populateCellWithFormField:field andObservation:self.observation];
    
    [cell setValid:![self.invalidFields containsObject:field]];

    return cell;
}

- (CGFloat)tableView:(UITableView *) tableView heightForRowAtIndexPath:(NSIndexPath *) indexPath {
    if ([indexPath row] == 0 && [self.observation.attachments count] == 0) {
        return 0.0;
    }
    
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView beginUpdates];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView endEditing:NO];
    [tableView endUpdates];
}

- (void) observationField:(id)field valueChangedTo:(id)value reloadCell:(BOOL)reload {
    
    NSString *fieldKey = (NSString *)[field objectForKey:@"name"];
    NSMutableDictionary *newProperties = [[NSMutableDictionary alloc] initWithDictionary:self.observation.properties];
    [newProperties setObject:value forKey:fieldKey];
    self.observation.properties = newProperties;
    
    if (reload == YES) {
        [self.editTable beginUpdates];
        NSInteger row = [[[self fieldToRow] objectForKey:[field objectForKey:@"id"]] integerValue];
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem: row inSection:0];
        [self.editTable reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:NO];
        [self.editTable endUpdates];
    }
    
    if ([self.invalidFields containsObject:field]) {
        [self.invalidFields removeObject:field];
        NSInteger row = [[_fieldToRow objectForKey:[field objectForKey:@"id"]] integerValue];
        [self.editTable reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
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
