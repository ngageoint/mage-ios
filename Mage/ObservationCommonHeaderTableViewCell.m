//
//  ObservationCommonHeaderTableViewCell.m
//  MAGE
//
//

#import "ObservationCommonHeaderTableViewCell.h"
#import <Server+helper.h>
#import <User.h>
#import <Event+helper.h>
#import "NSDate+display.h"

@interface ObservationCommonHeaderTableViewCell ()
@end

@implementation ObservationCommonHeaderTableViewCell


- (void) configureCellForObservation: (Observation *) observation {
    NSString *name = [observation.properties valueForKey:@"type"];
    if (name != nil) {
        self.primaryFieldLabel.text = name;
    } else {
        self.primaryFieldLabel.text = @"Observation";
    }
    Event *event = [Event MR_findFirstByAttribute:@"remoteId" withValue:[Server currentEventId]];
    NSDictionary *form = event.form;
    NSString *variantField = [form objectForKey:@"variantField"];
    if (variantField != nil) {
        self.variantFieldLabel.text = [observation.properties objectForKey:variantField];
    } else {
        self.variantFieldLabel.text = @"";
    }
    
    self.userLabel.text = observation.user.name;
    
    self.userLabel.text = observation.user.name;
    
    self.dateLabel.text = [observation.timestamp formattedDisplayDate];
}

@end
