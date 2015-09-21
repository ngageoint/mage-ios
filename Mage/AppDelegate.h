//
//  AppDelegate.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import <FICImageCache.h>
#import <LocationService.h>
#import <LocationFetchService.h>
#import <ObservationFetchService.h>
#import <ObservationPushService.h>
#import <AttachmentPushService.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, FICImageCacheDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) FICImageCache *imageCache;

- (NSURL *)applicationDocumentsDirectory;

@end
