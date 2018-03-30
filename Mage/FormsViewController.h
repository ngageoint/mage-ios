//
//  FormsViewController.h
//  MAGE
//
//  Created by Dan Barela on 8/10/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WKBGeometry.h"

@interface FormsViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource>

@property (strong, nonatomic) WKBGeometry *location;
@property (strong, nonatomic) NSArray *forms;

@end
