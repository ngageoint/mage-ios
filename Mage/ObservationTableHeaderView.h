//
//  ObservationTableHeaderView.h
//  MAGE
//
//  Created by Dan Barela on 3/8/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MaterialComponents/MaterialContainerScheme.h>

@interface ObservationTableHeaderView : UIView

- (instancetype) initWithName:(NSString *)name andScheme: (id<MDCContainerScheming>) containerScheme;

@end
