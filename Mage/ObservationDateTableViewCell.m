//
//  ObservationDateTableViewCell.m
//  Mage
//
//

#import "ObservationDateTableViewCell.h"
#import "NSDate+Iso8601.h"
#import "NSDate+display.h"

@interface ObservationDateTableViewCell()
@end

@implementation ObservationDateTableViewCell

- (void) populateCellWithKey:(id) key andValue:(id) value {
    NSDate* date = [NSDate dateFromIso8601String:value];
    
    self.valueTextView.text = [date formattedDisplayDate];
    self.keyLabel.text = [NSString stringWithFormat:@"%@", key];
}

@end
