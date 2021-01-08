//
//  ObservationTableViewCell.m
//  Mage
//
//

@import DateTools;
@import HexColors;

#import "ObservationTableViewCell.h"
#import "ObservationImage.h"
#import "ObservationFavorite.h"
#import "User.h"
#import "Server.h"
#import "AttachmentCollectionDataStore.h"
#import "Event.h"
#import "MageEnums.h"
#import "ObservationShapeStyleParser.h"
#import "Theme+UIResponder.h"
#import "MAGE-Swift.h"

@interface ObservationTableViewCell()

@property (strong, nonatomic) NSIndexPath *indexPath;
@property (strong, nonatomic) AttachmentCollectionDataStore *ads;
@property (strong, nonatomic) User *currentUser;
@property (strong, nonatomic) UIColor *favoriteDefaultColor;
@property (strong, nonatomic) UIColor *favoriteHighlightColor;
@property (weak, nonatomic) IBOutlet UIImageView *syncBadge;
@property (weak, nonatomic) IBOutlet UIImageView *errorBadge;
@property (weak, nonatomic) IBOutlet UIView *dotView;
@property (weak, nonatomic) IBOutlet UIButton *directionsButton;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;

@end

@implementation ObservationTableViewCell

-(id)initWithCoder:(NSCoder *) aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.currentUser = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
    }
    
    return self;
}

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>) containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
    self.primaryField.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];// [UIColor primaryText];
    self.backgroundColor = self.scheme.colorScheme.surfaceColor;// [UIColor background];
    self.variantField.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];// [UIColor primaryText];
    self.timeField.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.userField.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.favoriteDefaultColor = [UIColor colorWithWhite:0.0 alpha:1];
    self.favoriteHighlightColor = [UIColor colorWithHexString:@"00C853" alpha:1.0];
    self.directionsButton.tintColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    if (self.observation) {
        [self displayFavoriteForObservation:self.observation];
    }
    self.importantBadge.layer.borderColor = [self.scheme.colorScheme.surfaceColor CGColor];
    self.importantBadge.layer.borderWidth = 2.5;
    self.importantBadge.layer.cornerRadius = self.importantBadge.frame.size.width / 2.0f;
    
    self.syncBadge.layer.borderColor = [self.scheme.colorScheme.surfaceColor CGColor];
    self.syncBadge.layer.borderWidth = 2.5;
    self.syncBadge.layer.cornerRadius = self.syncBadge.frame.size.width / 2.0f;
    
    self.errorBadge.layer.borderColor = [self.scheme.colorScheme.surfaceColor CGColor];
    self.errorBadge.layer.borderWidth = 2.5;
    self.errorBadge.layer.cornerRadius = self.errorBadge.frame.size.width / 2.0f;
}

//- (void) themeDidChange:(MageTheme)theme {
//    self.primaryField.textColor = [UIColor primaryText];
//    self.backgroundColor = [UIColor background];
//    self.variantField.textColor = [UIColor primaryText];
//    self.timeField.textColor = [UIColor secondaryText];
//    self.userField.textColor = [UIColor secondaryText];
//    self.favoriteDefaultColor = [UIColor colorWithWhite:0.0 alpha:1];
//    self.favoriteHighlightColor = [UIColor colorWithHexString:@"00C853" alpha:1.0];
//    self.directionsButton.tintColor = [UIColor inactiveIcon];
//    if (self.observation) {
//        [self displayFavoriteForObservation:self.observation];
//    }
//    self.importantBadge.layer.borderColor = [[UIColor background] CGColor];
//    self.importantBadge.layer.borderWidth = 2.5;
//    self.importantBadge.layer.cornerRadius = self.importantBadge.frame.size.width / 2.0f;
//
//    self.syncBadge.layer.borderColor = [[UIColor background] CGColor];
//    self.syncBadge.layer.borderWidth = 2.5;
//    self.syncBadge.layer.cornerRadius = self.syncBadge.frame.size.width / 2.0f;
//
//    self.errorBadge.layer.borderColor = [[UIColor background] CGColor];
//    self.errorBadge.layer.borderWidth = 2.5;
//    self.errorBadge.layer.cornerRadius = self.errorBadge.frame.size.width / 2.0f;
//}

- (void) populateCellWithObservation:(Observation *) observation {
    // TODO if we are reusing this cell, we should probably cancel all of the image cache requests
    self.observation = observation;
    NSString *primaryText = [observation primaryFeedFieldText];
    NSString *variantText = [observation secondaryFeedFieldText];
    
    if (primaryText != nil && [primaryText isKindOfClass:[NSString class]] && [primaryText length] > 0) {
        self.primaryField.text = primaryText;
        self.primaryField.hidden = self.dotView.hidden = NO;
    } else {
        self.primaryField.hidden = self.dotView.hidden = YES;
    }
    
    if (variantText != nil && [variantText isKindOfClass:[NSString class]] && [variantText length] > 0) {
        self.variantField.hidden = NO;
        self.variantField.text = variantText;
    } else {
        self.variantField.hidden = YES;
    }
    
    if ([observation getGeometry].geometryType == SF_POINT) {
        [self.observationShapeImage setImage:[UIImage imageNamed:@"marker"]];
        [self.observationShapeImage setContentMode:UIViewContentModeScaleAspectFit];
        self.observationShapeImage.tintColor = [UIColor grayColor];
    } else {
        if ([observation getGeometry].geometryType == SF_LINESTRING) {
            [self.observationShapeImage setImage:[UIImage imageNamed:@"line_string"]];
            [self.observationShapeImage setContentMode:UIViewContentModeScaleAspectFill];
        } else if ([observation getGeometry].geometryType == SF_POLYGON) {
            [self.observationShapeImage setImage:[UIImage imageNamed:@"polygon"]];
            [self.observationShapeImage setContentMode:UIViewContentModeScaleAspectFill];
        }
        ObservationShapeStyle *style = [ObservationShapeStyleParser styleOfObservation:observation];
        if (style.strokeColor != nil) {
            self.observationShapeImage.tintColor = style.strokeColor;
        } else {
            self.observationShapeImage.tintColor = style.fillColor;
        }
    }
    
    self.icon.image = [ObservationImage imageForObservation:observation];
    self.timeField.text = observation.timestamp.shortTimeAgoSinceNow;
    self.userField.text = observation.user.name;
    
    self.ads = [[AttachmentCollectionDataStore alloc] init];
    self.ads.attachmentCollection = self.attachmentCollection;
    self.attachmentCollection.delegate = self.ads;
    self.attachmentCollection.dataSource = self.ads;
    [self.attachmentCollection registerClass:[AttachmentCell class] forCellWithReuseIdentifier:@"AttachmentCell"];
    self.ads.attachments = [observation.attachments setByAddingObjectsFromArray: observation.transientAttachments];
    self.ads.attachmentSelectionDelegate = self.attachmentSelectionDelegate;
    
    if ([observation.attachments count]) {
        self.attachmentCollection.hidden = NO;
    } else {
        self.attachmentCollection.hidden = YES;
    }
    
    self.importantBadge.hidden = ![observation isImportant];
    
    [self displayFavoriteForObservation:observation];
    
    if (observation.error != nil) {
        BOOL hasValidationError = [observation hasValidationError];
        self.syncBadge.hidden = hasValidationError;
        self.errorBadge.hidden = !hasValidationError;
    } else {
        self.syncBadge.hidden = YES;
        self.errorBadge.hidden = YES;
    }
}

- (void) didMoveToSuperview {
//    [self registerForThemeChanges];
}

- (void) displayFavoriteForObservation: (Observation *) observation {
    NSDictionary *favoritesMap = [observation getFavoritesMap];
    ObservationFavorite *favorite = [favoritesMap objectForKey:self.currentUser.remoteId];
    if (favorite && favorite.favorite) {
        self.favoriteButton.imageView.tintColor = MDCPalette.greenPalette.accent700;// self.favoriteHighlightColor;
        self.favoriteNumber.textColor = MDCPalette.greenPalette.accent700;
    } else {
        self.favoriteButton.imageView.tintColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
        self.favoriteNumber.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    }
    NSSet *favorites = [observation.favorites filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.favorite = %@", [NSNumber numberWithBool:YES]]];
    if ([favorites count]) {
        self.favoriteNumber.hidden = NO;
        self.favoriteNumber.text = [favorites count] <= 99 ? [@([favorites count]) stringValue] : @"99+";
    } else {
        self.favoriteNumber.hidden = YES;
    }
}

- (IBAction)onFavoriteTapped:(id)sender {
    if (self.observationActionsDelegate) {
        [self.observationActionsDelegate observationFavoriteTapped:self];
    }
}

- (IBAction)onMapTapped:(id)sender {
    if ([self.observationActionsDelegate respondsToSelector:@selector(observationMapTapped:)]) {
        [self.observationActionsDelegate observationMapTapped:self];
    }
}

- (IBAction)onShareTapped:(id)sender {
    if (self.observationActionsDelegate) {
        [self.observationActionsDelegate observationShareTapped:self];
    }
}

- (IBAction)onDirectionsTapped:(id)sender {
    if (self.observationActionsDelegate) {
        [self.observationActionsDelegate observationDirectionsTapped:self];
    }
}

@end
