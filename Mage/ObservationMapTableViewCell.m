//
//  ObservationMapTableViewCell.m
//  MAGE
//
//

#import "ObservationMapTableViewCell.h"
#import "Observations.h"
#import "ObservationDataStore.h"
#import "MapDelegate.h"
#import "Event.h"
#import "Theme+UIResponder.h"

@interface ObservationMapTableViewCell ()
@property (nonatomic, strong) ObservationDataStore *observationDataStore;
@property (strong, nonatomic) MapDelegate *mapDelegate;
@end

@implementation ObservationMapTableViewCell

- (void) themeDidChange:(MageTheme)theme {
    [UIColor themeMap:self.mapView];
    [self.mapDelegate updateTheme];
}

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
        dispatch_sync(dispatch_get_main_queue(), ^{
            MapObservation *mapObservation = [weakSelf.mapDelegate.mapObservations observationOfId:observation.objectID];
            MKCoordinateRegion viewRegion = [mapObservation viewRegionOfMapView:weakSelf.mapView];
            [weakSelf.mapDelegate selectedObservation:observation region:viewRegion];
        });
    }];
    
    [self registerForThemeChanges];
    [self.mapDelegate ensureMapLayout];
}

- (void)removeFromSuperview {
    [super removeFromSuperview];

    if (self.mapDelegate) {
        [self.mapDelegate cleanup];
        self.mapDelegate = nil;
    }
}

@end
