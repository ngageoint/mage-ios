//
//  ObservationAddImportantTableViewCell.h
//  MAGE
//
//  Created by William Newman on 10/27/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObservationHeaderTableViewCell.h"
#import "ObservationImportantDelegate.h"

@interface ObservationAddImportantTableViewCell : ObservationHeaderTableViewCell

@property (weak, nonatomic) IBOutlet NSObject<ObservationImportantDelegate> *observationImportantDelegate;

@end
