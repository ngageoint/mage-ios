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
- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation;
- (void) selectRow;
- (void) setValid:(BOOL) valid;
- (BOOL) isValid;
- (BOOL) isEmpty;
@end

@interface ObservationEditTableViewCell : UITableViewCell <UITextFieldDelegate, ValidObservationProperty>

@property (weak, nonatomic) IBOutlet UILabel *keyLabel;
@property (weak, nonatomic) IBOutlet UILabel *requiredIndicator;

@property (weak, nonatomic) NSDictionary *fieldDefinition;
@property (nonatomic, weak) id<ObservationEditListener> delegate;


@end
