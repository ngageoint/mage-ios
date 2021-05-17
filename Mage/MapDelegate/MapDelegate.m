//
//  MapDelegate.m
//  MAGE
//
//
@import HexColors;
@import DateTools;

#import "MapDelegate.h"
#import "LocationAnnotation.h"
#import "ObservationAnnotation.h"
#import "ObservationImage.h"
#import "User.h"
#import "Location.h"
#import "UIImage+Resize.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "MKAnnotationView+PersonIcon.h"
#import "StaticLayer.h"
#import "StaticPointAnnotation.h"
#import "StyledPolygon.h"
#import "StyledPolyline.h"
#import "AreaAnnotation.h"
#import <MapKit/MapKit.h>
#import "Server.h"
#import "CacheOverlays.h"
#import "XYZDirectoryCacheOverlay.h"
#import "GPKGGeoPackageCache.h"
#import "GPKGGeoPackageFactory.h"
#import "GeoPackageCacheOverlay.h"
#import "GeoPackageTileTableCacheOverlay.h"
#import "GeoPackageFeatureTableCacheOverlay.h"
#import "GPKGOverlayFactory.h"
#import "GPKGNumberFeaturesTile.h"
#import "GPKGMapShapeConverter.h"
#import "GPKGFeatureTileTableLinker.h"
#import "GPKGTileBoundingBoxUtils.h"
#import "GPKGMapUtils.h"
#import "CacheOverlayUpdate.h"
#import "SFPProjectionTransform.h"
#import "SFPProjectionConstants.h"
#import "MapObservationManager.h"
#import "SFGeometryUtils.h"
#import "SFPProjection.h"
#import "SFPProjectionTransform.h"
#import "MapShapePointAnnotationView.h"
#import "Event.h"
#import "Form.h"
#import "Observation.h"
#import "MapUtils.h"
#import "ObservationAccuracy.h"
#import "ObservationAccuracyRenderer.h"
#import "LocationAccuracy.h"
#import "LocationAccuracyRenderer.h"
#import "WMSTileOverlay.h"
#import "XYZTileOverlay.h"
#import "TMSTileOverlay.h"
#import "ImageryLayer.h"
#import "BaseMapOverlay.h"
#import <PureLayout.h>
#import "MAGE-Swift.h"

@interface MapDelegate () <MDCBottomSheetControllerDelegate, ObservationActionsDelegate, StraightLineNavigationDelegate>
    @property (nonatomic, strong) LocationAccuracy *selectedUserAccuracy;
    @property (nonatomic, strong) ObservationAccuracy *selectedObservationAccuracy;

    @property (nonatomic, strong) NSMutableDictionary<NSString *, CacheOverlay *> *mapCacheOverlays;
    @property (nonatomic, strong) GPKGBoundingBox * addedCacheBoundingBox;
    @property (nonatomic, strong) CacheOverlayUpdate * cacheOverlayUpdate;
    @property (nonatomic, strong) BaseMapOverlay *backgroundOverlay;
    @property (nonatomic, strong) BaseMapOverlay *darkBackgroundOverlay;
    @property (nonatomic, strong) NSObject * cacheOverlayUpdateLock;
    @property (nonatomic) BOOL updatingCacheOverlays;
    @property (nonatomic) BOOL waitingCacheOverlaysUpdate;
    @property (nonatomic, strong) GPKGGeoPackageCache *geoPackageCache;
    @property (nonatomic, strong) GPKGGeoPackageManager * geoPackageManager;
    @property (nonatomic, strong) NSMutableDictionary *staticLayers;
    @property (nonatomic, strong) NSMutableDictionary *onlineLayers;
    @property (nonatomic, strong) NSMutableArray *currentFeeds;
    @property (nonatomic, strong) AreaAnnotation *areaAnnotation;

    @property (nonatomic) BOOL isTrackingAnimation;

    @property (nonatomic) BOOL darkMode;

    @property (strong, nonatomic) MapObservationManager *mapObservationManager;
@property (strong, nonatomic) NSMutableArray *listenersRegistered;
@property (nonatomic) id<MKMapViewDelegate> mapEventDelegate;
@property (strong, nonatomic) GPKGGeoPackage * countriesGeoPackage;
@property (strong, nonatomic) GPKGGeoPackage * darkCountriesGeoPackage;
@property (strong, nonatomic) NSMutableDictionary *feedItemRetrievers;
@property (strong, nonatomic) MDCBottomSheetController *bottomSheet;
@property (strong, nonatomic) MKAnnotationView *enlargedPin;
@end

@implementation MapDelegate

- (void) setupListeners {
    if (self.mapView) {
        @synchronized (self) {
            if (!self.listenersRegistered) {
                self.listenersRegistered = [NSMutableArray arrayWithObjects:@"mapType", kCurrentEventIdKey, @"selectedOnlineLayers", [NSString stringWithFormat:@"selectedFeeds-%@", [Server currentEventId]], nil];
                if (!self.hideStaticLayers) {
                    [self.listenersRegistered addObject:@"selectedStaticLayers"];
                }
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                
                for (NSString *keyPath in self.listenersRegistered) {
                    [defaults addObserver:self
                               forKeyPath:keyPath
                                  options:NSKeyValueObservingOptionNew
                                  context:NULL];
                }
            }
        }

        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(formFetched:) name: MAGEFormFetched object:nil];
    }
    if (!self.mapCacheOverlays) {
        self.mapCacheOverlays = [[NSMutableDictionary alloc] init];
    }
    [[CacheOverlays getInstance] registerListener:self];
    self.cacheOverlayUpdate = nil;
    self.cacheOverlayUpdateLock = [[NSObject alloc] init];
    self.updatingCacheOverlays = false;
    self.waitingCacheOverlaysUpdate = false;
    self.geoPackageManager = [GPKGGeoPackageFactory manager];
    self.geoPackageCache = [[GPKGGeoPackageCache alloc]initWithManager:self.geoPackageManager];
    [self addFeeds];
}

- (void) setMapEventDelegte: (id<MKMapViewDelegate>) mapEventDelegate {
    self.mapEventDelegate = mapEventDelegate;
}

- (void) mapViewDidFinishLoadingMap:(MKMapView *)mapView {
    if (self.mapEventDelegate) [self.mapEventDelegate mapViewDidFinishLoadingMap:mapView];
}

- (void) mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered: (BOOL) fullyRendered {
    if (self.mapEventDelegate) [self.mapEventDelegate mapViewDidFinishRenderingMap:mapView fullyRendered:fullyRendered];
}

- (void) mapViewWillStartLoadingMap:(MKMapView *)mapView {
    if (self.mapEventDelegate) [self.mapEventDelegate mapViewWillStartLoadingMap:mapView];
}

- (void) mapView:(MKMapView *)mapView didAddOverlayViews:(NSArray *)overlayViews {
    if (self.mapEventDelegate) [self.mapEventDelegate mapView:mapView didAddOverlayViews:overlayViews];
}


// map annotation drop code from: https://stackoverflow.com/questions/6808876/how-do-i-animate-mkannotationview-drop
- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    MKAnnotationView *aV;

    for (aV in views) {

        // Don't pin drop if annotation is user location
        if ([aV.annotation isKindOfClass:[MKUserLocation class]]) {
            continue;
        } else if ([aV.annotation isKindOfClass:[AreaAnnotation class]]) {
            continue;
        }

        // Check if current annotation is inside visible map rect, else go to next one
        MKMapPoint point =  MKMapPointForCoordinate(aV.annotation.coordinate);
        if (!MKMapRectContainsPoint(self.mapView.visibleMapRect, point)) {
            continue;
        }

        if ([aV.annotation isKindOfClass:[ObservationAnnotation class]]) {
            ObservationAnnotation *obsAnn = (ObservationAnnotation *)aV.annotation;

            if (obsAnn.selected) {
                /**
                 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^
                 {
                 [mapView selectAnnotation:obsAnn animated:YES];
                 });
                 */
                dispatch_async(dispatch_get_main_queue(), ^{
                    [mapView selectAnnotation:obsAnn animated:NO];
                });
            } else if (obsAnn.animateDrop) {
                CGRect endFrame = aV.frame;
                
                // Move annotation out of view
                aV.frame = CGRectMake(aV.frame.origin.x, aV.frame.origin.y - mapView.frame.size.height, aV.frame.size.width, aV.frame.size.height);
                
                // Animate drop
                [UIView animateWithDuration:0.5 delay:0.04*[views indexOfObject:aV] options: UIViewAnimationOptionCurveLinear animations:^{
                    
                    aV.frame = endFrame;
                    
                    // Animate squash
                }completion:^(BOOL finished){
                    if (finished) {
                        [UIView animateWithDuration:0.05 animations:^{
                            aV.transform = CGAffineTransformMakeScale(1.0, 0.8);
                            
                        }completion:^(BOOL finished){
                            if (finished) {
                                [UIView animateWithDuration:0.1 animations:^{
                                    aV.transform = CGAffineTransformIdentity;
                                    
                                }];
                            }
                        }];
                    }
                }];
            }
            return;
        }
    }
}

-(void)mapTap: (CGPoint) tapPoint {

    CLLocationCoordinate2D tapCoord = [self.mapView convertPoint:tapPoint toCoordinateFromView:self.mapView];
    MKMapPoint mapPoint = MKMapPointForCoordinate(tapCoord);
    CGPoint mapPointAsCGP = CGPointMake(mapPoint.x, mapPoint.y);
    
    double tolerance = [GPKGMapUtils toleranceWithCGPoint:tapPoint andMapView:self.mapView andScreenPercentage:.02].screen;
    
    if (_areaAnnotation != nil) {
        [_mapView deselectAnnotation:_areaAnnotation animated:NO];
        [_mapView removeAnnotation:_areaAnnotation];
        _areaAnnotation = nil;
    }
    
    CGRect tapRect = CGRectMake(mapPointAsCGP.x, mapPointAsCGP.y, tolerance, tolerance);
    
    for (NSString* layerId in self.staticLayers) {
        NSArray *layerFeatures = [self.staticLayers objectForKey:layerId];
        for (id feature in layerFeatures) {
            if ([feature isKindOfClass:[MKPolyline class]]) {
                MKPolyline *polyline = (MKPolyline *) feature;
                
                MKMapPoint *polylinePoints = polyline.points;
                
                for (int p=0; p < polyline.pointCount-1; p++){
                    MKMapPoint mp = polylinePoints[p];
                    MKMapPoint mp2 = polylinePoints[p+1];
                    
                    if ([MapUtils rect:tapRect ContainsLineStart:CGPointMake(mp.x, mp.y) andLineEnd:CGPointMake(mp2.x, mp2.y)]) {
                        NSLog(@"tapped the polyline in layer %@ named %@", layerId, polyline.title);
                        [self.cacheOverlayDelegate onCacheOverlayTapped:polyline.title];
                        return;
                    }
                }
            } else if ([feature isKindOfClass:[MKPolygon class]]){
                MKPolygon *polygon = (MKPolygon*) feature;
                
                CGMutablePathRef mpr = CGPathCreateMutable();
                
                MKMapPoint *polygonPoints = polygon.points;
                
                for (int p=0; p < polygon.pointCount; p++){
                    MKMapPoint mp = polygonPoints[p];
                    if (p == 0)
                        CGPathMoveToPoint(mpr, NULL, mp.x, mp.y);
                    else
                        CGPathAddLineToPoint(mpr, NULL, mp.x, mp.y);
                }
                
                if(CGPathContainsPoint(mpr , NULL, mapPointAsCGP, FALSE)){
                    NSLog(@"tapped the polygon in layer %@ named %@", layerId, polygon.title);
                    [self.cacheOverlayDelegate onCacheOverlayTapped:polygon.title];
                    return;
                }
                
                CGPathRelease(mpr);
            }
        }
    }
    
    if ([self.mapCacheOverlays count] > 0) {
        NSMutableString * clickMessage = [[NSMutableString alloc] init];
        for (CacheOverlay * cacheOverlay in [self.mapCacheOverlays allValues]){
            NSString * message = [cacheOverlay onMapClickWithLocationCoordinate:tapCoord andMap:self.mapView];
            if (message != nil){
                if ([clickMessage length] > 0){
                    [clickMessage appendString:@"</br>"];
                }
                [clickMessage appendString:message];
            }
        }
        
        if ([clickMessage length] > 0) {
            if ([self.cacheOverlayDelegate respondsToSelector:@selector(onCacheOverlayTapped:)]) {
                [self.cacheOverlayDelegate onCacheOverlayTapped:clickMessage];
            }
        }
    }
}

- (void) cleanup {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    @try {
        for (NSString *keyPath in self.listenersRegistered) {
            [defaults removeObserver:self forKeyPath:keyPath];
        }
        self.listenersRegistered = nil;
    }
    @catch (id exception) {
        NSLog(@"Failed to remove observer from user defaults: %@", exception);
    }
    
    [[CacheOverlays getInstance] unregisterListener:self];
    
    [self.mapObservations clear];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MAGEFormFetched object:nil];

    self.locationManager.delegate = nil;
    self.locationManager = nil;
    self.observations.fetchedResultsController.delegate = nil;
    self.observations = nil;
    self.locations.fetchedResultsController.delegate = nil;
    self.locations = nil;
    if (self.selectedUserAccuracy) {
        [self.mapView removeOverlay:self.selectedUserAccuracy];
        self.selectedUserAccuracy = nil;
    }
    if (self.selectedObservationAccuracy) {
        [self.mapView removeOverlay:self.selectedObservationAccuracy];
        self.selectedObservationAccuracy = nil;
    }
    [self.darkCountriesGeoPackage close];
    [self.darkCountriesGeoPackage.metadataDb close];
    self.darkCountriesGeoPackage = nil;
    [self.countriesGeoPackage close];
    [self.countriesGeoPackage.metadataDb close];
    self.countriesGeoPackage = nil;
    [self.geoPackageCache closeAll];
    [self.geoPackageManager close];
    self.geoPackageManager = nil;
    self.geoPackageCache = nil;
}

- (void) addFeeds {
    if (self.feedItemRetrievers == nil) {
        self.feedItemRetrievers = [[NSMutableDictionary alloc] init];
    }
    NSArray *feedIdsInEvent = [[NSUserDefaults standardUserDefaults] arrayForKey:[NSString stringWithFormat:@"selectedFeeds-%@", [Server currentEventId]]];
    
    // remove any feeds that are no longer selected
    [self.currentFeeds filterUsingPredicate:[NSPredicate predicateWithFormat:@"NOT(self in %@)", feedIdsInEvent]];
    for (NSNumber *feedId in self.currentFeeds) {
        [self.feedItemRetrievers removeObjectForKey:feedId];
        NSArray<FeedItem*> *items = [FeedItem getFeedItemsForFeed:feedId];
        for (FeedItem *item in items) {
            if (item.isMappable) {
                [self.mapView removeAnnotation:item];
            }
        }
    }
    
    for (NSString *feedId in feedIdsInEvent) {
        FeedItemRetriever *retriever = [self.feedItemRetrievers objectForKey:feedId];
        if (retriever == nil) {
            retriever = [FeedItemRetriever getMappableFeedRetrieverWithFeedId:feedId delegate:self];
        }
        if (retriever != nil) {
            [self.feedItemRetrievers setObject:retriever forKey:feedId];
            NSArray<FeedItem*> *items = [retriever startRetriever];
            for (FeedItem *item in items) {
                if (item.isMappable) {
                    [self.mapView addAnnotation:item];
                }
            }
        }
    }
    [self.currentFeeds addObjectsFromArray:feedIdsInEvent];
}

- (NSMutableDictionary *) staticLayers {
    if (_staticLayers == nil) {
        _staticLayers = [[NSMutableDictionary alloc] init];
    }
    
    return _staticLayers;
}

- (NSMutableDictionary *) onlineLayers {
    if (_onlineLayers == nil) {
        _onlineLayers = [[NSMutableDictionary alloc] init];
    }
    return _onlineLayers;
}

- (NSMutableArray *) currentFeeds {
    if (_currentFeeds == nil) {
        _currentFeeds = [[NSMutableArray alloc] init];
    }
    return _currentFeeds;
}

- (void) setLocations:(Locations *) locations {
    _locations = locations;
    if (!_locations) return;
    _locations.delegate = self;
    
    [self.mapView removeAnnotations:[self.locationAnnotations allValues]];
    [self.locationAnnotations removeAllObjects];
    
    NSError *error;
    if (![self.locations.fetchedResultsController performFetch:&error]) {
        NSLog(@"Failed to perform fetch in the MapDelegate for locations %@, %@", error, [error userInfo]);
        return;
    }
    
    [self updateLocations:[self.locations.fetchedResultsController fetchedObjects]];
}

- (void) setObservations:(Observations *)observations withCompletion: (void (^)(void)) complete {
    _observations = observations;
    if (!_observations) return;
    _observations.delegate = self;
    
    Event *event = [Event getCurrentEventInContext:observations.fetchedResultsController.managedObjectContext];
    
    _mapObservationManager = [[MapObservationManager alloc] initWithMapView:self.mapView andEventForms:event.forms];
    
    [self.observationAnnotations clear];
    
    NSError *error;
    self.observations.fetchedResultsController.fetchRequest.fetchBatchSize = 0;
    if (![self.observations.fetchedResultsController performFetch:&error]) {
        NSLog(@"Failed to perform fetch in the MapDelegate for observations %@, %@", error, [error userInfo]);
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        if (weakSelf.hideObservations) {
            [weakSelf updateObservations:[((Observations *)[Observations hideObservations]).fetchedResultsController fetchedObjects]];
        } else {
            [weakSelf updateObservations:[weakSelf.observations.fetchedResultsController fetchedObjects]];
        }
        complete();
    });
}

- (void) formFetched: (NSNotification *) notification {
    Event *event = (Event *)notification.object;
    if ([[Server currentEventId] isEqualToNumber:event.remoteId]) {
        __weak typeof(self) weakSelf = self;
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
        dispatch_async(queue, ^{
            [weakSelf updateObservations:[weakSelf.observations.fetchedResultsController fetchedObjects]];
        });
    }
}

- (void) setObservations:(Observations *)observations {
    [self setObservations:observations withCompletion:^{
        
    }];
}

- (void) updateObservationPredicates: (NSMutableArray *) predicates {
    [self.observations.fetchedResultsController.fetchRequest setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicates]];
    NSError *error;
    if (![self.observations.fetchedResultsController performFetch:&error]) {
        NSLog(@"Failed to perform fetch in the MapDelegate for new observation predeicates %@, %@", error, [error userInfo]);
        return;
    }
    NSArray *observations = [self.observations.fetchedResultsController fetchedObjects];
    NSMutableArray *newObservations = [[NSMutableArray alloc] init];
    NSArray *currentObservationIds = [self.mapObservations.observationIds allKeys];
    NSMutableArray *observationIds = [[NSMutableArray alloc] initWithCapacity:observations.count];
    for (Observation *observation in observations) {
        if (![currentObservationIds containsObject:observation.objectID]) {
            [newObservations addObject:observation];
        }
        [observationIds addObject:observation.objectID];
    }
    [self.mapObservations removeObservationsNotInArray:observationIds];

    __weak typeof(self) weakSelf = self;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        [weakSelf updateObservations:newObservations];
    });
}

- (void) updateLocationPredicates: (NSMutableArray *) predicates {
    [self.locations.fetchedResultsController.fetchRequest setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicates]];
    
    NSError *error;
    if (![self.locations.fetchedResultsController performFetch:&error]) {
        NSLog(@"Failed to perform fetch in the MapDelegate for new location predicates %@, %@", error, [error userInfo]);
        return;
    }
    
    NSArray *locations = [self.locations.fetchedResultsController fetchedObjects];
    NSMutableArray *userRemoteIds = [[NSMutableArray alloc] initWithCapacity:locations.count];
    for (Location *location in locations) {
        [userRemoteIds addObject:location.user.remoteId];
    }
    
    NSMutableArray *ids = [NSMutableArray arrayWithArray:[self.locationAnnotations allKeys]];
    [ids removeObjectsInArray:userRemoteIds];
    
    for (NSString *userRemoteId in ids) {
        [self removeLocationForUser:userRemoteId];
    }
    [self updateLocations:[self.locations.fetchedResultsController fetchedObjects]];
}

- (void) ensureMapLayout {
    if (!self.mapCacheOverlays) {
        self.mapCacheOverlays = [[NSMutableDictionary alloc] init];
    }

    [self createBackgroundOverlay];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self setupMapType:defaults];
        
    BOOL showTraffic = [defaults boolForKey:@"mapShowTraffic"];
    self.mapView.showsTraffic = showTraffic && self.mapView.mapType != MKMapTypeSatellite && self.mapView.mapType != 3;
    
    [self updateCacheOverlaysSynchronized:[[CacheOverlays getInstance] getOverlays]];
    
    [self updateStaticLayers:[defaults objectForKey:@"selectedStaticLayers"]];
    [self updateOnlineLayers:[defaults objectForKey:@"selectedOnlineLayers"]];
}

-(void) observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context {
    if ([@"mapType" isEqualToString:keyPath] && self.mapView) {
        [self ensureMapLayout];
    } else if ([@"selectedStaticLayers" isEqualToString:keyPath] && self.mapView) {
        [self updateStaticLayers: [object objectForKey:keyPath]];
    } else if ([@"selectedOnlineLayers" isEqualToString:keyPath] && self.mapView) {
        [self updateOnlineLayers: [object objectForKey:keyPath]];
    } else if ([kCurrentEventIdKey isEqualToString:keyPath] && self.mapView) {
        [self updateCacheOverlaysSynchronized:[[CacheOverlays getInstance] getOverlays]];
    } else if ([@"selectedFeeds" isEqualToString:keyPath] && self.mapView) {
        
    }
}

- (void) setupMapType: (id) object {
    NSInteger mapType = [object integerForKey:@"mapType"];
    if (mapType == 3) {
        [self addBackgroundMap];
    } else {
        self.mapView.mapType = [object integerForKey:@"mapType"];
        [self removeBackgroundMap];
    }
}

-(void) cacheOverlaysUpdated: (NSArray<CacheOverlay *> *) cacheOverlays{
    if(self.mapView) {
        [self updateCacheOverlaysSynchronized:cacheOverlays];
    }
}

-(void) setHideLocations:(BOOL) hideLocations {
    _hideLocations = hideLocations;
    [self hideAnnotations:[self.locationAnnotations allValues] hide:hideLocations];
}

-(void) setHideObservations:(BOOL) hideObservations {
    if (_hideObservations != hideObservations) {
        _hideObservations = hideObservations;
        [self updateObservationPredicates:[Observations getPredicatesForObservationsForMap]];
    }
}

- (void) hideAnnotations:(NSArray *) annotations hide:(BOOL) hide {
    for (id<MKAnnotation> annotation in annotations) {
        MKAnnotationView *annotationView = [self.mapView viewForAnnotation:annotation];
        annotationView.hidden = hide;
        annotationView.accessibilityElementsHidden = hide;
        annotationView.enabled = !hide;
    }
}

/**
 *  Synchronously update the cache overlays, including overlays and features
 *
 *  @param cacheOverlays cache overlays
 */
- (void) updateCacheOverlaysSynchronized:(NSArray<CacheOverlay *> *) cacheOverlays {
    NSLog(@"Update Cache Overlays Synchronized %@", cacheOverlays);
    @synchronized(self.cacheOverlayUpdateLock){
        
        // Set the cache overlays to update, including wiping out an update that hasn't processed
        self.cacheOverlayUpdate = [[CacheOverlayUpdate alloc] initWithCacheOverlays:cacheOverlays];
        
        // Is a thread currently updating the cache overlays?
        if(self.updatingCacheOverlays){
            // Notify the thread that there is an update waiting
            self.waitingCacheOverlaysUpdate = true;
        }else{
        
            // Start a new update thread
            self.updatingCacheOverlays = true;
            
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
            dispatch_async(queue, ^{
                
                // Synchronously pull the next cache overlays to update
                CacheOverlayUpdate * overlaysToUpdate = [self getNextCacheOverlaysToUpdate];
                while(overlaysToUpdate != nil){
                    // Update the cache overlays
                    [self updateCacheOverlays:cacheOverlays];
                    overlaysToUpdate = [self getNextCacheOverlaysToUpdate];
                }

            });
        }
    }
    
}

/**
 *  Synchronously get the next cache overlays to update
 *
 *  @return cache overlays
 */
-(CacheOverlayUpdate *) getNextCacheOverlaysToUpdate{
    CacheOverlayUpdate * overlaysToUpdate = nil;
    // Synchronize on the update cache overlays to pull the next update
    @synchronized(self.cacheOverlayUpdateLock){
        // Get the update cache overlays and remove them
        overlaysToUpdate = self.cacheOverlayUpdate;
        self.cacheOverlayUpdate = nil;
        if(overlaysToUpdate == nil){
            // Notify that the updating thread is stopping
            self.updatingCacheOverlays = false;
        }
        // Reset the update waiting variable
        self.waitingCacheOverlaysUpdate = false;
    }
    return overlaysToUpdate;
}

/**
 *  Update all cache overlays by adding and removing overlays and features
 *
 *  @param cacheOverlays cache overlays
 */
- (void) updateCacheOverlays:(NSArray<CacheOverlay *> *) cacheOverlays {
    
    // Track enabled cache overlays
    NSMutableDictionary<NSString *, CacheOverlay *> *enabledCacheOverlays = [[NSMutableDictionary alloc] init];
    
    // Track enabled GeoPackages
    NSMutableSet<NSString *> * enabledGeoPackages = [[NSMutableSet alloc] init];
    
    // Reset the bounding box for newly added caches
    self.addedCacheBoundingBox = nil;
    
    for (CacheOverlay *cacheOverlay in cacheOverlays) {
        
        // If this cache overlay was replaced by a new version, remove the old from the map
        if(cacheOverlay.replacedCacheOverlay != nil){
            dispatch_sync(dispatch_get_main_queue(), ^{
                [cacheOverlay.replacedCacheOverlay removeFromMap:self.mapView];
            });
            if([cacheOverlay getType] == GEOPACKAGE){
                [self.geoPackageCache closeByName:[cacheOverlay getName]];
            }
        }
        
        // The user has asked for this overlay
        if(cacheOverlay.enabled){
            
            // Handle each type of cache overlay
            switch([cacheOverlay getType]){
             
                case XYZ_DIRECTORY:
                    [self addXYZDirectoryCacheOverlayWithEnabled:enabledCacheOverlays andCacheOverlay:(XYZDirectoryCacheOverlay *)cacheOverlay];
                    break;
                    
                case GEOPACKAGE:
                    [self addGeoPackageCacheOverlay:enabledCacheOverlays andEnabledGeoPackages:enabledGeoPackages andCacheOverlay:(GeoPackageCacheOverlay *)cacheOverlay];
                    break;
                    
                default:
                    break;
            }
        }
        
        [cacheOverlay setAdded:false];
        [cacheOverlay setReplacedCacheOverlay:nil];
    }
    
    // Remove any overlays that are on the map but no longer selected
    for(CacheOverlay * cacheOverlay in [self.mapCacheOverlays allValues]){
        dispatch_sync(dispatch_get_main_queue(), ^{
            [cacheOverlay removeFromMap:self.mapView];
        });
    }
    self.mapCacheOverlays = enabledCacheOverlays;
    
    // Close GeoPackages no longer enabled
    [self.geoPackageCache closeRetain:[enabledGeoPackages allObjects]];
    
    // If a new cache was added, zoom to the bounding box area
    if(self.addedCacheBoundingBox != nil){
        
        struct GPKGBoundingBoxSize size = [self.addedCacheBoundingBox sizeInMeters];
        CLLocationCoordinate2D center = [self.addedCacheBoundingBox center];
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(center, size.height, size.width);
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.mapView setRegion:region animated:true];
        });
    }
}

/**
 *  Add XYZ directory cache overlays to the map
 *
 *  @param enabledCacheOverlays     enabled cache overlays to add to
 *  @param xyzDirectoryCacheOverlay cache overlay
 */
-(void) addXYZDirectoryCacheOverlayWithEnabled: (NSMutableDictionary<NSString *, CacheOverlay *> *) enabledCacheOverlays andCacheOverlay: (XYZDirectoryCacheOverlay *) xyzDirectoryCacheOverlay{
    // Retrieve the cache overlay if it already exists (and remove from cache overlays)
    NSString * cacheName = [xyzDirectoryCacheOverlay getCacheName];
    CacheOverlay * cacheOverlay = [self.mapCacheOverlays objectForKey:cacheName];
    if(cacheOverlay == nil){
        
        // Set the cache directory path
        NSString *cacheDirectory = [xyzDirectoryCacheOverlay getDirectory];
        
        // Find the image extension type
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:cacheDirectory];
        NSString * patternExtension = nil;
        for (NSString *file in enumerator) {
            NSString * extension = [file pathExtension];
            if([extension caseInsensitiveCompare:@"png"] == NSOrderedSame ||
               [extension caseInsensitiveCompare:@"jpeg"] == NSOrderedSame ||
               [extension caseInsensitiveCompare:@"jpg"] == NSOrderedSame){
                patternExtension = extension;
                break;
            }
        }
        
        NSString *template = [NSString stringWithFormat:@"file://%@/{z}/{x}/{y}", cacheDirectory];
        if(patternExtension != nil){
            template = [NSString stringWithFormat:@"%@.%@", template, patternExtension];
        }
        MKTileOverlay *tileOverlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
        tileOverlay.minimumZ = xyzDirectoryCacheOverlay.minZoom;
        tileOverlay.maximumZ = xyzDirectoryCacheOverlay.maxZoom;
        [xyzDirectoryCacheOverlay setTileOverlay:tileOverlay];
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSLog(@"Adding xyz cache");
            [self.mapView addOverlay:tileOverlay level:MKOverlayLevelAboveRoads];
        });
        
        cacheOverlay = xyzDirectoryCacheOverlay;
    }else{
        [self.mapCacheOverlays removeObjectForKey:cacheName];
    }
    // Add the cache overlay to the enabled cache overlays
    [enabledCacheOverlays setObject:cacheOverlay forKey:cacheName];
    
}

/**
 *  Add GeoPackage cache overlays to the map, as map overlays and/or features
 *
 *  @param enabledCacheOverlays   enabled cache overlays to add to
 *  @param enabledGeoPackages     enabled GeoPackages to add to
 *  @param geoPackageCacheOverlay cache overlay
 */
-(void) addGeoPackageCacheOverlay: (NSMutableDictionary<NSString *, CacheOverlay *> *) enabledCacheOverlays andEnabledGeoPackages: (NSMutableSet<NSString *> *) enabledGeoPackages andCacheOverlay: (GeoPackageCacheOverlay *) geoPackageCacheOverlay{
    
    // Check each GeoPackage table
    for(CacheOverlay * tableCacheOverlay in [geoPackageCacheOverlay getChildren]){
        // Check if the table is enabled
        if(tableCacheOverlay.enabled || YES){
            
            // Get and open if needed the GeoPackage
            GPKGGeoPackage * geoPackage = [self.geoPackageCache geoPackageOpenName: [geoPackageCacheOverlay getName]];
            [enabledGeoPackages addObject:geoPackage.name];
            
            // Handle tile and feature tables
            switch([tableCacheOverlay getType]){
                case GEOPACKAGE_TILE_TABLE:
                    [self addGeoPackageTileCacheOverlay:enabledCacheOverlays andCacheOverlay:(GeoPackageTileTableCacheOverlay *)tableCacheOverlay andGeoPackage:geoPackage andLinkedToFeatures:false];
                    break;
                case GEOPACKAGE_FEATURE_TABLE:
                    [self addGeoPackageFeatureCacheOverlay:enabledCacheOverlays andCacheOverlay:(GeoPackageFeatureTableCacheOverlay *)tableCacheOverlay andGeoPackage:geoPackage];
                    break;
                default:
                    [NSException raise:@"Unsupported" format:@"Unsupported GeoPackage type: %d", [tableCacheOverlay getType]];
            }
            
            // If a newly added cache, update the bounding box for zooming
            if(geoPackageCacheOverlay.added){
                
                GPKGContentsDao * contentsDao = [geoPackage contentsDao];
                GPKGContents * contents = (GPKGContents *)[contentsDao queryForIdObject:[tableCacheOverlay getName]];
                GPKGBoundingBox * contentsBoundingBox = [contents boundingBox];
                SFPProjection * projection = [contentsDao projection:contents];
                
                SFPProjectionTransform * transform = [[SFPProjectionTransform alloc] initWithFromProjection:projection andToEpsg:PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
                GPKGBoundingBox * boundingBox = [contentsBoundingBox transform:transform];
                boundingBox = [GPKGTileBoundingBoxUtils boundWgs84BoundingBoxWithWebMercatorLimits:boundingBox];
                
                if(self.addedCacheBoundingBox == nil){
                    self.addedCacheBoundingBox = boundingBox;
                }else{
                    self.addedCacheBoundingBox = [GPKGTileBoundingBoxUtils unionWithBoundingBox:self.addedCacheBoundingBox andBoundingBox:boundingBox];
                }

            }
        }
    }
}

/**
 *  Add GeoPackage tile cache overlays
 *
 *  @param enabledCacheOverlays  enabled cache overlays to add to
 *  @param tileTableCacheOverlay tile table cache overlay
 *  @param geoPackage            GeoPackage
 *  @param linkedToFeatures false if a normal tile table, true if linked to a feature table
 */
-(void) addGeoPackageTileCacheOverlay: (NSMutableDictionary<NSString *, CacheOverlay *> *) enabledCacheOverlays andCacheOverlay: (GeoPackageTileTableCacheOverlay *) tileTableCacheOverlay andGeoPackage: (GPKGGeoPackage *) geoPackage andLinkedToFeatures: (BOOL) linkedToFeatures{
    
    // Retrieve the cache overlay if it already exists (and remove from cache overlays)
    NSString * cacheName = [tileTableCacheOverlay getCacheName];
    CacheOverlay * cacheOverlay = [self.mapCacheOverlays objectForKey:cacheName];
    GPKGBoundedOverlay * geoPackageTileOverlay;
    @try {
        if(cacheOverlay != nil){
            [self.mapCacheOverlays removeObjectForKey:cacheName];
            // If the existing cache overlay is being replaced, create a new cache overlay
            if(tileTableCacheOverlay.parent.replacedCacheOverlay != nil){
                cacheOverlay = nil;
            } else {
                // remove the old one and it will be re-added to preserve layer order
                [self.mapView removeOverlay:tileTableCacheOverlay.tileOverlay];
                cacheOverlay = nil;
            }
        }
        if(cacheOverlay == nil){
            // Create a new GeoPackage tile provider and add to the map
            GPKGTileDao * tileDao = [geoPackage tileDaoWithTableName:[tileTableCacheOverlay getName]];
            geoPackageTileOverlay = [GPKGOverlayFactory boundedOverlay:tileDao];
            geoPackageTileOverlay.canReplaceMapContent = false;
            [tileTableCacheOverlay setTileOverlay:geoPackageTileOverlay];
            
            // Check for linked feature tables
            [tileTableCacheOverlay.featureOverlayQueries removeAllObjects];
            GPKGFeatureTileTableLinker * linker = [[GPKGFeatureTileTableLinker alloc] initWithGeoPackage:geoPackage];
            NSArray<GPKGFeatureDao *> * featureDaos = [linker featureDaosForTileTable:tileDao.tableName];
            for(GPKGFeatureDao * featureDao in featureDaos){
                
                 // Create the feature tiles
                GPKGFeatureTiles * featureTiles = [[GPKGFeatureTiles alloc] initWithFeatureDao:featureDao];
                
                // Create an index manager
                GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
                [featureTiles setIndexManager:indexer];
                
                // Add the feature overlay query
                GPKGFeatureOverlayQuery * featureOverlayQuery = [[GPKGFeatureOverlayQuery alloc] initWithBoundedOverlay:geoPackageTileOverlay andFeatureTiles:featureTiles];
                [tileTableCacheOverlay.featureOverlayQueries addObject:featureOverlayQuery];
            }
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.mapView addOverlay:geoPackageTileOverlay level:(linkedToFeatures ? MKOverlayLevelAboveLabels: MKOverlayLevelAboveRoads)];
            });
            
            cacheOverlay = tileTableCacheOverlay;
        }
        // Add the cache overlay to the enabled cache overlays
        [enabledCacheOverlays setObject:cacheOverlay forKey:cacheName];
    }
    @catch (NSException *e) {
        NSLog(@"Exception adding GeoPackage tile cache overlay %@", e);
        __weak typeof(self) weakSelf = self;

        dispatch_sync(dispatch_get_main_queue(), ^{
            if (tileTableCacheOverlay != nil) {
                [tileTableCacheOverlay removeFromMap:weakSelf.mapView];
            }
            if (geoPackageTileOverlay != nil) {
                [weakSelf.mapView removeOverlay:geoPackageTileOverlay];
            }
        });
    }
}

- (void) createBackgroundOverlay {
    if (self.backgroundOverlay) return;
    GPKGGeoPackageManager *manager = [GPKGGeoPackageFactory manager];
    self.countriesGeoPackage = [manager open:@"countries"];
    if (self.countriesGeoPackage) {
        GPKGFeatureDao * featureDao = [self.countriesGeoPackage featureDaoWithTableName:@"countries"];
        
        // If indexed, add as a tile overlay
        GPKGFeatureTiles * featureTiles = [[GPKGFeatureTiles alloc] initWithGeoPackage:self.countriesGeoPackage andFeatureDao:featureDao];
        [featureTiles setIndexManager:[[GPKGFeatureIndexManager alloc] initWithGeoPackage:self.countriesGeoPackage andFeatureDao:featureDao]];
        
        self.backgroundOverlay = [[BaseMapOverlay alloc] initWithFeatureTiles:featureTiles];
        [self.backgroundOverlay setMinZoom:0];
        self.backgroundOverlay.darkTheme = NO;

        self.backgroundOverlay.canReplaceMapContent = true;
    }
    
    self.darkCountriesGeoPackage = [manager open:@"countries_dark"];
    if (self.darkCountriesGeoPackage) {
        GPKGFeatureDao * darkFeatureDao = [self.darkCountriesGeoPackage featureDaoWithTableName:@"countries"];
        
        // If indexed, add as a tile overlay
        GPKGFeatureTiles * darkFeatureTiles = [[GPKGFeatureTiles alloc] initWithGeoPackage:self.darkCountriesGeoPackage andFeatureDao:darkFeatureDao];
        [darkFeatureTiles setIndexManager:[[GPKGFeatureIndexManager alloc] initWithGeoPackage:self.darkCountriesGeoPackage andFeatureDao:darkFeatureDao]];
        
        self.darkBackgroundOverlay = [[BaseMapOverlay alloc] initWithFeatureTiles:darkFeatureTiles];
        [self.darkBackgroundOverlay setMinZoom:0];
        self.darkBackgroundOverlay.darkTheme = YES;

        self.darkBackgroundOverlay.canReplaceMapContent = true;
    }
}

- (void) addBackgroundMap {
    if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        [self.mapView removeOverlay:self.backgroundOverlay];
        [self.mapView addOverlay:self.darkBackgroundOverlay level:MKOverlayLevelAboveRoads];
    } else {
        NSLog(@"Adding the background map");
        [self.mapView removeOverlay:self.darkBackgroundOverlay];
        [self.mapView addOverlay:self.backgroundOverlay level:MKOverlayLevelAboveRoads];
    }
}

- (void) removeBackgroundMap {
    [self.mapView removeOverlay: self.backgroundOverlay];
    [self.mapView removeOverlay: self.darkBackgroundOverlay];
}

/**
 *  Add GeoPackage feature cache overlays, as overlays when indexed or as features when not
 *
 *  @param enabledCacheOverlays     enabled cache overlays to add to
 *  @param featureTableCacheOverlay feature table cache overlay
 *  @param geoPackage               GeoPackage
 */
-(void) addGeoPackageFeatureCacheOverlay: (NSMutableDictionary<NSString *, CacheOverlay *> *) enabledCacheOverlays andCacheOverlay: (GeoPackageFeatureTableCacheOverlay *) featureTableCacheOverlay andGeoPackage: (GPKGGeoPackage *) geoPackage{
    BOOL addAsEnabled = true;
    // Retrieve the cache overlay if it already exists (and remove from cache overlays)
    NSString * cacheName = [featureTableCacheOverlay getCacheName];
    CacheOverlay * cacheOverlay = [self.mapCacheOverlays objectForKey:cacheName];
    GPKGFeatureOverlay * featureOverlay;
    @try {
        if(cacheOverlay != nil){
            [self.mapCacheOverlays removeObjectForKey:cacheName];
            // If the existing cache overlay is being replaced, create a new cache overlay
            if(featureTableCacheOverlay.parent.replacedCacheOverlay != nil){
                cacheOverlay = nil;
            }
            for(GeoPackageTileTableCacheOverlay * linkedTileTable in [featureTableCacheOverlay getLinkedTileTables]){
                if(cacheOverlay != nil){
                    // Add the existing linked tile cache overlays
                    [self addGeoPackageTileCacheOverlay:enabledCacheOverlays andCacheOverlay:linkedTileTable andGeoPackage:geoPackage andLinkedToFeatures:true];
                }
                [self.mapCacheOverlays removeObjectForKey:[linkedTileTable getCacheName]];
            }
        }
        if(cacheOverlay == nil){
            // Add the features to the map
            GPKGFeatureDao * featureDao = [geoPackage featureDaoWithTableName:[featureTableCacheOverlay getName]];
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            
            // If indexed, add as a tile overlay
            if([featureTableCacheOverlay getIndexed]){
                GPKGFeatureTiles * featureTiles = [[GPKGFeatureTiles alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
                int maxFeaturesPerTile = 0;
                if([featureDao geometryType] == SF_POINT){
                    maxFeaturesPerTile = (int)[defaults integerForKey:@"geopackage_feature_tiles_max_points_per_tile"];
                }else{
                    maxFeaturesPerTile = (int)[defaults integerForKey:@"geopackage_feature_tiles_max_features_per_tile"];
                }
                [featureTiles setMaxFeaturesPerTile:[NSNumber numberWithInt:maxFeaturesPerTile]];
                GPKGNumberFeaturesTile * numberFeaturesTile = [[GPKGNumberFeaturesTile alloc] init];
                // Adjust the max features number tile draw paint attributes here as needed to
                // change how tiles are drawn when more than the max features exist in a tile
                [featureTiles setMaxFeaturesTileDraw:numberFeaturesTile];
                [featureTiles setIndexManager:[[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao]];
                // Adjust the feature tiles draw paint attributes here as needed to change how
                // features are drawn on tiles
                featureOverlay = [[GPKGFeatureOverlay alloc] initWithFeatureTiles:featureTiles];
                [featureOverlay setMinZoom:[NSNumber numberWithInt:[featureTableCacheOverlay getMinZoom]]];
                
                GPKGFeatureTileTableLinker * linker = [[GPKGFeatureTileTableLinker alloc] initWithGeoPackage:geoPackage];
                NSArray<GPKGTileDao *> * tileDaos = [linker tileDaosForFeatureTable:featureDao.tableName];
                [featureOverlay ignoreTileDaos:tileDaos];
                
                GPKGFeatureOverlayQuery * featureOverlayQuery = [[GPKGFeatureOverlayQuery alloc] initWithFeatureOverlay:featureOverlay];
                [featureTableCacheOverlay setFeatureOverlayQuery:featureOverlayQuery];
                featureOverlay.canReplaceMapContent = false;
                [featureTableCacheOverlay setTileOverlay:featureOverlay];
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    NSLog(@"Adding feature overlay");
                    [self.mapView addOverlay:featureOverlay level:MKOverlayLevelAboveLabels];
                });
                
                cacheOverlay = featureTableCacheOverlay;
            }
            // Not indexed, add the features to the map
            else {
                int maxFeaturesPerTable = 0;
                if([featureDao geometryType] == SF_POINT){
                    maxFeaturesPerTable = (int)[defaults integerForKey:@"geopackage_features_max_points_per_table"];
                }else{
                    maxFeaturesPerTable = (int)[defaults integerForKey:@"geopackage_features_max_features_per_table"];
                }
                SFPProjection * projection = featureDao.projection;
                GPKGMapShapeConverter * shapeConverter = [[GPKGMapShapeConverter alloc] initWithProjection:projection];
                GPKGResultSet * resultSet = [featureDao queryForAll];
                @try {
                    int totalCount = [resultSet count];
                    int count = 0;
                    while([resultSet moveToNext]){
                        // If there is another cache overlay update waiting, stop and remove this overlay to let the next update handle it
                        if(self.waitingCacheOverlaysUpdate){
                            addAsEnabled = false;
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                [featureTableCacheOverlay removeFromMap:self.mapView];
                            });
                            break;
                        }
                        GPKGFeatureRow * featureRow = [featureDao featureRow:resultSet];
                        GPKGGeometryData * geometryData = [featureRow geometry];
                        if(geometryData != nil && !geometryData.empty){
                            SFGeometry * geometry = geometryData.geometry;
                            if(geometry != nil){
                                @try {
                                    GPKGMapShape * shape = [shapeConverter toShapeWithGeometry:geometry];
                                    [featureTableCacheOverlay addShapeWithId:[featureRow id] andShape:shape];
                                    dispatch_sync(dispatch_get_main_queue(), ^{
                                        [GPKGMapShapeConverter addMapShape:shape toMapView:self.mapView];
                                    });
                                }
                                @catch (NSException *e) {
                                    NSLog(@"Failed to parse geometry: %@", e);
                                }
                                
                                if(++count >= maxFeaturesPerTable){
                                    if(count < totalCount){
                                        NSLog(@"%@- added %d of %d", cacheName, count, totalCount);
                                    }
                                    break;
                                }
                            }
                        }
                    }
                }
                @finally {
                    [resultSet close];
                }
            }
        
            // Add linked tile tables
            for(GeoPackageTileTableCacheOverlay * linkedTileTable in [featureTableCacheOverlay getLinkedTileTables]){
                [self addGeoPackageTileCacheOverlay:enabledCacheOverlays andCacheOverlay:linkedTileTable andGeoPackage:geoPackage andLinkedToFeatures:true];
            }
            
            cacheOverlay = featureTableCacheOverlay;
        }
    
        // If not cancelled for a waiting update
        if(addAsEnabled){
            // Add the cache overlay to the enabled cache overlays
            [enabledCacheOverlays setObject:cacheOverlay forKey:cacheName];
        }
    }
    @catch (NSException *e) {
        NSLog(@"Exception adding GeoPackage feature cache overlay %@", e);
        __weak typeof(self) weakSelf = self;
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (featureTableCacheOverlay != nil) {
                [featureTableCacheOverlay removeFromMap:weakSelf.mapView];
            }
            if (featureOverlay != nil) {
                [self.mapView removeOverlay:featureOverlay];
            }
        });
    }
}

- (void) updateOnlineLayers: (NSDictionary *) onlineLayersPerEvent {
    NSLog(@"update online layers");
    NSMutableSet *unselectedOnlineLayers = [[self.onlineLayers allKeys] mutableCopy];
    NSMutableArray *transparentLayers = [[NSMutableArray alloc] init];
    NSMutableArray *nonBaseLayers = [[NSMutableArray alloc] init];
    NSMutableArray *baseLayers = [[NSMutableArray alloc] init];
    NSArray *onlineLayersInEvent = [onlineLayersPerEvent objectForKey:[[Server currentEventId] stringValue]];
    for (NSNumber *onlineLayerId in onlineLayersInEvent) {
        ImageryLayer *onlineLayer = [ImageryLayer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"remoteId == %@ AND eventId == %@", onlineLayerId, [Server currentEventId]]];
        MKTileOverlay *overlay = nil;
        if ([[onlineLayer format] isEqualToString:@"WMS"]) {
            NSDictionary *wms = [onlineLayer options];
            NSLog(@"Adding the WMS layer %@ to the map", onlineLayer.name);
            overlay = [[WMSTileOverlay alloc] initWithURL: [onlineLayer url] andParameters: wms];
        } else if ([[onlineLayer format] isEqualToString:@"XYZ"]) {
            NSLog(@"Adding the online layer %@ to the map %@", onlineLayer.name, onlineLayer.url);
            overlay = [[XYZTileOverlay alloc] initWithURLTemplate:onlineLayer.url];
        } else if ([[onlineLayer format] isEqualToString:@"TMS"]) {
            NSLog(@"Adding the TMS layer %@ to the map %@", onlineLayer.name, onlineLayer.url);
            overlay = [[TMSTileOverlay alloc] initWithURLTemplate:onlineLayer.url];
        }
        if (![self.onlineLayers objectForKey:onlineLayerId]) {
            [self.onlineLayers setObject:overlay forKey:onlineLayerId];

            if ([[onlineLayer options] objectForKey:@"base"] && [[[onlineLayer options] objectForKey:@"base"] intValue] == 1) {
                [baseLayers addObject:overlay];
            } else if ([[onlineLayer options] objectForKey:@"transparent"] && [[[onlineLayer options] objectForKey:@"transparent"] intValue] == 1) {
                [transparentLayers addObject:overlay];
            } else {
                [nonBaseLayers addObject:overlay];
            }
        }

        [unselectedOnlineLayers removeObject:onlineLayerId];
    }
    // Add the layers in the proper order to the map
    for (MKTileOverlay *overlay in baseLayers) {
        [self.mapView addOverlay:overlay];
    }
    for (MKTileOverlay *overlay in nonBaseLayers) {
        [self.mapView addOverlay:overlay];
    }
    for (MKTileOverlay *overlay in transparentLayers) {
        [self.mapView addOverlay:overlay];
    }
        
    for (NSNumber *unselectedOnlineLayerId in unselectedOnlineLayers) {
        ImageryLayer *unselectedOnlineLayer = [ImageryLayer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"remoteId == %@ AND eventId == %@", unselectedOnlineLayerId, [Server currentEventId]]];

        NSLog(@"removing the layer %@ from the map", unselectedOnlineLayer.name);
        [self.mapView removeOverlay:[self.onlineLayers objectForKey:unselectedOnlineLayerId]];
        [self.onlineLayers removeObjectForKey:unselectedOnlineLayerId];
    }
}

- (void) updateStaticLayers: (NSDictionary *) staticLayersPerEvent {
    if (self.hideStaticLayers) return;
    NSMutableSet *unselectedStaticLayers = [[self.staticLayers allKeys] mutableCopy];
    
    NSArray *staticLayers = [staticLayersPerEvent objectForKey:[[Server currentEventId] stringValue]];
    
    for (NSNumber *staticLayerId in staticLayers) {
        StaticLayer *staticLayer = [StaticLayer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"remoteId == %@ AND eventId == %@", staticLayerId, [Server currentEventId]]];
        if (![unselectedStaticLayers containsObject:staticLayerId]) {
            NSLog(@"adding the static layer %@ to the map", staticLayer.name);
            NSMutableArray *annotations = [NSMutableArray array];
            for (NSDictionary *feature in [staticLayer.data objectForKey:@"features"]) {
                if ([[feature valueForKeyPath:@"geometry.type"] isEqualToString:@"Point"]) {
                    StaticPointAnnotation *annotation = [[StaticPointAnnotation alloc] initWithFeature:feature];
                    [_mapView addAnnotation:annotation];
                    [annotations addObject:annotation];
                } else if([[feature valueForKeyPath:@"geometry.type"] isEqualToString:@"Polygon"]) {
                    NSMutableArray *coordinates = [NSMutableArray arrayWithArray:[feature valueForKeyPath:@"geometry.coordinates"]];
                    StyledPolygon *polygon = [MapUtils generatePolygon:coordinates];
                    
                    CGFloat fillAlpha = 1.0f;
                    id fillOpacity = [feature valueForKeyPath:@"properties.style.polyStyle.color.opacity"];
                    if (fillOpacity) {
                        fillAlpha = [fillOpacity floatValue] / 255.0f;
                    }
                    [polygon fillColorWithHexString:[feature valueForKeyPath:@"properties.style.polyStyle.color.rgb"] andAlpha:fillAlpha];
                    
                    CGFloat lineAlpha = 1.0f;
                    id lineOpacity = [feature valueForKeyPath:@"properties.style.lineStyle.color.opacity"];
                    if (lineOpacity) {
                        lineAlpha = [lineOpacity floatValue] / 255.0f;
                    }
                    [polygon lineColorWithHexString:[feature valueForKeyPath:@"properties.style.lineStyle.color.rgb"] andAlpha:lineAlpha];
                    
                    id lineWidth = [feature valueForKeyPath:@"properties.style.lineStyle.width"];
                    if (!lineWidth) {
                        polygon.lineWidth = 1.0f;
                    } else {
                        polygon.lineWidth = [lineWidth floatValue];
                    }
                    
                    polygon.title = [NSString stringWithFormat:@"%@</br>%@",[feature valueForKeyPath:@"properties.name"], [feature valueForKeyPath:@"properties.description"]];

                    [annotations addObject:polygon];
                    [_mapView addOverlay:polygon];
                } else if([[feature valueForKeyPath:@"geometry.type"] isEqualToString:@"LineString"]) {
                    NSMutableArray *coordinates = [NSMutableArray arrayWithArray:[feature valueForKeyPath:@"geometry.coordinates"]];
                    StyledPolyline *polyline = [MapUtils generatePolyline:coordinates];
                    
                    CGFloat alpha = 1.0f;
                    id opacity = [feature valueForKeyPath:@"properties.style.lineStyle.color.opacity"];
                    if (opacity) {
                        alpha = [opacity floatValue] / 255.0f;
                    }

                    [polyline lineColorWithHexString:[feature valueForKeyPath:@"properties.style.lineStyle.color.rgb"] andAlpha:alpha];
                    
                    id lineWidth = [feature valueForKeyPath:@"properties.style.lineStyle.width"];
                    if (!lineWidth) {
                        polyline.lineWidth = 1.0f;
                    } else {
                        polyline.lineWidth = [lineWidth floatValue];
                    }
                    
                    polyline.title = [NSString stringWithFormat:@"%@</br>%@",[feature valueForKeyPath:@"properties.name"], [feature valueForKeyPath:@"properties.description"]];
                    [annotations addObject:polyline];
                    [_mapView addOverlay:polyline];
                }
            }
            [self.staticLayers setObject:annotations forKey:staticLayerId];
        }
        
        [unselectedStaticLayers removeObject:staticLayerId];
    }
    
    for (NSNumber *unselectedStaticLayerId in unselectedStaticLayers) {
        StaticLayer *unselectedStaticLayer = [StaticLayer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"remoteId == %@", unselectedStaticLayerId]];
        NSLog(@"removing the layer %@ from the map", unselectedStaticLayer.name);
        for (id staticItem in [self.staticLayers objectForKey:unselectedStaticLayerId]) {
            if ([staticItem conformsToProtocol:@protocol(MKOverlay)]) {
                [self.mapView removeOverlay:staticItem];
            } else if ([staticItem conformsToProtocol:@protocol(MKAnnotation)]) {
                [self.mapView removeAnnotation:staticItem];
            }
        }
        [self.staticLayers removeObjectForKey:unselectedStaticLayerId];
    }
}

- (void) setUserTrackingMode:(MKUserTrackingMode) mode animated:(BOOL) animated {
    if (!self.isTrackingAnimation || mode != MKUserTrackingModeFollowWithHeading) {
        [self.mapView setUserTrackingMode:mode animated:animated];
    }
}

- (void) mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated {
    if (self.userTrackingModeDelegate) {
        [self.userTrackingModeDelegate userTrackingModeChanged:mode];
    }
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    if (self.mapView.userTrackingMode == MKUserTrackingModeFollow) {
        self.isTrackingAnimation = YES;
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    self.isTrackingAnimation = NO;
}

- (MKAnnotationView *)mapView:(MKMapView *) mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[LocationAnnotation class]]) {
		LocationAnnotation *locationAnnotation = annotation;
        MKAnnotationView *annotationView = [locationAnnotation viewForAnnotationOnMapView:self.mapView];
        annotationView.layer.zPosition = [locationAnnotation.timestamp timeIntervalSinceReferenceDate];
        annotationView.canShowCallout = self.canShowUserCallout;
        annotationView.hidden = self.hideLocations;
        annotationView.accessibilityElementsHidden = self.hideLocations;
        annotationView.enabled = !self.hideLocations;
        return annotationView;
    } else if ([annotation isKindOfClass:[ObservationAnnotation class]]) {
        ObservationAnnotation *observationAnnotation = annotation;
        MKAnnotationView *annotationView = [observationAnnotation viewForAnnotationOnMapView:self.mapView];
        // adjiust the center offset if this is the enlargedPin
        if (annotationView == self.enlargedPin) {
            annotationView.centerOffset = CGPointMake(0, -(annotationView.image.size.height));
        }
        annotationView.canShowCallout = false;// self.canShowObservationCallout;
        annotationView.hidden = self.hideObservations;
        annotationView.accessibilityElementsHidden = self.hideObservations;
        annotationView.enabled = !self.hideObservations;
        annotationView.accessibilityLabel = [NSString stringWithFormat:@"Observation Annotation %@", observationAnnotation.observation.objectID.URIRepresentation];
        return annotationView;
    }
    else if ([annotation isKindOfClass:[StaticPointAnnotation class]]) {
        StaticPointAnnotation *staticAnnotation = annotation;
        return [staticAnnotation viewForAnnotationOnMapView:self.mapView];
    } else if ([annotation isKindOfClass:[AreaAnnotation class]]) {
        AreaAnnotation *areaAnnotation = annotation;
        return [areaAnnotation viewForAnnotationOnMapView:self.mapView];
    } else if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
        MKPointAnnotation *pointAnnotation = (MKPointAnnotation *)annotation;
        MKPinAnnotationView *pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pinAnnotation"];
        [pinView setPinTintColor:[UIColor redColor]];
        pinView.accessibilityLabel = [NSString stringWithFormat:@"Pin Annotation %f, %f", pointAnnotation.coordinate.latitude, pointAnnotation.coordinate.longitude];
        return pinView;
    } else if ([annotation isKindOfClass:[GPKGMapPoint class]]) {
        GPKGMapPoint *point = annotation;
        GPKGMapPointOptions *options = point.options;
        if(options.image != nil){
            MKAnnotationView *mapPointImageView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"pinImageAnnotation"];
            if (mapPointImageView == nil) {
                mapPointImageView = [[MapShapePointAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pinImageAnnotation" andMapView:mapView andDragCallback:nil];
            }
            mapPointImageView.image = options.image;
            mapPointImageView.centerOffset = options.imageCenterOffset;
            
            return mapPointImageView;
        }
    } else if ([annotation isKindOfClass:[FeedItem class]]) {
        FeedItem *item = (FeedItem *)annotation;
        MKAnnotationView *annotationView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"feedItem"];
        if (!annotationView) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"feedItem"];
            annotationView.canShowCallout = YES;
        }
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
        annotationView.rightCalloutAccessoryView = rightButton;
        [FeedItemRetriever setAnnotationImageWithFeedItem:item annotationView:annotationView];
        annotationView.annotation = annotation;
        annotationView.accessibilityLabel = [NSString stringWithFormat:@"Feed %@ Item %@", item.feed.remoteId, item.remoteId];
        return annotationView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *) mapView didSelectAnnotationView:(MKAnnotationView *) view {
    if ([view.annotation isKindOfClass:[LocationAnnotation class]]) {
        LocationAnnotation *annotation = view.annotation;
        User *user = annotation.user;
        
        if ([user avatarUrl] != nil) {
            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", documentsDirectory, user.avatarUrl]]];
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 45, 45)];
            view.leftCalloutAccessoryView = imageView;
            
            [imageView setImage:image];
        }
        
        double accuracy = annotation.location.horizontalAccuracy;
        self.selectedUserAccuracy = [LocationAccuracy locationAccuracyWithCenterCoordinate:annotation.location.coordinate radius:accuracy timestamp:annotation.timestamp];
        [self.mapView addOverlay:self.selectedUserAccuracy];
    } else if ([view.annotation isKindOfClass:[ObservationAnnotation class]]) {
        ObservationAnnotation *annotation = view.annotation;
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            view.transform = CGAffineTransformScale(view.transform, 2.0, 2.0);
            view.centerOffset = CGPointMake(0, -(view.image.size.height));
            self.enlargedPin = view;
        } completion:nil];

        Observation *observation = annotation.observation;
        
        [annotation setSubtitle:observation.timestamp.timeAgoSinceNow];
        
        id accuracyProperty = [observation.properties valueForKeyPath:@"accuracy"];
        if (accuracyProperty != nil) {
            double accuracy = [accuracyProperty doubleValue];
            self.selectedObservationAccuracy = [ObservationAccuracy circleWithCenterCoordinate:observation.location.coordinate radius:accuracy];
            [self.mapView addOverlay:self.selectedObservationAccuracy];
        }
        self.obsBottomSheet = [[ObservationBottomSheetController alloc] initWithObservation:observation actionsDelegate:self scheme:self.scheme];
        self.obsBottomSheet.preferredContentSize = CGSizeMake(self.obsBottomSheet.preferredContentSize.width, 220);
        
        self.bottomSheet = [[MDCBottomSheetController alloc] initWithContentViewController:self.obsBottomSheet];
        [self.bottomSheet.navigationController.navigationBar setTranslucent:true];
        self.bottomSheet.delegate = self;
        [self.navigationController presentViewController:self.bottomSheet animated:true completion:nil];
    } else if ([view.annotation isKindOfClass:[StaticPointAnnotation class]]) {
        StaticPointAnnotation *annotation = view.annotation;
        NSString *clickMessage = [annotation detailTextForAnnotation];
        [self.cacheOverlayDelegate onCacheOverlayTapped:clickMessage];
    } else {
        NSLog(@"Annotation is a %@", [view class]);
    }
}

- (void) startBearing {
//    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
//    [self.locationManager startUpdatingLocation];
//    self.locationManager.headingFilter = 0.5;
//    [self.locationManager startUpdatingHeading];
//    [self.straightLineNavigation startBearingWithManager:self.locationManager];
}

- (void) startStraightLineNavigation: (CLLocationCoordinate2D) destination image:(UIImage*) image {
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [self.locationManager startUpdatingLocation];
    self.locationManager.headingFilter = 0.5;
    [self.locationManager startUpdatingHeading];
    self.navigationDestinationCoordinate = destination;
    [self setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
    [self.straightLineNavigation stopNavigation];
    [self.straightLineNavigation startNavigationWithManager:self.locationManager destinationCoordinate:destination delegate:self image:image scheme:self.scheme];
}

- (void)mapView:(MKMapView *) mapView didDeselectAnnotationView:(MKAnnotationView *) view {
    if (self.selectedUserAccuracy != nil) {
        [_mapView removeOverlay:self.selectedUserAccuracy];
        self.selectedUserAccuracy = nil;
    }
    
    if (self.selectedObservationAccuracy != nil) {
        [_mapView removeOverlay:self.selectedObservationAccuracy];
        self.selectedObservationAccuracy = nil;
    }
    
    if (_areaAnnotation != nil && view.annotation == _areaAnnotation) {
        [self performSelector:@selector(reSelectAnnotationIfNoneSelected:)
                   withObject:view.annotation afterDelay:0];
    }
}

- (void)reSelectAnnotationIfNoneSelected:(id<MKAnnotation>)annotation {
    if (_mapView.selectedAnnotations == nil || _mapView.selectedAnnotations.count == 0)
        [_mapView selectAnnotation:annotation animated:NO];
}

- (void) mapView:(MKMapView *) mapView annotationView:(MKAnnotationView *) view calloutAccessoryControlTapped:(UIControl *) control {

	if ([view.annotation isKindOfClass:[LocationAnnotation class]] || view.annotation == mapView.userLocation) {
        if (self.mapCalloutDelegate) {
            LocationAnnotation *annotation = view.annotation;
            [self.mapCalloutDelegate calloutTapped:annotation.user];
        }
	} else if ([view.annotation isKindOfClass:[ObservationAnnotation class]]) {
        if (self.mapCalloutDelegate) {
            ObservationAnnotation *annotation = view.annotation;
            [self.mapCalloutDelegate calloutTapped:annotation.observation];
        }
    } else if ([view.annotation isKindOfClass:[FeedItem class]]) {
        if (self.mapCalloutDelegate) {
            [self.mapCalloutDelegate calloutTapped:view.annotation];
        }
    }
}

- (MKOverlayRenderer *) mapView:(MKMapView *) mapView rendererForOverlay:(id < MKOverlay >) overlay {
    if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        return [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    } else if ([overlay isKindOfClass:[ObservationAccuracy class]]) {
        return [[ObservationAccuracyRenderer alloc] initWithOverlay:overlay];
    } else if ([overlay isKindOfClass:[LocationAccuracy class]]) {
        return [[LocationAccuracyRenderer alloc] initWithOverlay:overlay];
    } else if ([overlay isKindOfClass:[MKPolygon class]]) {
        MKPolygon *polygon = (MKPolygon *) overlay;
        MKPolygonRenderer *renderer = [[MKPolygonRenderer alloc] initWithPolygon:polygon];
        if ([overlay isKindOfClass:[StyledPolygon class]]) {
            StyledPolygon *styledPolygon = (StyledPolygon *) polygon;
            renderer.fillColor = styledPolygon.fillColor;
            renderer.strokeColor = styledPolygon.lineColor;
            renderer.lineWidth = styledPolygon.lineWidth;
        } else {
            renderer.strokeColor = [UIColor blackColor];
            renderer.lineWidth = 1;
        }
        return renderer;
    } else if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolyline *polyline = (MKPolyline *) overlay;
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:polyline];
        if ([overlay isKindOfClass:[StyledPolyline class]]) {
            StyledPolyline *styledPolyline = (StyledPolyline *) polyline;
            renderer.strokeColor = styledPolyline.lineColor;
            renderer.lineWidth = styledPolyline.lineWidth;
        }else{
            renderer.strokeColor = [UIColor blackColor];
            renderer.lineWidth = 1;
        }
        return renderer;
    } else if ([overlay isKindOfClass:[NavigationOverlay class]]) {
        NavigationOverlay *nav = (NavigationOverlay *) overlay;
        return nav.renderer;
    }

    return nil;
}

- (NSMutableDictionary *) locationAnnotations {
    if (!_locationAnnotations) {
        _locationAnnotations = [[NSMutableDictionary alloc] init];
    }
    
    return _locationAnnotations;
}

- (MapObservations *) observationAnnotations {
    if (!_mapObservations) {
        _mapObservations = [[MapObservations alloc] initWithMapView:_mapView];
    }
    
    return _mapObservations;
}

#pragma mark - NSFetchResultsController

- (void) controller:(NSFetchedResultsController *) controller
    didChangeObject:(id) object
        atIndexPath:(NSIndexPath *) indexPath
      forChangeType:(NSFetchedResultsChangeType) type
       newIndexPath:(NSIndexPath *)newIndexPath {
    
    if ([object isKindOfClass:[Observation class]]) {
        switch(type) {
                
            case NSFetchedResultsChangeInsert:
                [self updateObservation:object withAnimation:YES];
                break;
                
            case NSFetchedResultsChangeDelete:
                [self deleteObservation:object];
                NSLog(@"Got delete for observation");
                break;
                
            case NSFetchedResultsChangeUpdate: {
                [self updateObservation:object withAnimation:NO];
                break;
            }
                
            case NSFetchedResultsChangeMove:
                [self updateObservation:object withAnimation:NO];
                break;
                
            default:
                break;
        }
        
    } else {
        switch(type) {
                
            case NSFetchedResultsChangeInsert:
                [self updateLocation:object];
                break;
                
            case NSFetchedResultsChangeDelete:
                NSLog(@"Got delete for location");
                break;
                
            case NSFetchedResultsChangeUpdate:
                [self updateLocation:object];
                break;
                
            case NSFetchedResultsChangeMove:
                [self updateLocation:object];
                break;
                
            default:
                break;
        }
    }
}

- (void) updateLocations:(NSArray *)locations {
    for (Location *location in locations) {
        [self updateLocation:location];
    }
}

- (void) updateObservations:(NSArray *)observations {
    __weak typeof(self) weakSelf = self;
    for (Observation *observation in observations) {
        if (!self.observations) return;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [weakSelf updateObservation: observation withAnimation:NO];
        });
    }
}

- (LocationAnnotation *) removeLocationForUser: (NSString *) remoteId {
    LocationAnnotation *annotation = [self.locationAnnotations objectForKey:remoteId];
    if (annotation != nil) {
        [_mapView removeAnnotation:annotation];
        [self.locationAnnotations removeObjectForKey:remoteId];
    }
    return annotation;
}

- (void) updateLocation:(Location *) location {
    User *user = location.user;
    
    LocationAnnotation *annotation = [self.locationAnnotations objectForKey:user.remoteId];
    if (annotation == nil) {
        annotation = [[LocationAnnotation alloc] initWithLocation:location];
        annotation.view.layer.zPosition = [location.timestamp timeIntervalSinceReferenceDate];
        [_mapView addAnnotation:annotation];
        [self.locationAnnotations setObject:annotation forKey:user.remoteId];
    } else {
        [annotation setSubtitle:location.timestamp.timeAgoSinceNow];
        MKAnnotationView *annotationView = [_mapView viewForAnnotation:annotation];
        annotationView.layer.zPosition = [location.timestamp timeIntervalSinceReferenceDate];
        [annotation setCoordinate:[location location].coordinate];
        [annotationView setImageForUser:annotation.user];
    }
}

- (void) updateGPSLocation:(GPSLocation *) location forUser:(User *) user {
    LocationAnnotation *annotation = [self.locationAnnotations objectForKey:user.remoteId];
    if (annotation == nil) {
        annotation = [[LocationAnnotation alloc] initWithGPSLocation:location user:user];
        [_mapView addAnnotation:annotation];
        [self.locationAnnotations setObject:annotation forKey:user.remoteId];
        SFGeometry * geometry = [location getGeometry];
        SFPoint *centroid = [SFGeometryUtils centroidOfGeometry:geometry];
        [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake([centroid.y doubleValue], [centroid.x doubleValue])];
    } else {
        MKAnnotationView *annotationView = [_mapView viewForAnnotation:annotation];
        SFGeometry * geometry = [location getGeometry];
        SFPoint *centroid = [SFGeometryUtils centroidOfGeometry:geometry];
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([centroid.y doubleValue], [centroid.x doubleValue]);
        [annotation setCoordinate:coordinate];
        [annotationView setImageForUser:user];
    }
}

- (void) updateObservation: (Observation *) observation withAnimation: (BOOL) animateDrop {
    [self.mapObservations removeById:observation.objectID];
    if ([observation getGeometry] != nil) {
        MapObservation *mapObservation = [self.mapObservationManager addToMapWithObservation:observation andAnimateDrop:animateDrop];
        [self.mapObservations addMapObservation:mapObservation];
    }
}

- (void) deleteObservation: (Observation *) observation {
    [self.mapObservations removeById:observation.objectID];
}

- (void)selectedUser:(User *) user {
    LocationAnnotation *annotation = [self.locationAnnotations objectForKey:user.remoteId];
    [self.mapView deselectAnnotation:annotation animated:NO];
    [self.mapView selectAnnotation:annotation animated:YES];
    
    [self.mapView setCenterCoordinate:annotation.location.coordinate];
}

- (void)selectedUser:(User *) user region:(MKCoordinateRegion) region {
    LocationAnnotation *annotation = [self.locationAnnotations objectForKey:user.remoteId];
    
    [self.mapView setRegion:region animated:YES];
    [self.mapView deselectAnnotation:annotation animated:NO];
    [self.mapView selectAnnotation:annotation animated:YES];
}

- (void)selectedObservation:(Observation *) observation {
    [self.mapView setCenterCoordinate:[observation location].coordinate];
    [self selectObservation:observation];
}

- (void)selectedObservation:(Observation *) observation region:(MKCoordinateRegion) region {
    [self.mapView setRegion:region animated:YES];
    [self selectObservation:observation];
}

- (void)selectObservation:(Observation *) observation{
    MapObservation *mapObservation = [self.mapObservations observationOfId:observation.objectID];
    if (mapObservation != nil) {
        if([MapObservations isAnnotation: mapObservation]){
            [self.mapView selectAnnotation:[((MapAnnotationObservation *)mapObservation) annotation] animated:YES];
        }else{
            MapAnnotation *shapeAnnotation = [self.mapObservationManager addShapeAnnotationAtLocation:[observation location].coordinate forObservation:observation andHidden:self.hideObservations];
            [self.mapObservations setShapeAnnotation:shapeAnnotation withShapeObservation:(MapShapeObservation *)mapObservation];
        }
    }
}

- (void)observationDetailSelected:(Observation *)observation {
    [self selectedObservation:observation];
}

- (void)userDetailSelected:(User *)user {
    [self selectedUser:user];
}

- (void) mapClickAtPoint: (CGPoint) point{
    
    CLLocationCoordinate2D location = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
    
    [self.mapObservations clearShapeAnnotation];
    
    MapShapeObservation *mapShapeObservation = [self.mapObservations clickedShapeAtLocation:location];
    if (mapShapeObservation != nil) {
        MapAnnotation *shapeAnnotation = [self.mapObservationManager addShapeAnnotationAtLocation:location forObservation:mapShapeObservation.observation andHidden:self.hideObservations];
        [self.mapObservations setShapeAnnotation:shapeAnnotation withShapeObservation:mapShapeObservation];
    }
    
    if (!self.hideStaticLayers) {
        [self mapTap:point];
    }
}

- (void)bottomSheetControllerDidDismissBottomSheet:(nonnull MDCBottomSheetController *)controller {
    [self resetEnlargedPin];
}

- (void) resetEnlargedPin {
    if (self.enlargedPin) {
        [self.mapView deselectAnnotation:self.enlargedPin.annotation animated:true];
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.enlargedPin.transform = CGAffineTransformScale(self.enlargedPin.transform, 0.5, 0.5);
            self.enlargedPin.centerOffset = CGPointMake(0, -(self.enlargedPin.image.size.height / 2.0));
            self.enlargedPin = nil;
        } completion:nil];
    }
}

- (void) cancelStraightLineNavigation {
    [self.straightLineNavigation stopNavigation];
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopUpdatingHeading];
}

@end
