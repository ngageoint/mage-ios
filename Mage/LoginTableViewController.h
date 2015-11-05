//
//  LoginViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "Authentication.h"

@interface LoginTableViewController : UITableViewController<AuthenticationDelegate, UITextFieldDelegate>

@end
