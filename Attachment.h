//
//  Attachment.h
//  mage-ios-sdk
//
//  Created by Dan Barela on 5/6/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Attachment : NSManagedObject

@property (nonatomic, retain) NSString * contentType;
@property (nonatomic, retain) NSNumber * dirty;
@property (nonatomic, retain) NSString * localPath;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * remoteId;
@property (nonatomic, retain) NSString * remotePath;
@property (nonatomic, retain) NSNumber * size;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSManagedObject *observation;

@end
