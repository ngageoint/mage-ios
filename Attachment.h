//
//  Attachment.h
//  mage-ios-sdk
//
//  Created by Dan Barela on 12/5/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Observation;

@interface Attachment : NSManagedObject

@property (nonatomic, retain) NSString * contentType;
@property (nonatomic, retain) NSNumber * dirty;
@property (nonatomic, retain) NSString * localPath;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * remoteId;
@property (nonatomic, retain) NSString * remotePath;
@property (nonatomic, retain) NSNumber * size;
@property (nonatomic, retain) NSDate * lastModified;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) Observation *observation;

@end
