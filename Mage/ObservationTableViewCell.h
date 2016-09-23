//
//  ObservationTableViewCell.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import <Observation.h>
#import "AttachmentSelectionDelegate.h"

@class ObservationTableViewCell;

@protocol ObservationActionsDelegate <NSObject>

@required
- (void) observationFavoriteTapped:(ObservationTableViewCell *) tableViewCell;
- (void) observationShareTapped:(ObservationTableViewCell *) tableViewCell;

@end

@class ObservationFavoriteDelegate;

@interface ObservationTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *primaryField;
@property (weak, nonatomic) IBOutlet UILabel *variantField;
@property (weak, nonatomic) IBOutlet UILabel *timeField;
@property (weak, nonatomic) IBOutlet UILabel *userField;
@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;
@property (weak, nonatomic) IBOutlet UILabel *favoriteNumber;
@property (weak, nonatomic) IBOutlet UIImageView *importantIcon;
@property (weak, nonatomic) IBOutlet NSObject<ObservationActionsDelegate> *observationActionsDelegate;
@property (weak, nonatomic) IBOutlet NSObject<AttachmentSelectionDelegate> *attachmentSelectionDelegate;
@property (weak, nonatomic) IBOutlet UICollectionView *attachmentCollection;

- (void) populateCellWithObservation:(Observation *) observation;

@end
