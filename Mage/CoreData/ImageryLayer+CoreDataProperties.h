//
//  ImageryLayer+CoreDataProperties.h
//  mage-ios-sdk
//
//  Created by Dan Barela on 10/1/19.
//  Copyright © 2019 National Geospatial-Intelligence Agency. All rights reserved.
//
//

#import "ImageryLayer.h"


NS_ASSUME_NONNULL_BEGIN

@interface ImageryLayer (CoreDataProperties)

+ (NSFetchRequest<ImageryLayer *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *format;
@property (nullable, nonatomic, retain) NSDictionary* options;
@property (nonatomic) BOOL isSecure;

@end

NS_ASSUME_NONNULL_END
