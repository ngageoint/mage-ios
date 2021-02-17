//
//  DropdownEditViewController.h
//  MAGE
//
//  Created by William Newman on 6/1/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MaterialComponents/MaterialContainerScheme.h>

@protocol PropertyEditDelegate
- (void) setValue:(id) value forFieldDefinition:(NSDictionary *) fieldDefinition;
- (void) invalidValue:(id) value forFieldDefinition:(NSDictionary *) fieldDefinition;
@end

@interface SelectEditViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchResultsUpdating>

- (instancetype) initWithFieldDefinition: (NSDictionary *) fieldDefinition andValue: value andDelegate: (id<PropertyEditDelegate>) delegate scheme: (id<MDCContainerScheming>) containerScheme;
- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme;

@end
