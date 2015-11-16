//
//  PersonTableViewCell.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "User+helper.h"

@interface PersonTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *timestamp;
@property (weak, nonatomic) IBOutlet UILabel *myself;


- (id) populateCellWithUser:(User *) user;

@end
