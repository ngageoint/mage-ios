//
//  ObservationActionsTableViewCell.m
//  MAGE
//
//  Created by William Newman on 9/26/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationActionsTableViewCell.h"
#import "User.h"
#import "ObservationFavorite.h"

@interface ObservationActionsTableViewCell()
@property (strong, nonatomic) UIColor *favoriteDefaultColor;
@property (strong, nonatomic) UIColor *favoriteHighlightColor;
@end

@implementation ObservationActionsTableViewCell

-(id)initWithCoder:(NSCoder *) aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        self.favoriteDefaultColor = [UIColor colorWithWhite:0.0 alpha:.54];
        self.favoriteHighlightColor = [UIColor colorWithRed:126/255.0 green:211/255.0 blue:33/255.0 alpha:1.0];
    }
    
    return self;
}

- (void) configureCellForObservation: (Observation *) observation {
    User *currentUser = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];

    NSDictionary *favoritesMap = [observation getFavoritesMap];
    ObservationFavorite *favorite = [favoritesMap objectForKey:currentUser.remoteId];
    if (favorite && favorite.favorite) {
        self.favoriteButton.imageView.tintColor = self.favoriteHighlightColor;
    } else {
        self.favoriteButton.imageView.tintColor = self.favoriteDefaultColor;
    }
}


@end
