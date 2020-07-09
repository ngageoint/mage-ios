//
//  MageTabBarController.h
//  MAGE
//
//

#import <UIKit/UIKit.h>
#import "MapCalloutTappedSegueDelegate.h"
#import "MAGEMasterSelectionDelegate.h"

@interface MageTabBarController : UITabBarController

@property(nonatomic, weak) IBOutlet MapCalloutTappedSegueDelegate *userMapCalloutTappedDelegate;
@property(nonatomic, weak) IBOutlet MapCalloutTappedSegueDelegate *observationMapCalloutTappedDelegate;
@property(nonatomic, weak) IBOutlet MapCalloutTappedSegueDelegate *feedItemMapCalloutTappedDelegate;
@property (nonatomic, assign) id<MAGEMasterSelectionDelegate> masterSelectionDelegate;

@end
