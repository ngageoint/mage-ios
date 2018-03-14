//
//  ObservationHeaderTableViewCell.h
//  MAGE
//
//

#import <UIKit/UIKit.h>
#import "Observation.h"

@interface ObservationHeaderTableViewCell : UITableViewCell

- (void) configureCellForObservation: (Observation *) observation withForms: (NSArray *) forms;

@end
