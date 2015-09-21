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

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) populateCellWithKey:(id) key andValue:(id) value {
    NSDate* date = [NSDate dateFromIso8601String:value];
    
    self.valueTextView.text = [date formattedDisplayDate];
    self.keyLabel.text = [NSString stringWithFormat:@"%@", key];
}

@end
