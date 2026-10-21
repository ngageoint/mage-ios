//
//  AppDelegate.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "LocationService.h"
#import "AttachmentPushService.h"

@class BaseMapOverlay;

@protocol SceneWindowConnecting <NSObject>
- (void) sceneDidConnectWithWindow:(UIWindow *)window;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate, SceneWindowConnecting>

@property (strong, nonatomic) UIWindow *window;

- (NSURL *)applicationDocumentsDirectory;
- (void) logout;
- (void) chooseEvent;
- (void) createRootView;
- (BaseMapOverlay *) getBaseMap;
- (BaseMapOverlay *) getDarkBaseMap;
+ (UIViewController*) topMostController;
- (void)startObservingTokenExpiration;
- (void) sceneDidConnectWithWindow:(UIWindow *)window;
- (void) sceneDidBecomeActive;
- (void) sceneWillResignActive;
- (void) sceneDidEnterBackground;
- (void) sceneWillEnterForeground;
- (void) handleOpenURL:(NSURL *)url;

@end
