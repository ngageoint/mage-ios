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
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UILabel *timestamp;


- (id) populateCellWithLocation:(Location *) location;

@end
