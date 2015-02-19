//
//  ObservationViewController_iPad.m
//  MAGE
//
//  Created by Dan Barela on 2/11/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationViewController_iPad.h"
#import <Server+helper.h>
#import <GeoPoint.h>


@implementation ObservationViewController_iPad

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSString *name = [self.observation.properties valueForKey:@"type"];
    if (name != nil) {
        self.primaryFieldLabel.text = name;
    } else {
        self.primaryFieldLabel.text = @"Observation";
    }
    NSDictionary *form = [Server observationForm];
    NSString *variantField = [form objectForKey:@"variantField"];
    if (variantField != nil) {
        self.secondaryFieldLabel.text = [self.observation.properties objectForKey:variantField];
    } else {
        self.secondaryFieldLabel.text = @"";
    }

}

- (IBAction)getDirections:(id)sender {
    CLLocationCoordinate2D coordinate = ((GeoPoint *) self.observation.geometry).location.coordinate;
    NSURL *testURL = [NSURL URLWithString:@"comgooglemaps-x-callback://"];
    if ([[UIApplication sharedApplication] canOpenURL:testURL]) {
        NSString *directionsRequest = [NSString stringWithFormat:@"%@://?daddr=%f,%f&x-success=%@&x-source=%s",
                                       @"comgooglemaps-x-callback",
                                       coordinate.latitude,
                                       coordinate.longitude,
                                       @"mage://?resume=true",
                                       "MAGE"];
        NSURL *directionsURL = [NSURL URLWithString:directionsRequest];
        [[UIApplication sharedApplication] openURL:directionsURL];
    } else {
        NSLog(@"Can't use comgooglemaps-x-callback:// on this device.");
        MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
        MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
        [mapItem setName:[self.observation.properties valueForKey:@"type"]];
        NSDictionary *options = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
        [mapItem openInMapsWithLaunchOptions:options];
    }
}

@end
