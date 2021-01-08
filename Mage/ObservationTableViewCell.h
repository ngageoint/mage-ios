//
//  ObservationTableViewCell.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "Observation.h"
#import "AttachmentSelectionDelegate.h"
#import "ObservationActionsDelegate_legacy.h"
#import <MaterialComponents/MaterialContainerScheme.h>

@class ObservationTableViewCell;

@class ObservationFavoriteDelegate;

@interface ObservationTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *primaryField;
@property (weak, nonatomic) IBOutlet UILabel *variantField;
@property (weak, nonatomic) IBOutlet UILabel *timeField;
@property (weak, nonatomic) IBOutlet UILabel *userField;
@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;
@property (weak, nonatomic) IBOutlet UILabel *favoriteNumber;
@property (weak, nonatomic) IBOutlet UIImageView *importantBadge;
@property (weak, nonatomic) IBOutlet NSObject<ObservationActionsDelegate_legacy> *observationActionsDelegate;
@property (weak, nonatomic) IBOutlet NSObject<AttachmentSelectionDelegate> *attachmentSelectionDelegate;
@property (weak, nonatomic) IBOutlet UICollectionView *attachmentCollection;
@property (weak, nonatomic) IBOutlet UIImageView *observationShapeImage;
@property (strong, nonatomic) Observation *observation;


- (void) populateCellWithObservation:(Observation *) observation;
- (void) displayFavoriteForObservation: (Observation *) observation;
- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>) containerScheme;

@end
