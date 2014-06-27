//
//  Layer.h
//  mage-ios-sdk
//
//  Created by Dan Barela on 6/27/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Layer : NSManagedObject

@property (nonatomic, retain) NSString * remoteId;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * loaded;
@property (nonatomic, retain) NSString * formId;
@property (nonatomic, retain) NSString * url;

@end
