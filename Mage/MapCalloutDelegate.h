//
//  MapCalloutDelegate.h
//  MAGE
//
//  Created by William Newman on 9/26/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CalloutTappedDelegate <NSObject>

@required
    -(void) calloutTapped:(id) calloutItem;

@end

@interface MapCalloutDelegate : NSObject<CalloutTappedDelegate>
    @property(nonatomic, weak) IBOutlet UIViewController *viewController;
    @property(nonatomic, weak) NSString *segueIdentifier;
@end
