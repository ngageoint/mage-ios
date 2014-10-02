//
//  MapViewController_iPad.m
//  MAGE
//
//  Created by William Newman on 9/30/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapViewController_iPad.h"

@implementation MapViewController_iPad

//-(void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *) button {
//    self.masterViewButton = nil;
//    self.masterViewPopover = nil;
//    
//    NSMutableArray *itemArray = [self.toolbar.items mutableCopy];
//    [itemArray removeObject:button];
//    [self.toolbar setItems:itemArray];
//}
//
//
//-(void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)button forPopoverController:(UIPopoverController *) pc {
//    self.masterViewButton = button;
//    self.masterViewPopover = pc;
//    
//    button.image = [UIImage imageNamed:@"bars"];
//    
//    NSMutableArray *items = [self.toolbar.items mutableCopy];
//    if (!items) {
//        items = [NSMutableArray arrayWithObject:button];
//    } else {
//        [items insertObject:button atIndex:0];
//    }
//    
//    [self.toolbar setItems:items];
//}
//
//- (void) buttonClick {
//    if (self.masterViewButton && self.masterViewPopover) {
//        [self.masterViewPopover presentPopoverFromBarButtonItem:self.masterViewButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
//    }
//}

@end
