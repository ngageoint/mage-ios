//
//  EventTableHeaderView.h
//  MAGE
//
//  Created by Dan Barela on 4/23/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
@import MaterialComponents;

@interface EventTableHeaderView : UIView

- (instancetype) initWithName:(NSString *)name containerScheme:(id<MDCContainerScheming>)containerScheme;

@end
