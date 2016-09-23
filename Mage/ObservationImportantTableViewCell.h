//
//  ImportantTableViewCell.h
//  MAGE
//
//  Created by William Newman on 9/28/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObservationHeaderTableViewCell.h"
#import "ObservationImportantDelegate.h"

@interface ObservationImportantTableViewCell : ObservationHeaderTableViewCell

@property (weak, nonatomic) IBOutlet NSObject<ObservationImportantDelegate> *observationImportantDelegate;

@end
