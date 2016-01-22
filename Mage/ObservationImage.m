//
//  ObservationImage.m
//  Mage
//
//

#import "ObservationImage.h"
#import "Server+helper.h"
#import <Event+helper.h>

const CGFloat annotationScaleWidth = 35.0;

@implementation ObservationImage

+ (NSString *) imageNameForObservation:(Observation *) observation {
	if (!observation) return nil;
    Event *event = [Event MR_findFirstByAttribute:@"remoteId" withValue:[Server currentEventId]];
    NSDictionary *form = event.form;
    NSString *rootIconFolder = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat: @"/events/icons-%@/icons", event.remoteId]];
    
    NSString *type = [observation.properties objectForKey:@"type"];
    if (type == nil) {
        return nil;
    }
    
    NSString *variantField = [form objectForKey:@"variantField"];
    NSMutableArray *iconProperties = [[NSMutableArray alloc] initWithArray: @[type]];
    if (variantField != nil && [[observation.properties objectForKey:variantField] length]) {
        [iconProperties addObject: [observation.properties objectForKey:variantField]];
    }
    
    BOOL foundIcon = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    while(!foundIcon) {
        NSString *iconPath = [iconProperties componentsJoinedByString:@"/"];
        NSString *directoryToSearch = [rootIconFolder stringByAppendingPathComponent:iconPath];
        NSLog(@"search directory %@", directoryToSearch);
        if ([fileManager fileExistsAtPath:directoryToSearch]) {
            NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:[rootIconFolder stringByAppendingPathComponent:iconPath] error:nil];
            NSLog(@"directory contents %@", [directoryContents description]);

            if ([directoryContents count] != 0) {
                for (NSString *path in directoryContents) {
                    NSString *filename = [path lastPathComponent];
                    NSLog(@"filename is %@", filename);
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
    NSString *imagePath = [ObservationImage imageNameForObservation:observation];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    if (image == nil) {
        image = [UIImage imageNamed:@"defaultMarker"];
    }
    
    [image setAccessibilityIdentifier:imagePath];
    
    return image;
}


+ (UIImage *) imageForObservation:(Observation *) observation inMapView: (MKMapView *) mapView {
    UIImage *image = [self imageForObservation:observation];

    if (mapView != nil && image != nil) {
        float scale = annotationScaleWidth / image.size.width;
        
        // Ensure annotation will  fit in map view
        // Add 5 to give the annotation a little padding
        if ((image.size.height * scale) > (mapView.frame.size.height / 2)) {
            scale = (mapView.frame.size.height / 2) / (image.size.height + 5);
        }
        
        float newHeight = image.size.height * scale;
        float newWidth = image.size.width * scale;
        
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
        [image drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [newImage setAccessibilityIdentifier:[image accessibilityIdentifier]];
        return newImage;
    }
    
	return image;
}

@end
