//
//  MapCalloutTappedDelegate_iPhone.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import "MapCalloutTapped.h"

@interface MapCalloutTappedSegueDelegate : NSObject<MapCalloutTapped>

@property(nonatomic, weak) IBOutlet UIViewController *viewController;
@property(nonatomic, weak) NSString *segueIdentifier;

@end
