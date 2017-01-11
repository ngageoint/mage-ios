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

@interface ObservationTableViewCell()

@property (strong, nonatomic) NSIndexPath *indexPath;
@property (strong, nonatomic) AttachmentCollectionDataStore *ads;
@property (strong, nonatomic) User *currentUser;
@property (strong, nonatomic) UIColor *favoriteDefaultColor;
@property (strong, nonatomic) UIColor *favoriteHighlightColor;

@end

@implementation ObservationTableViewCell

-(id)initWithCoder:(NSCoder *) aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        self.currentUser = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
        self.favoriteDefaultColor = [UIColor colorWithWhite:0.0 alpha:.54];
        self.favoriteHighlightColor = [UIColor colorWithRed:126/255.0 green:211/255.0 blue:33/255.0 alpha:1.0];
    }
    
    return self;
}

- (void) populateCellWithObservation:(Observation *) observation {
    Event *event = [Event MR_findFirstByAttribute:@"remoteId" withValue:[Server currentEventId]];
    NSDictionary *form = event.form;
    NSString *variantField = [form objectForKey:@"variantField"];
    NSString *type = [observation.properties objectForKey:@"type"];
    self.primaryField.text = type;
    NSString *variantText = [observation.properties objectForKey:variantField];
    if (variantField != nil && variantText != nil && [variantText isKindOfClass:[NSString class]] && [variantText length] > 0) {
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
    self.ads.observation = observation;
    self.ads.attachmentSelectionDelegate = self.attachmentSelectionDelegate;
    
    if ([observation.attachments count]) {
        self.attachmentCollection.hidden = NO;
    } else {
        self.attachmentCollection.hidden = YES;
    }
    
    self.importantIcon.hidden = ![observation isImportant];
    
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
        self.favoriteNumber.text = [favorites count] <= 99 ? [@([favoritesMap count]) stringValue] : @"99+";
    } else {
        self.favoriteNumber.hidden = YES;
    }
}

- (IBAction)onFavoriteTapped:(id)sender {
    if (self.observationActionsDelegate) {
        [self.observationActionsDelegate observationFavoriteTapped:self];
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
