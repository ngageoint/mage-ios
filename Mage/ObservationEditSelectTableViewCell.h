//
//  ObservationPickerTableViewCell.h
//  Mage
//
//

#import "ObservationEditTableViewCell.h"

@import SkyFloatingLabelTextField;

@interface ObservationEditSelectTableViewCell : ObservationEditTableViewCell
@property (strong, nonatomic) IBOutlet SkyFloatingLabelTextFieldWithIcon *valueField;
@property (weak, nonatomic) IBOutlet UILabel *labelField;
@property (strong, nonatomic) id value;
@end
