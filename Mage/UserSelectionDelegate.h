//
//  ObservationSelectionDelegate.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import "User+helper.h"
#import <MapKit/MapKit.h>

@protocol UserSelectionDelegate <NSObject>

@required
    -(void) selectedUser:(User *) user;
    -(void) selectedUser:(User *) user region:(MKCoordinateRegion) region;
    -(void) userDetailSelected: (User *) user;

@end
