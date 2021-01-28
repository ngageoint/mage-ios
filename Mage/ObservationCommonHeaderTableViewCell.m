//
//  ObservationCommonHeaderTableViewCell.m
//  MAGE
//
//

#import "ObservationCommonHeaderTableViewCell.h"
#import "Server.h"
#import "User.h"
#import "Event.h"
#import "NSDate+display.h"
#import "MapDelegate.h"
#import "AttachmentCollectionDataStore.h"
#import "MAGE-Swift.h"
#import <mgrs/MGRS.h>

@interface ObservationCommonHeaderTableViewCell ()
@property (strong, nonatomic) MapDelegate *mapDelegate;
@property (weak, nonatomic) IBOutlet NSObject<AttachmentSelectionDelegate> *attachmentSelectionDelegate;
@property (strong, nonatomic) AttachmentCollectionDataStore *ads;
@property (weak, nonatomic) IBOutlet UICollectionView *attachmentCollection;
@end

@implementation ObservationCommonHeaderTableViewCell

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor dialog];
    self.primaryFieldLabel.textColor = [UIColor brand];
    self.variantFieldLabel.textColor = [UIColor brand];
    self.userLabel.textColor = [UIColor secondaryText];
    self.dateLabel.textColor = [UIColor secondaryText];
    self.locationLabel.textColor = [UIColor secondaryText];
    [UIColor themeMap:self.mapView];
}

- (void) configureCellForObservation: (Observation *) observation withForms:(NSArray *)forms {
    
    NSString *primaryFieldText = [observation primaryFeedFieldText];
    
    if (primaryFieldText != nil && [primaryFieldText length] > 0) {
        self.primaryFieldLabel.text = primaryFieldText;
        self.primaryFieldLabel.hidden = NO;
    } else {
        self.primaryFieldLabel.hidden = YES;
    }
    
    NSString *variantText = [observation secondaryFeedFieldText];
    if (variantText != nil && [variantText length] > 0) {
        self.variantFieldLabel.hidden = NO;
        self.variantFieldLabel.text = variantText;
    } else {
        self.variantFieldLabel.hidden = YES;
    }
    
    self.userLabel.text = observation.user.name;
    self.dateLabel.text = [observation.timestamp formattedDisplayDate];
    
    [self setupMapForObservation:observation];
    [self setupAttachmentsForObservation:observation];
    
    [self registerForThemeChanges];
}
         
- (void) setupMapForObservation:(Observation *) observation {
    if (!self.mapView) {
        return;
    }
    
    self.mapDelegate = [[MapDelegate alloc] init];
    [self.mapDelegate setMapView: self.mapView];
    self.mapView.delegate = self.mapDelegate;
    [self.mapDelegate setupListeners];
    
    Observations *observations = [Observations observationsForObservation:observation];
    self.mapDelegate.hideStaticLayers = YES;
    
    __weak __typeof__(self) weakSelf = self;
    [self.mapDelegate setObservations:observations withCompletion:^{
        MapObservation *mapObservation = [weakSelf.mapDelegate.mapObservations observationOfId:observation.objectID];
        MKCoordinateRegion viewRegion = [mapObservation viewRegionOfMapView:weakSelf.mapView];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.mapDelegate selectedObservation:observation region:viewRegion];
        });
    }];

 }

- (void) setupAttachmentsForObservation:(Observation *) observation {
    if (!self.attachmentCollection) {
        return;
    }
    
    [self.attachmentCollection registerClass:[AttachmentCell class] forCellWithReuseIdentifier:@"AttachmentCell"];

    self.ads = [[AttachmentCollectionDataStore alloc] init];
    self.ads.attachmentCollection = self.attachmentCollection;
    self.attachmentCollection.delegate = self.ads;
    self.attachmentCollection.dataSource = self.ads;
    self.ads.attachments = [observation.attachments setByAddingObjectsFromArray: observation.transientAttachments];
}

- (void) setAttachmentSelectionDelegate:(NSObject<AttachmentSelectionDelegate> *)attachmentSelectionDelegate {
    _attachmentSelectionDelegate = attachmentSelectionDelegate;
    self.ads.attachmentSelectionDelegate = self.attachmentSelectionDelegate;
}

@end
