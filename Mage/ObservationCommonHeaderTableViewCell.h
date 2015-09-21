//
//  ObservationCommonHeaderTableViewCell.h
//  MAGE
//
//

#import "ObservationHeaderTableViewCell.h"

@interface ObservationCommonHeaderTableViewCell : ObservationHeaderTableViewCell
@property (weak, nonatomic) IBOutlet UILabel *primaryFieldLabel;
@property (weak, nonatomic) IBOutlet UILabel *variantFieldLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *userLabel;

@end
