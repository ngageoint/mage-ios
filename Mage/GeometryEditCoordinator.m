//
//  GeometryEditCoordinator.m
//  MAGE
//
//  Created by Dan Barela on 1/30/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "GeometryEditCoordinator.h"
#import "GeometryEditViewController.h"
#import "LocationService.h"
#import "WKBPoint.h"

@interface GeometryEditCoordinator()

@property (strong, nonatomic) UINavigationController *navigationController;

@end

@implementation GeometryEditCoordinator

- (instancetype) initWithFieldDefinition: (NSDictionary *) fieldDefinition andGeometry: (WKBGeometry *) geometry andPinImage: (UIImage *) pinImage andDelegate: (id<GeometryEditDelegate>) delegate andNavigationController: (UINavigationController *) navigationController {
    if (self = [super init]) {
        self.delegate = delegate;
        self.navigationController = navigationController;
        self.pinImage = pinImage;
        self.fieldDefinition = fieldDefinition;
        self.currentGeometry = geometry;
        
        if (self.currentGeometry == nil) {
            CLLocation *location = [[LocationService singleton] location];

            if (location) {
                self.currentGeometry = [[WKBPoint alloc] initWithXValue:location.coordinate.longitude andYValue:location.coordinate.latitude];
            } else {
                // TODO fixme, bug fix for iOS 10, creating coordinate at 0,0 does not work, create at 1,1
                self.currentGeometry = [[WKBPoint alloc] initWithXValue:1.0 andYValue:1.0];
            }
        }
    }
    
    return self;
}

- (void) start {
    GeometryEditViewController *vc = [[GeometryEditViewController alloc] initWithCoordinator: self];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(fieldEditCanceled)];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(fieldEditDone)];
    [vc.navigationItem setLeftBarButtonItem:backButton];
    [vc.navigationItem setRightBarButtonItem:doneButton];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void) fieldEditCanceled {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) fieldEditDone {
    [self.delegate geometryUpdated:self.currentGeometry];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) updateGeometry: (WKBGeometry *) geometry {
    self.currentGeometry = geometry;
}

- (NSString *) fieldName {
    return [[self.fieldDefinition objectForKey:@"name"] isEqualToString:@"geometry"] ? @"Location" : [self.fieldDefinition objectForKey:@"name"];
}

@end
