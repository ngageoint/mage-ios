//
//  TimePickerTableViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>

@interface ValuePickerTableViewController : UITableViewController <UITableViewDelegate>

@property (nonatomic, strong) NSString *section;
@property (nonatomic, strong) NSArray *labels;
@property (nonatomic, strong) NSArray *values;
@property (nonatomic) NSNumber *selected;
@property (nonatomic, strong) NSString *preferenceKey;

@end
