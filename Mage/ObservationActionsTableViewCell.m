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

- (IBAction)directionsButtonTapped:(id)sender {
    [self.observationActionsDelegate observationDirectionsTapped:sender];
    /*
    WKBGeometry *geometry = [self.observation getGeometry];
    WKBPoint *point = [GeometryUtility centroidOfGeometry:geometry];
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([point.y doubleValue], [point.x doubleValue]);
    
     NSURL *mapsUrl = [NSURL URLWithString:@"comgooglemaps-x-callback://"];
     if ([[UIApplication sharedApplication] canOpenURL:mapsUrl]) {
     NSString *directionsRequest = [NSString stringWithFormat:@"%@://?daddr=%f,%f&x-success=%@&x-source=%s",
     @"comgooglemaps-x-callback",
     coordinate.latitude,
     coordinate.longitude,
     @"mage://?resume=true",
     "MAGE"];
     NSURL *directionsURL = [NSURL URLWithString:directionsRequest];
     [[UIApplication sharedApplication] openURL:directionsURL];
     } else {
     
     NSLog(@"Can't use comgooglemaps-x-callback:// on this device.");
     MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
     MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
     [mapItem setName:self.navigationItem.title];
     
     MKMapItem *currentLocation = [MKMapItem mapItemForCurrentLocation];
     NSDictionary *options = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
     [MKMapItem openMapsWithItems:@[currentLocation, mapItem] launchOptions:options];
     }
     */
    
    /*
    NSURL *mapsUrl = [NSURL URLWithString:@"http://maps.apple.com/?q=Mexican+Restaurant"];
    [[UIApplication sharedApplication] openURL:mapsUrl options:@{} completionHandler:^(BOOL success) {
        NSLog(@"opened? %d", success);
    }];
     */
    
    //[self sendMessage];
}

- (IBAction)favoriteButtonTapped:(id)sender {
    [self.observationActionsDelegate observationFavoriteTapped:sender];
}

- (void) configureCellForObservation: (Observation *) observation withForms:(NSArray *)forms {
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
