//
//  Attachment+CoreDataProperties.h
//  mage-ios-sdk
//
//  Created by William Newman on 4/18/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Attachment.h"

NS_ASSUME_NONNULL_BEGIN

@interface Attachment (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *contentType;
@property (nullable, nonatomic, retain) NSNumber *dirty;
@property (nullable, nonatomic, retain) NSNumber *eventId;
@property (nullable, nonatomic, retain) NSDate *lastModified;
@property (nullable, nonatomic, retain) NSString *localPath;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *observationRemoteId;
@property (nullable, nonatomic, retain) NSString *remoteId;
@property (nullable, nonatomic, retain) NSString *remotePath;
@property (nullable, nonatomic, retain) NSNumber *size;
@property (nullable, nonatomic, retain) NSString *url;
@property (nullable, nonatomic, retain) Observation *observation;
@property (nullable, nonatomic, retain) NSNumber *taskIdentifier;

@end

NS_ASSUME_NONNULL_END
