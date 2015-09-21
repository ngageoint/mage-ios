//
//  ObservationTextAreaTableViewCell.m
//  Mage
//
//

#import "ObservationTextAreaTableViewCell.h"

@implementation ObservationTextAreaTableViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (CGFloat) getCellHeightForValue:(id)value {
    UIFont *cellFont = self.valueTextView.font;
    CGSize constraintSize = CGSizeMake(self.valueTextView.textContainer.size.width, MAXFLOAT);
    CGSize labelSize = [value sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:NSLineBreakByCharWrapping];
    [self.valueTextView setFrame:CGRectMake(self.valueTextView.frame.origin.x, self.valueTextView.frame.origin.y, self.valueTextView.frame.size.width, labelSize.height)];
    
    return self.valueTextView.textContainerInset.top + self.valueTextView.textContainerInset.bottom + self.valueTextView.frame.origin.y + labelSize.height+2 + 11;
}

@end
