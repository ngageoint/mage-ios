//
//  GPSSensitivityDataSource.m
//  MAGE
//
//  Created by William Newman on 10/7/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "GPSSensitivityDataSource.h"
#import "LocationService.h"

@implementation GPSSensitivityDataSource

-(NSArray *) labels {
    if (_labels == nil) {
        NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
        NSDictionary *frequencyDictionary = [defaults dictionaryForKey:@"gpsSensitivities"];
        _labels = (NSArray *) [frequencyDictionary objectForKey:@"labels"];
    }
    
    return _labels;
}

-(NSArray *) values {
    if (_values == nil) {
        NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
        NSDictionary *frequencyDictionary = [defaults dictionaryForKey:@"gpsSensitivities"];
        _values = (NSArray *) [frequencyDictionary objectForKey:@"values"];
    }
    
    return _values;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
    
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent: (NSInteger)component {
    return [self.labels count];
    
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self.labels objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (self.gpsSensistivitySelectedDelegate) {
        [self.gpsSensistivitySelectedDelegate gpsSensistivitySelected:[self.values objectAtIndex:row] withLabel:[self.labels objectAtIndex:row]];
    }
}

@end
