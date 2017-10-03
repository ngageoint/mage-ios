//
//  SignUpDelegate.h
//  MAGE
//
//  Created by Dan Barela on 9/14/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SignUpDelegate <NSObject>

- (void) signUpWithParameters: (NSDictionary *) parameters atURL: (NSURL *) url;
- (void) signUpCanceled;

@end
