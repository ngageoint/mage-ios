//
//  ObservationMapDirectionsTableViewCell.m
//  MAGE
//
//

#import "ObservationMapDirectionsTableViewCell.h"
#import <MapKit/MapKit.h>
#import <GeoPoint.h>

@interface ObservationMapDirectionsTableViewCell ()
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong) NSString *mapItemName;
@end

@implementation ObservationMapDirectionsTableViewCell

- (void) configureCellForObservation: (Observation *) observation {
    
    self.coordinate = ((GeoPoint *) observation.geometry).location.coordinate;
    self.mapItemName = [observation.properties valueForKey:@"type"];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    if (selected) {
        
        NSURL *testURL = [NSURL URLWithString:@"comgooglemaps-x-callback://"];
        if ([[UIApplication sharedApplication] canOpenURL:testURL]) {
            NSString *directionsRequest = [NSString stringWithFormat:@"%@://?daddr=%f,%f&x-success=%@&x-source=%s",
                                           @"comgooglemaps-x-callback",
                                           self.coordinate.latitude,
                                           self.coordinate.longitude,
                                           @"mage://?resume=true",
                                           "MAGE"];
            NSURL *directionsURL = [NSURL URLWithString:directionsRequest];
            [[UIApplication sharedApplication] openURL:directionsURL];
        } else {
            NSLog(@"Can't use comgooglemaps-x-callback:// on this device.");
            MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:self.coordinate addressDictionary:nil];
            MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
            [mapItem setName:self.mapItemName];
            NSDictionary *options = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
            [mapItem openInMapsWithLaunchOptions:options];

        }
    }
}

@end
