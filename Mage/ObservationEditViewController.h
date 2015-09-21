//
//  ObservationEditViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import <Observation.h>
#import "ObservationEditListener.h"
#import "AttachmentCollectionDataStore.h"
#import <GeoPoint.h>

@interface ObservationEditViewController : UIViewController

@property (strong, nonatomic) Observation *observation;
@property (strong, nonatomic) GeoPoint *location;

@property (strong, nonatomic) id<AttachmentSelectionDelegate> attachmentDelegate;

@end
