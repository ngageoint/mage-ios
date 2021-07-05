//
//  MageSplitViewController.h
//  MAGE
//
//

#import <UIKit/UIKit.h>
#import "LocationService.h"
#import <MaterialComponents/MaterialContainerScheme.h>

@interface MageSplitViewController : UISplitViewController<UISplitViewControllerDelegate>

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme;

@end
