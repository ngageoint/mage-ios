//
//  MKAnnotationView+PersonIcon.h
//  MAGE
//
//

#import <MapKit/MapKit.h>
#import "MAGE-Swift.h"

@interface MKAnnotationView (PersonIcon)

- (void) setImageForUser:(User *) user;
- (UIImage *) circleWithColor: (UIColor *) color;
- (UIColor *) colorForUser: (User *) user;
@end
