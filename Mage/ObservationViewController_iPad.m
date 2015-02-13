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
    self.primaryFieldLabel.text = name;
    NSDictionary *form = [Server observationForm];
    NSString *variantField = [form objectForKey:@"variantField"];
    if (variantField != nil) {
        self.secondaryFieldLabel.text = [self.observation.properties objectForKey:variantField];
    }

}
- (IBAction)getDirections:(id)sender {
    MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:((GeoPoint *) self.observation.geometry).location.coordinate addressDictionary:nil];
    MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
    [mapItem setName:[self.observation.properties valueForKey:@"type"]];
    NSDictionary *options = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
    [mapItem openInMapsWithLaunchOptions:options];
}

@end
