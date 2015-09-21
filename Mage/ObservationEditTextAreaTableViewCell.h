//
//  ObservationEditTextAreaTableViewCell.h
//  MAGE
//
//

#import "ObservationEditTableViewCell.h"

@interface ObservationEditTextAreaTableViewCell : ObservationEditTableViewCell <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textArea;

@end
