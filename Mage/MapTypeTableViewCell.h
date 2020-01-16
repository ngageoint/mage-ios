//
//  MapTypeTableViewCell.h
//  MAGE
//
//  Created by Dan Barela on 1/4/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@protocol MapTypeDelegate

-(void) mapTypeChanged:(MKMapType) mapType;

@end

@interface MapTypeTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UISegmentedControl *mapTypeSegmentedControl;
@property (weak, nonatomic) id<MapTypeDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *cellTitle;

@end
