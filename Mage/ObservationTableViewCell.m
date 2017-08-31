//
//  ObservationTableViewCell.m
//  Mage
//
//

#import "ObservationTableViewCell.h"
#import "ObservationImage.h"
#import "ObservationFavorite.h"
#import <NSDate+DateTools.h>
#import "User.h"
#import "Server.h"
#import "AttachmentCollectionDataStore.h"
#import "Event.h"
#import "NSDate+iso8601.h"
#import "Attachment+Thumbnail.h"
#import <MageEnums.h>

@interface ObservationTableViewCell()

@property (strong, nonatomic) NSIndexPath *indexPath;
@property (strong, nonatomic) AttachmentCollectionDataStore *ads;
@property (strong, nonatomic) User *currentUser;
@property (strong, nonatomic) UIColor *favoriteDefaultColor;
@property (strong, nonatomic) UIColor *favoriteHighlightColor;
@property (weak, nonatomic) IBOutlet UIImageView *syncBadge;
@property (weak, nonatomic) IBOutlet UIImageView *errorBadge;
@property (weak, nonatomic) IBOutlet UIView *dotView;

@end

@implementation ObservationTableViewCell

-(id)initWithCoder:(NSCoder *) aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        self.currentUser = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
        self.favoriteDefaultColor = [UIColor colorWithWhite:0.0 alpha:.38];
        self.favoriteHighlightColor = [UIColor colorWithRed:126/255.0 green:211/255.0 blue:33/255.0 alpha:1.0];
    }
    
    return self;
}

- (void) populateCellWithObservation:(Observation *) observation {
    NSString *primaryText = [observation primaryFieldText];
    NSString *variantText = [observation secondaryFieldText];
    
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
    
    self.icon.image = [ObservationImage imageForObservation:observation];
    
    self.timeField.text = observation.timestamp.shortTimeAgoSinceNow;
    
    self.userField.text = observation.user.name;
    
    self.ads = [[AttachmentCollectionDataStore alloc] init];
    self.ads.attachmentFormatName = AttachmentSmallSquare;
    self.ads.attachmentCollection = self.attachmentCollection;
    self.attachmentCollection.delegate = self.ads;
    self.attachmentCollection.dataSource = self.ads;
    [self.attachmentCollection registerNib:[UINib nibWithNibName:@"AttachmentCell" bundle:nil] forCellWithReuseIdentifier:@"AttachmentCell"];
    self.ads.observation = observation;
    self.ads.attachmentSelectionDelegate = self.attachmentSelectionDelegate;
    
    if ([observation.attachments count]) {
        self.attachmentCollection.hidden = NO;
    } else {
        self.attachmentCollection.hidden = YES;
    }
    
    self.importantBadge.hidden = ![observation isImportant];
    
    NSDictionary *favoritesMap = [observation getFavoritesMap];
    ObservationFavorite *favorite = [favoritesMap objectForKey:self.currentUser.remoteId];
    if (favorite && favorite.favorite) {
        self.favoriteButton.imageView.tintColor = self.favoriteHighlightColor;
        self.favoriteNumber.textColor = self.favoriteHighlightColor;
    } else {
        self.favoriteButton.imageView.tintColor = self.favoriteDefaultColor;
        self.favoriteNumber.textColor = self.favoriteDefaultColor;
    }
    
    NSSet *favorites = [observation.favorites filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.favorite = %@", [NSNumber numberWithBool:YES]]];
    if ([favorites count]) {
        self.favoriteNumber.hidden = NO;
        self.favoriteNumber.text = [favorites count] <= 99 ? [@([favorites count]) stringValue] : @"99+";
    } else {
        self.favoriteNumber.hidden = YES;
    }
    
    if (observation.error != nil) {
        BOOL hasValidationError = [observation hasValidationError];
        self.syncBadge.hidden = hasValidationError;
        self.errorBadge.hidden = !hasValidationError;
    } else {
        self.syncBadge.hidden = YES;
        self.errorBadge.hidden = YES;
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
