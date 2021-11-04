//
//  ObservationSelectionDelegate.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class User;

@protocol UserSelectionDelegate <NSObject>

@required
    -(void) selectedUser:(User *) user;
    -(void) selectedUser:(User *) user region:(MKCoordinateRegion) region;
    -(void) userDetailSelected: (User *) user;

@end
