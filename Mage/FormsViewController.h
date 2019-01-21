//
//  FormsViewController.h
//  MAGE
//
//  Created by Dan Barela on 8/10/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SFGeometry.h"

@interface FormsViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource>

@property (strong, nonatomic) SFGeometry *location;
@property (strong, nonatomic) NSArray *forms;

@end
