//
//  ObservationFields.m
//  MAGE
//
//  Created by William Newman on 5/26/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationFields.h"

@implementation ObservationFields

+ (NSArray *) fields {
    static NSArray *fields;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fields = @[@"checkbox",
                   @"date",
                   @"dropdown",
                   @"multiselectdropdown",
                   @"email",
                   @"geometry",
                   @"numberfield",
                   @"password",
                   @"radio",
                   @"textarea",
                   @"textfield",
                   @"attachment"];
    });
    
    return fields;
}

@end
