//
//  MapCalloutTappedDelegate_iPhone.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import "MapCalloutTappedSegueDelegate.h"

@interface MapCalloutTappedDelegate_iPhone : NSObject<MapCalloutTapped>

@property(nonatomic, weak) IBOutlet MapCalloutTappedSegueDelegate *userMapCalloutTappedDelegate;
@property(nonatomic, weak) IBOutlet MapCalloutTappedSegueDelegate *observationMapCalloutTappedDelegate;
@property(nonatomic, weak) IBOutlet MapCalloutTappedSegueDelegate *feedItemMapCalloutTappedDelegate;


@end
