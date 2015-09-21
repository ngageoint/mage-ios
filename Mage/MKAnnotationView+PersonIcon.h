//
//  MKAnnotationView+PersonIcon.h
//  MAGE
//
//

#import <MapKit/MapKit.h>
#import "User.h"

@interface MKAnnotationView (PersonIcon)

- (void) setImageForUser:(User *) user;
@end
