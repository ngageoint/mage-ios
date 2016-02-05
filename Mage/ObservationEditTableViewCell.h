//
//  ObservationEditTableViewCell.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import <Observation.h>
#import "ObservationEditListener.h"
#import "AttachmentSelectionDelegate.h"

@protocol ValidObservationProperty
- (void) setValid:(BOOL) valid;
@end

@interface ObservationEditTableViewCell : UITableViewCell <UITextFieldDelegate, ValidObservationProperty>

@property (weak, nonatomic) IBOutlet UITextField *valueTextField;
@property (weak, nonatomic) IBOutlet UILabel *keyLabel;
@property (weak, nonatomic) NSDictionary *fieldDefinition;
@property (nonatomic, weak) id<ObservationEditListener> delegate;
@property (weak, nonatomic) IBOutlet UILabel *requiredIndicator;
@property (weak, nonatomic) IBOutlet NSObject<AttachmentSelectionDelegate> *attachmentSelectionDelegate;

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation;
- (CGFloat) getCellHeightForValue: (id) value;
- (void) selectRow;

@end
