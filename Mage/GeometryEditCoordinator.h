//
//  GeometryEditCoordinator.h
//  MAGE
//
//  Created by Dan Barela on 1/30/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKBGeometry.h"

@protocol GeometryEditDelegate

- (void) geometryUpdated: (WKBGeometry *) geometry;

@end

@interface GeometryEditCoordinator : NSObject

@property (strong, nonatomic) WKBGeometry *originalGeometry;
@property (strong, nonatomic) WKBGeometry *currentGeometry;

@property (strong, nonatomic) id<GeometryEditDelegate> delegate;
@property (strong, nonatomic) UIImage *pinImage;
@property (strong, nonatomic) NSDictionary *fieldDefinition;

- (instancetype) initWithFieldDefinition: (NSDictionary *) fieldDefinition andGeometry: (WKBGeometry *) geometry andPinImage: (UIImage *) pinImage andDelegate: (id<GeometryEditDelegate>) delegate andNavigationController: (UINavigationController *) navigationController;
- (void) start;
- (void) updateGeometry: (WKBGeometry *) geometry;
- (NSString *) fieldName;

@end
