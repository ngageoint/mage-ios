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
#import "MAGE-Swift.h"

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
            }

            NSLog(@"Location %@", self.currentGeometry);
        }
        self.geometryEditViewController = [[GeometryEditViewController alloc] initWithCoordinator: self scheme:self.scheme];
    }
    
    return self;
}

- (UIViewController *) createViewController {
    return self.geometryEditViewController;
}

- (void) setMapEventDelegte: (id<MKMapViewDelegate>) mapEventDelegate {
    [self.geometryEditViewController.mapDelegate setMapEventDelegte:mapEventDelegate];
}

- (void) start {
    [self createViewController];
    [self.navigationController pushViewController:self.geometryEditViewController animated:YES];
}

- (void) fieldEditCanceled {
    [self.delegate geometryEditCancel:self];
}

- (void) fieldEditDone {
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
