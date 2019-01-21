//
//  ObservationEditViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "Observation.h"
#import "ObservationEditListener.h"
#import "SFGeometry.h"

@protocol ObservationEditViewControllerDelegate

- (void) addVoiceAttachment;
- (void) addVideoAttachment;
- (void) addCameraAttachment;
- (void) addGalleryAttachment;
- (void) deleteObservation;
- (void) fieldSelected: (NSDictionary *) field;
- (void) attachmentSelected: (Attachment *) attachment;

@end

@interface ObservationEditViewController : UIViewController

@property (nonatomic) BOOL newObservation;
@property (strong, nonatomic) Observation *observation;
@property (strong, nonatomic) SFGeometry *location;
@property (strong, nonatomic) id<ObservationEditViewControllerDelegate> delegate;

- (instancetype) initWithDelegate: (id<ObservationEditViewControllerDelegate>) delegate andObservation: (Observation *) observation andNew: (BOOL) newObservation;
- (void) refreshObservation;
- (BOOL) validate;

@end
