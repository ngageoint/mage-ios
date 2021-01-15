//
//  MapCalloutTappedDelegate_iPhone.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import <MaterialComponents/MaterialContainerScheme.h>
#import "MapCalloutTapped.h"

@interface MapCalloutTappedSegueDelegate : NSObject<MapCalloutTapped>

@property(nonatomic, weak) IBOutlet UIViewController *viewController;
@property(nonatomic, weak) NSString *segueIdentifier;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;

@end
