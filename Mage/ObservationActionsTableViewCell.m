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
@end

@implementation ObservationActionsTableViewCell

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor dialog];
    self.directionsButton.tintColor = [UIColor inactiveIcon];
    [self configureFavoriteColors];
}

- (IBAction)directionsButtonTapped:(id)sender {
    [self.observationActionsDelegate observationDirectionsTapped:sender];
}

- (IBAction)favoriteButtonTapped:(id)sender {
    [self.observationActionsDelegate observationFavoriteTapped:sender];
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
