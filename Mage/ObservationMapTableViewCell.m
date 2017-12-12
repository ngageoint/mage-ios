//
//  ObservationMapTableViewCell.m
//  MAGE
//
//

#import "ObservationMapTableViewCell.h"
#import "Observations.h"
#import "ObservationDataStore.h"
#import "MapDelegate.h"
#import <Event.h>

@interface ObservationMapTableViewCell ()
@property (nonatomic, strong) ObservationDataStore *observationDataStore;
@property (strong, nonatomic) MapDelegate *mapDelegate;
@end

@implementation ObservationMapTableViewCell

- (void) configureCellForObservation: (Observation *) observation withForms:(NSArray *)forms {
    Observations *observations = [Observations observationsForObservation:observation];
    [self.observationDataStore startFetchControllerWithObservations:observations];
    if(self.mapDelegate == nil){
        self.mapDelegate = [[MapDelegate alloc] init];
    }
    [self.mapDelegate setMapView: self.mapView];
    self.mapView.delegate = self.mapDelegate;
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    self.observationDataStore.observationSelectionDelegate = self.mapDelegate;
    self.mapDelegate.hideStaticLayers = YES;
    
    __weak __typeof__(self) weakSelf = self;
    [self.mapDelegate setObservations:observations withCompletion:^{
        MapObservation *mapObservation = [weakSelf.mapDelegate.mapObservations observationOfId:observation.objectID];
        MKCoordinateRegion viewRegion = [mapObservation viewRegionOfMapView:weakSelf.mapView];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [weakSelf.mapDelegate selectedObservation:observation region:viewRegion];
        });
    }];
}

@end
