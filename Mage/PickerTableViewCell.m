//
//  PickerTableViewCell.m
//  MAGE
//
//  Created by Dan Barela on 11/12/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "PickerTableViewCell.h"

@implementation PickerTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.pickerValues = [NSMutableArray array];
    }
    return self;
}

- (void)awakeFromNib
{
    self.pickerValues = [NSMutableArray array];
}

- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    return self.pickerValues.count;
}

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return self.pickerValues[row];
}

- (CGFloat) getCellHeightForValue:(id)value {
    BOOL boolValue = [value boolValue];
    if (boolValue == YES) {
        return 162.0;
    } else {
        return 0.0;
    }
}

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    self.pickerValues = [NSMutableArray array];
    for (id choice in [field objectForKey:@"choices"]) {
        NSLog(@"title is %@", [choice objectForKey:@"title"]);
        [self.pickerValues addObject:[choice objectForKey:@"title"]];
    }
    
    [self.picker reloadAllComponents];
    //[self.picker selectRow:[pickerValues indexOfObject:[observation.properties objectForKey:[field objectForKey:@"name"]]] inComponent:0 animated:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSString *newValue = [self.pickerValues objectAtIndex:row];
    if (self.delegate && [self.delegate respondsToSelector:@selector(observationField:valueChangedTo:reloadCell:)]) {
        [self.delegate observationField:self.fieldDefinition valueChangedTo:newValue reloadCell:YES];
    }
}

@end
