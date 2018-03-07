//
//  EventTableViewCell.m
//  MAGE
//
//  Created by William Newman on 5/24/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "EventTableViewCell.h"
#import "Theme+UIResponder.h"

@interface EventTableViewCell()
@property (weak, nonatomic) IBOutlet UILabel *eventName;
@property (weak, nonatomic) IBOutlet UILabel *eventDescription;
@property (weak, nonatomic) IBOutlet UILabel *eventBadgeLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *eventBadgeLabelHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *eventBadgeLabelWidth;
@property (weak, nonatomic) IBOutlet UIStackView *cellView;
@end

@implementation EventTableViewCell

- (void) registerForThemeChanges {
    self.eventName.textColor = [UIColor primaryText];
    self.eventDescription.textColor = [UIColor secondaryText];
}

- (void) populateCellWithEvent:(Event *) event offlineObservationCount:(NSUInteger) count {
    [self registerForThemeChanges];
    
    self.eventName.text = event.name;
    self.eventDescription.text = event.eventDescription;
    
    if (count > 0) {
        self.eventBadgeLabel.hidden = NO;

        // Create label
        CGFloat fontSize = self.eventBadgeLabel.font.pointSize;
        
        // Add count to label and get size
        self.eventBadgeLabel.text = [NSString stringWithFormat:@"%@", @(count)];
        CGSize textSize = [self.eventBadgeLabel.text sizeWithAttributes:@{NSFontAttributeName:[self.eventBadgeLabel font]}];
        
        // Adjust frame to be square for single digits or elliptical for numbers > 9
        CGFloat height = (int)(0.4 * fontSize) + textSize.height;
        CGFloat width = (count <= 9) ? height : textSize.width + (int) fontSize;
        
        // Set radius and clip to bounds
        self.eventBadgeLabel.layer.cornerRadius = height / 2.0;
        self.eventBadgeLabel.clipsToBounds = true;
        
        self.eventBadgeLabelWidth.constant = width;
        self.eventBadgeLabelHeight.constant = height;
    } else {
        self.eventBadgeLabel.hidden = YES;
    }
}

@end
