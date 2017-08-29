//
//  ObservationEditViewDataStore.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import <Observation.h>
#import "ObservationEditListener.h"
#import "AttachmentSelectionDelegate.h"
#import "ObservationAnnotationChangedDelegate.h"

@protocol ObservationEditFieldDelegate <NSObject>

- (void) fieldSelected: (NSDictionary *) field;
- (void) attachmentSelected: (Attachment *) attachment;
- (void) deleteObservation;

@end

@interface ObservationEditViewDataStore : NSObject <UITableViewDelegate, UITableViewDataSource, ObservationEditListener>

@property (strong, nonatomic) Observation *observation;

@property (weak, nonatomic) IBOutlet UITableView *editTable;
@property (nonatomic, weak) IBOutlet NSObject<AttachmentSelectionDelegate> *attachmentSelectionDelegate;
@property (nonatomic, strong) NSObject<ObservationAnnotationChangedDelegate> *annotationChangedDelegate;

- (instancetype) initWithObservation: (Observation *)observation andIsNew: (BOOL) isNew andDelegate: (id<ObservationEditFieldDelegate>) delegate andAttachmentSelectionDelegate: (id<AttachmentSelectionDelegate>) attachmentDelegate andEditTable: (UITableView *) tableView;

- (BOOL) validate;

@end
