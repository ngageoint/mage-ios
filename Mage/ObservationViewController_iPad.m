//
//  ObservationViewerViewController.m
//  Mage
//
//

#import "ObservationViewController_iPad.h"
#import "Observation.h"
#import "ObservationImportant.h"
#import "ObservationFavorite.h"
#import "ObservationAnnotation.h"
#import "ObservationImage.h"
#import "ObservationHeaderTableViewCell.h"
#import "ObservationPropertyTableViewCell.h"
#import "User.h"
#import "Role.h"
#import "ObservationEditViewController.h"
#import "Server.h"
#import "MapDelegate.h"
#import "ObservationDataStore.h"
#import "Event.h"
#import "NSDate+display.h"
#import "ObservationFields.h"
#import "MAGE-Swift.h"

@interface ObservationViewController_iPad ()<NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet MapDelegate *mapDelegate;
@property (weak, nonatomic) IBOutlet UILabel *primaryFieldLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondaryFieldLabel;
@property (weak, nonatomic) IBOutlet UIStackView *favoritesView;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;
@property (weak, nonatomic) IBOutlet UIButton *favoritesButton;

@property (strong, nonatomic) UIColor *favoriteDefaultColor;
@property (strong, nonatomic) UIColor *favoriteHighlightColor;
@end

@implementation ObservationViewController_iPad

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO];
    
    self.favoriteDefaultColor = [UIColor colorWithWhite:0.0 alpha:.54];
    self.favoriteHighlightColor = [UIColor colorWithRed:126/255.0 green:211/255.0 blue:33/255.0 alpha:1.0];
    
}

- (void) registerCellTypes {
    [super registerCellTypes];
    [self.propertyTable registerNib:[UINib nibWithNibName:@"ObservationViewIPadHeaderCell" bundle:nil] forCellReuseIdentifier:@"header"];
}

- (NSMutableArray *) getHeaderSection {
   return [[NSMutableArray alloc] initWithObjects:@"header", @"location", @"actions", nil];
}

@end
