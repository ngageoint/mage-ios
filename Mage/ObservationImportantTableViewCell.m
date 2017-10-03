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

@interface ObservationImportantTableViewCell()

@property (strong, nonatomic) User *currentUser;

@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIView *importantActions;

@end

@implementation ObservationImportantTableViewCell

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
