//
//  ObservationDatePickerTableViewCell.h
//  Mage
//
//

#import "ObservationEditTableViewCell.h"
@import SkyFloatingLabelTextField;

@interface ObservationDatePickerTableViewCell : ObservationEditTableViewCell
@property (weak, nonatomic) IBOutlet SkyFloatingLabelTextFieldWithIcon *textField;
@end
