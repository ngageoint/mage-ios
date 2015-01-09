//
//  ObservationEditViewDataStore.m
//  MAGE
//
//  Created by Dan Barela on 10/1/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationEditViewDataStore.h"
#import "ObservationEditTableViewCell.h"
#import <Server+helper.h>

@interface ObservationEditViewDataStore ()

@property (nonatomic, strong) NSDateFormatter *dateDisplayFormatter;
@property (nonatomic, strong) NSDateFormatter *dateParseFormatter;

@end

@implementation ObservationEditViewDataStore

NSArray *_rowToCellType;
NSArray *_rowToField;
NSDictionary *_fieldToRow;
NSInteger expandedRow = -1;

- (NSArray *)rowToCellType {
    if (_rowToCellType != nil) {
        return _rowToCellType;
    }
    NSDictionary *form = [Server observationForm];
    
    NSMutableArray *cells = [[NSMutableArray alloc] init];
    NSMutableArray *fields = [[NSMutableArray alloc] init];
    NSMutableDictionary *fieldToRowMap = [[NSMutableDictionary alloc] init];
    // add the attachment cell first and then do the other fields
    [fieldToRowMap setObject:[NSNumber numberWithInt:fields.count] forKey:@"attachments"];
    [cells addObject:@"observationEdit-attachmentView"];
    [fields addObject:@{}];
    
    // run through the form and map the row indexes to fields
    for (id field in [form objectForKey:@"fields"]) {
        NSString *type = [field objectForKey:@"type"];
        if (![type isEqualToString:@"hidden"]) {
            [fieldToRowMap setObject:[NSNumber numberWithInt:fields.count] forKey:[field objectForKey:@"id"]];
            [cells addObject:[NSString stringWithFormat: @"observationEdit-%@", type]];
            [fields addObject:field];
            if ([type isEqualToString:@"date"]) {
                [cells addObject:@"observationEdit-dateSpinner"];
                [fields addObject:field];
            } else if ([type isEqualToString:@"radio"] || [type isEqualToString:@"dropdown"]) {
                [cells addObject:@"observationEdit-picker"];
                [fields addObject:field];
            }
        }
    }
    _fieldToRow = fieldToRowMap;
    _rowToCellType = cells;
    _rowToField = fields;
    
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
    if (_fieldToRow != nil) {
        return _fieldToRow;
    }
    return [[NSDictionary alloc] init];
}

- (id) valueForIndexPath: (NSIndexPath *) indexPath {
    id field = [self rowToField][indexPath.row];
    id value = [self.observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]];
    return value;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self rowToField].count;
}

- (ObservationEditTableViewCell *) cellForFieldAtIndex: (NSIndexPath *) indexPath inTableView: (UITableView *) tableView {
    NSString *cellType = (NSString *)[self rowToCellType][indexPath.row];
    id field = [self rowToField][indexPath.row];
    
    ObservationEditTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"observationEdit-generic"];
    }
    cell.fieldDefinition = field;
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ObservationEditTableViewCell *cell = [self cellForFieldAtIndex:indexPath inTableView:tableView];
    id field = [self rowToField][indexPath.row];
    [cell populateCellWithFormField:field andObservation:_observation];
    cell.delegate = self;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    ObservationEditTableViewCell *cell = [self cellForFieldAtIndex:indexPath inTableView:tableView];
    NSDictionary *field = [[self rowToField] objectAtIndex: indexPath.row];
    
    if ([[field objectForKey:@"archived"] intValue] == 1) {
        return 0.0;
    }
    if ([[[self rowToCellType] objectAtIndex: indexPath.row] isEqualToString:@"observationEdit-dateSpinner"] ||
        [[[self rowToCellType] objectAtIndex: indexPath.row] isEqualToString:@"observationEdit-picker"]) {
        return [cell getCellHeightForValue:[NSNumber numberWithBool:(expandedRow == indexPath.row)]];
    } else if ([[[self rowToCellType] objectAtIndex: indexPath.row] isEqualToString:@"observationEdit-attachmentView"]) {
        return [cell getCellHeightForValue:[NSNumber numberWithInteger:self.observation.attachments.count]];
    }
    return [cell getCellHeightForValue:[self valueForIndexPath:indexPath]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView beginUpdates];
    
    if ([[[[self rowToField] objectAtIndex:indexPath.row] objectForKey:@"type"] isEqualToString:@"date"] ||
        [[[[self rowToField] objectAtIndex:indexPath.row] objectForKey:@"type"] isEqualToString:@"dropdown"] ||
        [[[[self rowToField] objectAtIndex:indexPath.row] objectForKey:@"type"] isEqualToString:@"radio"]) {
        
        if (expandedRow != indexPath.row +1) {
            expandedRow = indexPath.row + 1;
        } else {
            expandedRow = -1;
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    [tableView endUpdates];
}

- (void) observationField:(id)field valueChangedTo:(id)value reloadCell:(BOOL)reload {
    [self.editTable beginUpdates];
    
    NSString *fieldKey = (NSString *)[field objectForKey:@"name"];
    NSMutableDictionary *newProperties = [[NSMutableDictionary alloc] initWithDictionary:_observation.properties];
    [newProperties setObject:value forKey:fieldKey];
    self.observation.properties = newProperties;
    
    if (reload == YES) {
        NSInteger row = [[[self fieldToRow] objectForKey:[field objectForKey:@"id"]] integerValue];
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem: row inSection:0];
        [self.editTable reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:NO];
    }
    
    [self.editTable endUpdates];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    
    return view;
}


@end
