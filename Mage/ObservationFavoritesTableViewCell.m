//
//  ObservationFavoritesTableViewCell.m
//  MAGE
//
//  Created by William Newman on 9/26/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationFavoritesTableViewCell.h"
#import "Theme+UIResponder.h"

@implementation ObservationFavoritesTableViewCell

- (void) didMoveToSuperview {
    [self registerForThemeChanges];
}

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor dialog];
    self.favoriteTextLabel.textColor = [UIColor primaryText];
    self.favoriteCountLabel.textColor = [UIColor primaryText];
}

- (void) configureCellForObservation: (Observation *) observation withForms:(NSArray *)forms {
    NSSet *favorites = [observation.favorites filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.favorite = %@", [NSNumber numberWithBool:YES]]];
    self.favoriteCountLabel.text = [@([favorites count]) stringValue];
    if ([favorites count] > 1) {
        self.favoriteTextLabel.text = @"FAVORITES";
    } else {
        self.favoriteTextLabel.text = @"FAVORITE";
    }
}

@end
