//
//  ObservationEditViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import <Observation.h>
#import "ObservationEditListener.h"
#import "AttachmentCollectionDataStore.h"
#import "WKBGeometry.h"

@interface ObservationEditViewController : UIViewController

@property (strong, nonatomic) Observation *observation;
@property (strong, nonatomic) WKBGeometry *location;

@property (strong, nonatomic) id<AttachmentSelectionDelegate> attachmentDelegate;

@end
