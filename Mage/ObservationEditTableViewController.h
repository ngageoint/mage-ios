//
//  ObservationEditViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "Observation.h"
#import "ObservationEditListener.h"
#import "AttachmentCollectionDataStore.h"
#import "ObservationEditViewDataStore.h"
#import "AudioRecordingDelegate.h"
#import "SFGeometry.h"

@protocol PropertyEditDelegate
- (void) setValue:(id) value forFieldDefinition:(NSDictionary *) fieldDefinition;
- (void) invalidValue:(id) value forFieldDefinition:(NSDictionary *) fieldDefinition;
@end

@interface ObservationEditTableViewController : UITableViewController<PropertyEditDelegate>

@property (strong, nonatomic) Observation *observation;
@property (strong, nonatomic) SFGeometry *location;

@property (strong, nonatomic) id<AttachmentSelectionDelegate> attachmentDelegate;

- (instancetype) initWithObservation: (Observation *) observation andIsNew: (BOOL) isNew andDelegate: (id<ObservationEditFieldDelegate>) delegate;

- (BOOL) validate;
- (void) refreshObservation;

@end
