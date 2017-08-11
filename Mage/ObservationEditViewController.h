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

@protocol ObservationEditViewControllerDelegate

- (void) editCanceled;
- (void) editComplete;

@end

@interface ObservationEditViewController : UIViewController

@property (nonatomic) BOOL newObservation;
@property (strong, nonatomic) Observation *observation;
@property (strong, nonatomic) WKBGeometry *location;
@property (strong, nonatomic) id<ObservationEditViewControllerDelegate> delegate;
@property (strong, nonatomic) id<AttachmentSelectionDelegate> attachmentDelegate;

- (instancetype) initWithDelegate: (id<ObservationEditViewControllerDelegate>) delegate andObservation: (Observation *) observation andNew: (BOOL) newObservation;

@end
