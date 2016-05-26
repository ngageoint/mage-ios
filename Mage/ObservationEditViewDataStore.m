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
    
    for (NSInteger i = 0; i < [self.editTable numberOfRowsInSection:0]; ++i) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
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
    self.eventId = [Server currentEventId];
    self.variantField = [event.form objectForKey:@"variantField"];
    
    NSMutableArray *cells = [[NSMutableArray alloc] init];
    NSMutableArray *rowToField = [[NSMutableArray alloc] init];
    NSMutableDictionary *fieldToRowMap = [[NSMutableDictionary alloc] init];
    // add the attachment cell first and then do the other fields
    [fieldToRowMap setObject:[NSNumber numberWithInteger:rowToField.count] forKey:@"attachments"];
    [cells addObject:@"attachmentView"];
    [rowToField addObject:@{}];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"archived = %@ AND hidden = %@ AND type IN %@", nil, nil, [ObservationFields fields]];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES];
    NSArray *fields = [[[event.form objectForKey:@"fields"] filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:@[sortDescriptor]];
    
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
    return [self rowToField].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (ObservationEditTableViewCell *) cellForFieldAtIndex: (NSIndexPath *) indexPath inTableView: (UITableView *) tableView {
    NSString *cellType = (NSString *)[self rowToCellType][indexPath.row];
    id field = [self rowToField][indexPath.row];
    
    ObservationEditTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellType];
    cell.fieldDefinition = field;
    
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

- (CGFloat)tableView:(UITableView *) tableView heightForRowAtIndexPath:(NSIndexPath *) indexPath {
    if ([indexPath row] == 0 && [self.observation.attachments count] == 0) {
        return 0.0;
    }
    
    return UITableViewAutomaticDimension;
}

- (IBAction)tap:(UITapGestureRecognizer *)sender {
    CGPoint point = [sender locationInView:self.editTable];
    NSIndexPath *indexPath = [self.editTable indexPathForRowAtPoint:point];
    ObservationEditTableViewCell *cell = (ObservationEditTableViewCell *) [self.editTable cellForRowAtIndexPath:indexPath];
    [cell selectRow];
}

- (void) observationField:(id)field valueChangedTo:(id)value reloadCell:(BOOL)reload {
    
    NSString *fieldKey = (NSString *)[field objectForKey:@"name"];
    NSMutableDictionary *newProperties = [[NSMutableDictionary alloc] initWithDictionary:self.observation.properties];
    
    if (value == nil) {
        [newProperties removeObjectForKey:fieldKey];
    } else {
        [newProperties setObject:value forKey:fieldKey];
    }
    
    self.observation.properties = newProperties;
    
    NSInteger row = [[[self fieldToRow] objectForKey:[field objectForKey:@"id"]] integerValue];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem: row inSection:0];
    
    if (reload == YES) {
        [self.editTable beginUpdates];
        [self.editTable reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:NO];
        [self.editTable endUpdates];
    }
    
    if ([self.invalidIndexPaths containsObject:indexPath]) {
        [self.invalidIndexPaths removeObject:indexPath];
        [self.editTable reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
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
