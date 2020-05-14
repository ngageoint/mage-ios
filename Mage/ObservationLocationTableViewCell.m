//
//  ObservationLocationTableViewCell.m
//  MAGE
//
//  Created by William Newman on 5/8/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationLocationTableViewCell.h"
#import "Theme+UIResponder.h"
#import <mgrs/MGRS.h>

@interface ObservationLocationTableViewCell()
@property (weak, nonatomic) IBOutlet UIImageView *locationIcon;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *accuracyLabel;
@end

@implementation ObservationLocationTableViewCell

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor dialog];
    self.locationLabel.textColor = [UIColor primaryText];
    self.accuracyLabel.textColor = [UIColor secondaryText];
    self.locationIcon.tintColor = [[UIColor mageBlue] colorWithAlphaComponent:.87];
}

- (void) configureCellForObservation: (Observation *) observation withForms:(NSArray *)forms {
    self.locationLabel.text = [self getLocationText:observation];
        
    self.accuracyLabel.hidden = YES;
    NSString *provider = [observation.properties objectForKey:@"provider"];
    if (![provider isEqualToString:@"manual"]) {
        self.accuracyLabel.hidden = NO;
        
        if ([provider isEqualToString:@"gps"]) {
            provider = [provider uppercaseString];
        } else if (provider != nil) {
            provider = [provider capitalizedString];
        }
        
        NSString *accuracy = @"";
        id accuracyProperty = [observation.properties valueForKey:@"accuracy"];
        if (accuracyProperty != nil) {
            accuracy = [NSString stringWithFormat:@" +/- %.02fm", [accuracyProperty floatValue]];
        }
        
        self.accuracyLabel.text = [NSString stringWithFormat:@"%@%@", provider ?: @"", accuracy];
    }
    
    [self registerForThemeChanges];
}

- (NSString *) getLocationText:(Observation *) observation {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"showMGRS"]) {
        return [MGRS MGRSfromCoordinate:observation.location.coordinate];
    } else {
        return [NSString stringWithFormat:@"%.05f, %.05f", observation.location.coordinate.latitude, observation.location.coordinate.longitude];
    }
}

@end
