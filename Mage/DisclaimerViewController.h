//
//  ConsentViewController.h
//  MAGE
//
//

#import <UIKit/UIKit.h>
#import <MaterialComponents/MaterialContainerScheme.h>

@protocol DisclaimerDelegate

- (void) disclaimerAgree;
- (void) disclaimerDisagree;

@end

@interface DisclaimerViewController : UIViewController

@property (weak, nonatomic) id<DisclaimerDelegate> delegate;
- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme;

@end
