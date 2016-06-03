//
//  ObservationPickerTableViewCell.h
//  Mage
//
//

#import "ObservationEditTableViewCell.h"

@interface ObservationEditSelectTableViewCell : ObservationEditTableViewCell
@property (strong, nonatomic) IBOutlet UILabel *valueField;
@property (strong, nonatomic) id value;
@end
