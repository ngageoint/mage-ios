//
//  ObservationMapTableViewCell.m
//  MAGE
//
//  Created by Dan Barela on 2/19/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationMapTableViewCell.h"
#import "Observations.h"
#import "ObservationDataStore.h"
#import "MapDelegate.h"

@interface ObservationMapTableViewCell ()

@property (nonatomic, strong) ObservationDataStore *observationDataStore;
@property (strong, nonatomic) MapDelegate *mapDelegate;

@end

@implementation ObservationMapTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) configureCellForObservation: (Observation *) observation {
    Observations *observations = [Observations observationsForObservation:observation];
    [self.observationDataStore startFetchControllerWithObservations:observations];
    self.mapDelegate = [[MapDelegate alloc] init];
    [self.mapDelegate setMapView: self.mapView];
    self.mapView.delegate = self.mapDelegate;

    [self.mapDelegate setObservations:observations];
    self.observationDataStore.observationSelectionDelegate = self.mapDelegate;
    [self.mapDelegate selectedObservation:observation];
    self.mapDelegate.hideStaticLayers = YES;
    [self.mapDelegate setObservations:observations];
    
    CLLocationDistance latitudeMeters = 2500;
    CLLocationDistance longitudeMeters = 2500;
    NSDictionary *properties = observation.properties;
    id accuracyProperty = [properties valueForKeyPath:@"accuracy"];
    if (accuracyProperty != nil) {
        double accuracy = [accuracyProperty doubleValue];
        latitudeMeters = accuracy > latitudeMeters ? accuracy * 2.5 : latitudeMeters;
        longitudeMeters = accuracy > longitudeMeters ? accuracy * 2.5 : longitudeMeters;
    }
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(observation.location.coordinate, latitudeMeters, longitudeMeters);
    MKCoordinateRegion viewRegion = [self.mapView regionThatFits:region];
    
    [self.mapDelegate selectedObservation:observation region:viewRegion];
}

@end
