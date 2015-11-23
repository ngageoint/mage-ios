//
//  SignUpViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "MageServer.h"

@interface SignUpTableViewController : UITableViewController<UITextFieldDelegate>
@property (strong, nonatomic) MageServer *server;
@end
