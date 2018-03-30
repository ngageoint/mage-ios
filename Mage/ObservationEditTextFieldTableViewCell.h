//
//  ObservationEditTextFieldTableViewCell.h
//  MAGE
//
//

#import "ObservationEditTableViewCell.h"

@import SkyFloatingLabelTextField;

@interface ObservationEditTextFieldTableViewCell : ObservationEditTableViewCell

@property (weak, nonatomic) IBOutlet SkyFloatingLabelTextFieldWithIcon *textField;

@end
