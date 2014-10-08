//
//  UserFetchDataSource.h
//  MAGE
//
//  Created by William Newman on 10/7/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol UserFetchIntervalSelected <NSObject>

-(void) userFetchIntervalSelected:(NSString *) value withLabel:(NSString *) label;

@end

@interface UserFetchDataSource : NSObject

@property (nonatomic, weak) NSArray *labels;
@property (nonatomic, weak) NSArray *values;

@property (nonatomic, weak) IBOutlet id<UserFetchIntervalSelected> userFetchIntervalSelectedDelegate;

@end
