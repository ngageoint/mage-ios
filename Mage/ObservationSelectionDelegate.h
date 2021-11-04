//
//  ObservationItemSelectionDelegate.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class Observation;

@protocol ObservationSelectionDelegate <NSObject>

@optional
- (void) getDirections:(Observation *) observation;
- (void) favorite: (Observation *) observation;

@required
    - (void) selectedObservation:(Observation *) observation;
    - (void) selectedObservation:(Observation *) observation region:(MKCoordinateRegion) region;
    - (void) observationDetailSelected: (Observation *) observation;

@end
