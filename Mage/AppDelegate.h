//
//  AppDelegate.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "LocationService.h"

@class BaseMapOverlay;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (NSURL *)applicationDocumentsDirectory;
- (void) logout;
- (void) chooseEvent;
- (void) createRootView;
- (BaseMapOverlay *) getBaseMap;
- (BaseMapOverlay *) getDarkBaseMap;
+ (UIViewController*) topMostController;

@end
