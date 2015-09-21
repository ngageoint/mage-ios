//
//  LocationContainerViewController.h
//  MAGE
//
//

#import <UIKit/UIKit.h>
#import "UserSelectionDelegate.h"

@interface PeopleContainerViewController : UIViewController

@property (strong, nonatomic) id<UserSelectionDelegate> delegate;

@end
