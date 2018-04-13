//
//  FormPickerViewController.h
//  MAGE
//
//  Created by Dan Barela on 8/10/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WKBGeometry.h"

@protocol FormPickedDelegate <NSObject>

- (void) formPicked: (NSDictionary *) form;
- (void) cancelSelection;

@end

@interface FormPickerViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

- (instancetype) initWithDelegate: (id<FormPickedDelegate>) delegate andForms: (NSArray *) forms andLocation: (WKBGeometry *) location andNewObservation: (BOOL) newObservation;

@end
