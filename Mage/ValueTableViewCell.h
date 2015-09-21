//
//  TimeTableViewCell.h
//  Mage
//
//

#import <UIKit/UIKit.h>

@interface ValueTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (nonatomic, strong) NSString *preferenceValue;

@end
