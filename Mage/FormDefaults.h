//
//  FormDefaults.h
//  MAGE
//
//  Created by William Newman on 2/8/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Event.h"

NS_ASSUME_NONNULL_BEGIN

@interface FormDefaults : NSObject

- (instancetype) initWithEventId:(NSInteger) eventId formId:(NSInteger) formId;

- (NSMutableDictionary *) getDefaults;
- (NSDictionary *) getDefaultsMap;
- (void) setDefaults:(NSDictionary *) form;
- (void) clearDefaults;
+ (NSMutableDictionary *) mutableForm:(NSDictionary *) form;

@end

NS_ASSUME_NONNULL_END
