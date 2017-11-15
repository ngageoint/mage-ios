//
//  ObservationImage.m
//  Mage
//
//

#import "ObservationImage.h"
#import "Server.h"
#import "Event.h"

const CGFloat annotationScaleWidth = 35.0;

@implementation ObservationImage

+ (NSString *) imageNameForObservation:(Observation *) observation {
    if (!observation) return nil;
    
    NSString *primaryField = [observation getPrimaryField];
    NSString *secondaryField = [observation getSecondaryField];
    NSMutableArray *iconProperties = [[NSMutableArray alloc] init];
    NSArray *observationForms = [observation.properties objectForKey:@"forms"];
    
    if ([observationForms count] != 0) {
        [iconProperties addObject:[[observationForms objectAtIndex:0] objectForKey:@"formId"]];
    }
    
    NSString *rootIconFolder = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat: @"/events/icons-%@/icons", observation.eventId]];
    
    if (primaryField != nil && [[[observationForms objectAtIndex:0] objectForKey:primaryField] length]) {
        [iconProperties addObject: [[observationForms objectAtIndex:0] objectForKey:primaryField]];
    }
    if (secondaryField != nil && [[[observationForms objectAtIndex:0] objectForKey:secondaryField] length]) {
        [iconProperties addObject: [[observationForms objectAtIndex:0] objectForKey:secondaryField]];
    }
    
    BOOL foundIcon = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    while(!foundIcon) {
        NSString *iconPath = [iconProperties componentsJoinedByString:@"/"];
        NSString *directoryToSearch = [rootIconFolder stringByAppendingPathComponent:iconPath];
        if ([fileManager fileExistsAtPath:directoryToSearch]) {
            NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:[rootIconFolder stringByAppendingPathComponent:iconPath] error:nil];
            
            if ([directoryContents count] != 0) {
                for (NSString *path in directoryContents) {
                    NSString *filename = [path lastPathComponent];
                    if ([filename hasPrefix:@"icon"]) {
                        return [[rootIconFolder stringByAppendingPathComponent:iconPath] stringByAppendingPathComponent:path];
                    }
                }
            }
            
            if ([iconProperties count] == 0) {
                foundIcon = YES;
            }
            [iconProperties removeLastObject];
        } else {
            if ([iconProperties count] == 0) {
                foundIcon = YES;
            }
            [iconProperties removeLastObject];
        }
    }
    return nil;
}

+ (UIImage *) imageForObservation:(Observation *) observation {
    UIImage *image;

    if ([[observation getGeometry] geometryType] == WKB_POINT) {
        NSString *imagePath = [ObservationImage imageNameForObservation:observation];
        image = [UIImage imageWithContentsOfFile:imagePath];
        if (image == nil) {
            image = [UIImage imageNamed:@"defaultMarker"];
        }
        
        [image setAccessibilityIdentifier:imagePath];
        
        return image;
    } else if ([[observation getGeometry] geometryType] == WKB_LINESTRING) {
        image = [UIImage imageNamed:@"line_string_marker"];
    } else if ([[observation getGeometry] geometryType] == WKB_POLYGON) {
        image = [UIImage imageNamed:@"polygon_marker"];
    }
    if (image == nil) return nil;
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(38, 50), NO, 0.0f);
    [image drawInRect:CGRectMake(0.0f, 0.0f, 38, 38)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [newImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

+ (UIImage *) imageForObservation:(Observation *) observation inMapView: (MKMapView *) mapView {
    UIImage *image = [self imageForObservation:observation];
    
    if (mapView != nil && image != nil) {
        float scale = image.size.width / annotationScaleWidth;
        
        UIImage *scaledImage = [UIImage imageWithCGImage:[image CGImage] scale:scale orientation:image.imageOrientation];
        return scaledImage;
    }
    
    return image;
}

@end
