//
//  PersonTableViewCell.h
//  Mage
//
//  Created by Billy Newman on 7/14/14.
//

#import <UIKit/UIKit.h>
#import "Location+helper.h"

@interface PersonTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *email;
@property (weak, nonatomic) IBOutlet UILabel *timestamp;

- (void) populateCellWithLocation:(Location *) location;

@end
