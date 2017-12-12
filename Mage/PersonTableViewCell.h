//
//  PersonTableViewCell.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "User.h"

@protocol UserActionsDelegate <NSObject>

@required
- (void) userMapTapped:(id) sender;

@end

@interface PersonTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *timestamp;
@property (weak, nonatomic) IBOutlet UILabel *myself;
@property (weak, nonatomic) IBOutlet NSObject<UserActionsDelegate> *userActionsDelegate;
@property (strong, nonatomic) User *user;

- (id) populateCellWithUser:(User *) user;

@end
