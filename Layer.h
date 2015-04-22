//
//  Layer.h
//  mage-ios-sdk
//
//  Created by William Newman on 4/22/15.
//  Copyright (c) 2015 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Layer : NSManagedObject

@property (nonatomic, retain) NSNumber * eventId;
@property (nonatomic, retain) NSString * formId;
@property (nonatomic, retain) NSNumber * loaded;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * remoteId;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * url;

@end
