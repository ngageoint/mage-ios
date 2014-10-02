//
//  ObservationEditTextAreaTableViewCell.h
//  MAGE
//
//  Created by Dan Barela on 10/2/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationEditTableViewCell.h"

@interface ObservationEditTextAreaTableViewCell : ObservationEditTableViewCell <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textArea;

@end
