//
//  ObservationContainerViewController.h
//  MAGE
//
//

#import <UIKit/UIKit.h>
#import "AttachmentSelectionDelegate.h"
#import "ObservationSelectionDelegate.h"

@interface ObservationContainerViewController : UIViewController

@property (strong, nonatomic) id<AttachmentSelectionDelegate, ObservationSelectionDelegate> delegate;

@end
