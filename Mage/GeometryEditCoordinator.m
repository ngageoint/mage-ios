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
@property (nonatomic) BOOL valueChanged;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@end

@implementation GeometryEditCoordinator

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
}

- (instancetype) initWithFieldDefinition: (NSDictionary *) fieldDefinition andGeometry: (SFGeometry *) geometry andPinImage: (UIImage *) pinImage andDelegate: (id<GeometryEditDelegate>) delegate andNavigationController: (UINavigationController *) navigationController scheme: (id<MDCContainerScheming>) containerScheme {
    if (self = [super init]) {
        self.scheme = containerScheme;
        self.delegate = delegate;
        self.navigationController = navigationController;
        self.pinImage = pinImage;
        self.fieldDefinition = fieldDefinition;
        self.currentGeometry = geometry;
        self.valueChanged = false;
        
        if (self.currentGeometry == nil) {
            CLLocation *location = [[LocationService singleton] location];
            self.valueChanged = true;
            if (location) {
                self.currentGeometry = [[SFPoint alloc] initWithXValue:location.coordinate.longitude andYValue:location.coordinate.latitude];
            } else {
                // TODO fixme, bug fix for iOS 10, creating coordinate at 0,0 does not work, create at 1,1
                self.currentGeometry = [[SFPoint alloc] initWithXValue:1.0 andYValue:1.0];
            }
            
            NSLog(@"Location %@", self.currentGeometry);
        }
    }
    
    return self;
}

- (UIViewController *) createViewController {
    self.geometryEditViewController = [[GeometryEditViewController alloc] initWithCoordinator: self scheme:self.scheme];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(fieldEditCanceled)];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(fieldEditDone)];
    doneButton.accessibilityLabel = @"Done";
    [self.geometryEditViewController.navigationItem setLeftBarButtonItem:backButton];
    [self.geometryEditViewController.navigationItem setRightBarButtonItem:doneButton];
    return self.geometryEditViewController;
}

- (void) start {
    [self createViewController];
    [self.navigationController pushViewController:self.geometryEditViewController animated:YES];
}

- (void) fieldEditCanceled {
    [self.delegate geometryEditCancel:self];
}

- (void) fieldEditDone {
    NSLog(@"Done geometry coordinator");
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
    [self.delegate geometryEditComplete:self.currentGeometry fieldDefintion:self.fieldDefinition coordinator:self wasValueChanged:self.valueChanged];
}

- (void) updateGeometry: (SFGeometry *) geometry {
    self.valueChanged = true;
    self.currentGeometry = geometry;
}

- (NSString *) fieldName {
    return [[self.fieldDefinition objectForKey:@"name"] isEqualToString:@"geometry"] ? @"Location" : [self.fieldDefinition objectForKey:@"title"];
}

@end
