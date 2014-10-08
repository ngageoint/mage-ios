//
//  ObservationTableViewCell.m
//  Mage
//
//  Created by Dan Barela on 7/17/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "ObservationTableViewCell.h"
#import "ObservationImage.h"
#import <NSDate+DateTools.h>
#import <User.h>

@implementation ObservationTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) populateCellWithObservation:(Observation *) observation {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *form = [defaults objectForKey:@"form"];
    NSString *variantField = [form objectForKey:@"variantField"];
    NSString *type = [observation.properties objectForKey:@"type"];
    self.primaryField.text = type;
    if (variantField != nil) {
        self.variantField.text = [observation.properties objectForKey:variantField];
    }
    self.icon.image = [ObservationImage imageForObservation:observation scaledToWidth:[NSNumber numberWithFloat:35]];
    
    NSString *timestamp = [observation.properties objectForKey:@"timestamp"];
    NSDateFormatter *dateFormat = [NSDateFormatter new];
    dateFormat.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    dateFormat.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    // Always use this locale when parsing fixed format date strings
    NSLocale* posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormat.locale = posix;
    NSDate* output = [dateFormat dateFromString:timestamp];
    
    self.timeField.text = output.shortTimeAgoSinceNow;
    
    self.userField.text = observation.user.name;
    if ([observation.attachments count] != 0) {
        self.numberOfAttachmentsLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[observation.attachments count]];
        self.paperClipImage.image = [self.paperClipImage.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.numberOfAttachmentsLabel setHidden:NO];
        [self.paperClipImage setHidden:NO];
    } else {
        [self.paperClipImage setHidden:YES];
        [self.numberOfAttachmentsLabel setHidden:YES];
    }
}

@end
