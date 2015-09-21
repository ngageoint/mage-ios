//
//  ObservationPickerTableViewCell.h
//  Mage
//
//

#import "ObservationEditTableViewCell.h"

@interface ObservationPickerTableViewCell : ObservationEditTableViewCell <UIPickerViewDataSource, UIPickerViewDelegate>

@property (strong, nonatomic) IBOutlet UIPickerView *picker;
@property (strong, nonatomic) NSMutableArray *pickerValues;

@end
