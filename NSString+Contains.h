//
//  NSString+Contains.h
//  mage-ios-sdk
//
//  Created by Dan Barela on 2/26/15.
//  Copyright (c) 2015 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Contains)

- (BOOL)safeContainsString:(NSString*)other;

@end
