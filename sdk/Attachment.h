//
//  Attachment.h
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Observation;

NS_ASSUME_NONNULL_BEGIN

@interface Attachment : NSManagedObject

+ (Attachment *) attachmentForJson: (NSDictionary *) json inContext: (NSManagedObjectContext *) context;
- (id) populateFromJson: (NSDictionary *) json;
- (NSURL *) sourceURLWithSize:(NSInteger) size;

@end

NS_ASSUME_NONNULL_END

#import "Attachment+CoreDataProperties.h"
