//
//  StaticPointAnnotation.m
//  MAGE
//
//

#import "StaticPointAnnotation.h"

@implementation StaticPointAnnotation

-(id) initWithFeature:(NSDictionary *)feature {
    if ((self = [super init])) {
        
        NSArray *coordinates = [feature valueForKeyPath:@"geometry.coordinates"];
        [self setCoordinate:CLLocationCoordinate2DMake([[coordinates objectAtIndex: 1] floatValue], [[coordinates objectAtIndex: 0] floatValue])];
        _iconUrl = [feature valueForKeyPath:@"properties.style.iconStyle.icon.href"];
        [self setTitle:[feature valueForKeyPath: @"properties.name"]];
        [self setSubtitle:[feature valueForKeyPath: @"properties.description"]];
        _feature = feature;
    }
    return self;
}

- (MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView {
    MKAnnotationView *annotationView = (MKAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:_iconUrl];
    
    if (annotationView == nil) {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:self reuseIdentifier:_iconUrl];
        annotationView.enabled = YES;
        annotationView.canShowCallout = YES;
       
        NSLog(@"showing icon from %@", _iconUrl);
        UIImage *image = nil;
        if ([[_iconUrl lowercaseString] hasPrefix:@"http"]) {
            image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:_iconUrl]]];
        } else {
            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
            image = [UIImage imageWithData:[NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", documentsDirectory,_iconUrl]]];
        }
        
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
