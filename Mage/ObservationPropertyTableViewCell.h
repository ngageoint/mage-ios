//
//  ObservationPropertyTableViewCell.h
//  Mage
//
//

#import <UIKit/UIKit.h>

@interface ObservationPropertyTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextView *valueTextView;
@property (weak, nonatomic) IBOutlet UILabel *keyLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) NSDictionary *fieldDefinition;

- (void) populateCellWithKey: (id) key andValue: (id) value;

@end
