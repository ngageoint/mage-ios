//
//  StaticPointAnnotation.m
//  MAGE
//
//  Created by Dan Barela on 1/29/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "StaticPointAnnotation.h"

@implementation StaticPointAnnotation

-(id) initWithFeature:(NSDictionary *)feature {
    if ((self = [super init])) {
        
        NSArray *coordinates = [feature valueForKeyPath:@"geometry.coordinates"];
        _coordinate = CLLocationCoordinate2DMake([[coordinates objectAtIndex: 1] floatValue], [[coordinates objectAtIndex: 0] floatValue]);
        _iconUrl = [feature valueForKeyPath:@"properties.style.iconStyle.icon.href"];
        _title = [feature valueForKeyPath: @"properties.name"];
        _subtitle = [feature valueForKeyPath: @"properties.description"];
        _feature = feature;
    }
    return self;
}

-(void) setCoordinate:(CLLocationCoordinate2D) coordinate {
    _coordinate = coordinate;
}

- (MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView {
    MKAnnotationView *annotationView = (MKAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:_iconUrl];
    
    if (annotationView == nil) {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:self reuseIdentifier:_iconUrl];
        annotationView.enabled = YES;
        annotationView.canShowCallout = YES;
       
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:_iconUrl]]];
        
        float oldWidth = image.size.width;
        float scaleFactor = 35.0 / oldWidth;
        
        float newHeight = image.size.height * scaleFactor;
        float newWidth = oldWidth * scaleFactor;
        
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
        [image drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [newImage setAccessibilityIdentifier:[image accessibilityIdentifier]];
        annotationView.image = newImage;
        
        annotationView.centerOffset = CGPointMake(0, -(annotationView.image.size.height/2.0f));
    } else {
        annotationView.annotation = self;
    }
    return annotationView;
}

@end
