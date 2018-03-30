//
//  ImportantTableViewCell.m
//  MAGE
//
//  Created by William Newman on 9/28/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationImportantTableViewCell.h"
#import "User.h"
#import "Role.h"
#import "ObservationImportant.h"
#import "NSDate+display.h"
#import "Theme+UIResponder.h"

@interface ObservationImportantTableViewCell()

@property (strong, nonatomic) User *currentUser;

@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIView *importantActions;
@property (weak, nonatomic) IBOutlet UIButton *updateButton;
@property (weak, nonatomic) IBOutlet UIButton *removeButton;

@end

@implementation ObservationImportantTableViewCell

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor dialog];
    self.userLabel.textColor = [UIColor primaryText];
    self.descriptionLabel.textColor = [UIColor primaryText];
    self.dateLabel.textColor = [UIColor secondaryText];
    [self.updateButton setTitleColor:[UIColor flatButton] forState:UIControlStateNormal];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.currentUser = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
}

- (void) configureCellForObservation: (Observation *) observation withForms:(NSArray *)forms {
    ObservationImportant *important = observation.observationImportant;
    
    User *user = [User MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"remoteId == %@", important.userId]];
    self.userLabel.hidden = user ? NO : YES;
    self.userLabel.text = [NSString stringWithFormat:@"%@ flagged as important", [user name]];

    self.dateLabel.text = [important.timestamp formattedDisplayDateWithDateStyle:NSDateFormatterLongStyle andTimeStyle:NSDateFormatterLongStyle];
    
    self.descriptionLabel.hidden = [important.reason length] ? NO : YES;
    self.descriptionLabel.text = important.reason;
    
    self.importantActions.hidden = ![observation currentUserCanUpdateImportant];
    
    [self registerForThemeChanges];
}

- (IBAction) onRemoveImportantTapped:(id)sender {
    if (self.observationImportantDelegate) {
        [self.observationImportantDelegate removeObservationImportant];
    }
}

- (IBAction) onUpdateImportantTapped:(id)sender {
    if (self.observationImportantDelegate) {
        [self.observationImportantDelegate flagObservationImportant];
    }
}

@end
