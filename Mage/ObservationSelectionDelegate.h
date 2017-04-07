//
//  ObservationItemSelectionDelegate.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "Observation.h"

@protocol ObservationSelectionDelegate <NSObject>

@required
    - (void) selectedObservation:(Observation *) observation;
    - (void) selectedObservation:(Observation *) observation region:(MKCoordinateRegion) region;
    - (void) observationDetailSelected: (Observation *) observation;

@end
