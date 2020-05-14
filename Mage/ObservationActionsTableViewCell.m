//
//  ObservationActionsTableViewCell.m
//  MAGE
//
//  Created by William Newman on 9/26/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

@import HexColors;

#import "ObservationActionsTableViewCell.h"
#import "User.h"
#import "ObservationFavorite.h"
#import "Theme+UIResponder.h"

@interface ObservationActionsTableViewCell()
@property (nonatomic) BOOL isFavorite;
@property (weak, nonatomic) IBOutlet UIButton *directionsButton;
@property (weak, nonatomic) IBOutlet UIButton *favoritesCount;
@end

@implementation ObservationActionsTableViewCell

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor dialog];
    self.favoritesCount.tintColor = [UIColor primaryText];
    self.directionsButton.tintColor = [UIColor inactiveIcon];
    
    [self configureFavoriteColors];
}

- (IBAction)directionsButtonTapped:(id)sender {
    [self.observationActionsDelegate observationDirectionsTapped:sender];
}

- (IBAction)favoriteButtonTapped:(id)sender {
    [self.observationActionsDelegate observationFavoriteTapped:sender];
}

- (IBAction)favoriteCountTapped:(id)sender {
    [self.observationActionsDelegate observationFavoriteInfoTapped:sender];
}

- (void) configureCellForObservation: (Observation *) observation withForms:(NSArray *)forms {
    User *currentUser = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];

    NSDictionary *favoritesMap = [observation getFavoritesMap];
    ObservationFavorite *favorite = [favoritesMap objectForKey:currentUser.remoteId];
    if (favorite && favorite.favorite) {
        self.isFavorite = YES;
    } else {
        self.isFavorite = NO;
    }
    
    NSSet *favorites = [observation.favorites filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.favorite = %@", [NSNumber numberWithBool:YES]]];
    
    if ([favorites count] > 0){
        self.favoritesCount.hidden = NO;
        
        UIFont *favoriteCount = [UIFont systemFontOfSize:15.0f];
        UIFont *favoriteLabel = [UIFont systemFontOfSize:13.0f];
        NSDictionary *countAttributes = @{NSFontAttributeName:favoriteCount, NSForegroundColorAttributeName:[UIColor primaryText]};
        NSDictionary *labelAttributes = @{NSFontAttributeName:favoriteLabel, NSForegroundColorAttributeName:[UIColor secondaryText]};
        NSMutableAttributedString *favoritesText = [[NSMutableAttributedString alloc] init];
        [favoritesText appendAttributedString:[[NSAttributedString alloc] initWithString:[@([favorites count]) stringValue] attributes:countAttributes]];
        [favoritesText appendAttributedString:[[NSAttributedString alloc] initWithString:([favorites count] > 1 ? @" FAVORIES" : @" FAVORITE") attributes:labelAttributes]];
        [self.favoritesCount setAttributedTitle:favoritesText forState:UIControlStateNormal];
    } else {
        self.favoritesCount.hidden = YES;
    }
    
    [self registerForThemeChanges];
}

- (void) configureFavoriteColors {
    if (self.isFavorite) {
        self.favoriteButton.imageView.tintColor = [UIColor colorWithHexString:@"00C853" alpha:1.0];
    } else {
        self.favoriteButton.imageView.tintColor = [UIColor inactiveIcon];
    }
}


@end
