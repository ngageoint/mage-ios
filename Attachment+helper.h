//
//  Attachment+helper.h
//  mage-ios-sdk
//
//  Created by Dan Barela on 7/17/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Attachment.h"

@interface Attachment (helper)

- (id) populateObjectFromJson: (NSDictionary *) json;

+ (Attachment*) attachmentForJson: (NSDictionary *) json;
+ (id) attachmentForJson: (NSDictionary *) json inContext: (NSManagedObjectContext *) context;
+ (id) attachmentForJson: (NSDictionary *) json inContext: (NSManagedObjectContext *) context insertIntoContext: (NSManagedObjectContext *) insertContext;

@end
