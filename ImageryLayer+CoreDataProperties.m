//
//  ImageryLayer+CoreDataProperties.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 10/1/19.
//  Copyright © 2019 National Geospatial-Intelligence Agency. All rights reserved.
//
//

#import "ImageryLayer+CoreDataProperties.h"

@implementation ImageryLayer (CoreDataProperties)

+ (NSFetchRequest<ImageryLayer *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"ImageryLayer"];
}

@dynamic format;
@dynamic options;
@dynamic isSecure;

@end
