//
//  ExternalDevice.h
//  MAGE
//
//  Created by Dan Barela on 8/17/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ExternalDevice : NSObject

+ (void) checkCameraPermissionsForViewController: (UIViewController *) viewController withCompletion:(void (^)(BOOL granted)) complete;
+ (void) checkMicrophonePermissionsForViewController: (UIViewController *) viewController withCompletion:(void (^)(BOOL granted)) complete;
+ (void) checkGalleryPermissionsForViewController: (UIViewController *) viewController withCompletion:(void (^)(BOOL granted)) complete;

@end
