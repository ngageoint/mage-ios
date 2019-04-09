//
//  ObservationEditTableViewCell.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "Observation.h"
#import "ObservationEditListener.h"
#import "AttachmentSelectionDelegate.h"

@protocol ValidObservationProperty
- (void) populateCellWithFormField: (id) field andValue: (id) value;
- (void) selectRow;
- (void) setValid:(BOOL) valid;
- (BOOL) isValid;
- (BOOL) isValid:(BOOL) required;
- (BOOL) isEmpty;
@end

@interface ObservationEditTableViewCell : UITableViewCell <UITextFieldDelegate, ValidObservationProperty>

@property (weak, nonatomic) IBOutlet UILabel *keyLabel;
@property (weak, nonatomic) IBOutlet UILabel *requiredIndicator;

@property (strong, nonatomic) NSDictionary *fieldDefinition;
@property (nonatomic, weak) id<ObservationEditListener> delegate;

@property (nonatomic) BOOL fieldValueValid;

@end
