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
#import "SFPoint.h"

@interface GeometryEditCoordinator()

@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) GeometryEditViewController *geometryEditViewController;

@end

@implementation GeometryEditCoordinator

- (instancetype) initWithFieldDefinition: (NSDictionary *) fieldDefinition andGeometry: (SFGeometry *) geometry andPinImage: (UIImage *) pinImage andDelegate: (id<GeometryEditDelegate>) delegate andNavigationController: (UINavigationController *) navigationController {
    if (self = [super init]) {
        self.delegate = delegate;
        self.navigationController = navigationController;
        self.pinImage = pinImage;
        self.fieldDefinition = fieldDefinition;
        self.currentGeometry = geometry;
        
        if (self.currentGeometry == nil) {
            CLLocation *location = [[LocationService singleton] location];

            if (location) {
                self.currentGeometry = [[SFPoint alloc] initWithXValue:location.coordinate.longitude andYValue:location.coordinate.latitude];
            } else {
                // TODO fixme, bug fix for iOS 10, creating coordinate at 0,0 does not work, create at 1,1
                self.currentGeometry = [[SFPoint alloc] initWithXValue:1.0 andYValue:1.0];
            }
        }
    }
    
    return self;
}

- (void) start {
    self.geometryEditViewController = [[GeometryEditViewController alloc] initWithCoordinator: self];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(fieldEditCanceled)];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(fieldEditDone)];
    [self.geometryEditViewController.navigationItem setLeftBarButtonItem:backButton];
    [self.geometryEditViewController.navigationItem setRightBarButtonItem:doneButton];
    [self.navigationController pushViewController:self.geometryEditViewController animated:YES];
}

- (void) fieldEditCanceled {
    [self.delegate geometryEditCancel:self];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) fieldEditDone {
    // Validate the geometry
    NSError *error;
    if (![self.geometryEditViewController validate:&error]) {
        NSString *message = [[error userInfo] valueForKey:NSLocalizedDescriptionKey];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Invalid Geometry"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        
        [self.navigationController presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    [self.delegate geometryEditComplete:self.currentGeometry fieldDefintion:self.fieldDefinition coordinator:self];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) updateGeometry: (SFGeometry *) geometry {
    self.currentGeometry = geometry;
}

- (NSString *) fieldName {
    return [[self.fieldDefinition objectForKey:@"name"] isEqualToString:@"geometry"] ? @"Location" : [self.fieldDefinition objectForKey:@"title"];
}

@end
