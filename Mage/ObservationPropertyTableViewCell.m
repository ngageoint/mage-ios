//
//  ObservationPropertyTableViewCell.m
//  Mage
//
//

#import "ObservationPropertyTableViewCell.h"

@implementation ObservationPropertyTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) populateCellWithKey:(id)key andValue:(id)value {
    self.valueTextView.text = [NSString stringWithFormat:@"%@", value];
    self.keyLabel.text = [NSString stringWithFormat:@"%@", key];
    [self.valueTextView setSecureTextEntry:YES];
}

- (CGFloat) getCellHeightForValue:(id)value {
    return self.bounds.size.height;
}

@end
