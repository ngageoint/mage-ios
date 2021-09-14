//
//  AppDelegate.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "LocationService.h"
#import "LocationFetchService.h"
#import "ObservationFetchService.h"
#import "ObservationPushService.h"
#import "AttachmentPushService.h"
#import "BaseMapOverlay.h"


@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (NSURL *)applicationDocumentsDirectory;
- (void) logout;
- (void) chooseEvent;
- (void) createRootView;
- (BaseMapOverlay *) getBaseMap;
- (BaseMapOverlay *) getDarkBaseMap;

@end
