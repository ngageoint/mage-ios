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

@property (weak, nonatomic) id<DisclaimerDelegate> delegate;

@end
