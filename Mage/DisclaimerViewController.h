//
//  ConsentViewController.h
//  MAGE
//
//

#import <UIKit/UIKit.h>

@protocol DisclaimerDelegate

- (void) disclaimerAgree;
- (void) disclaimerDisagree;

@end

@interface DisclaimerViewController : UIViewController

- (instancetype) initWithDelegate: (id<DisclaimerDelegate>) delegate;

@end
