//
//  ObservationImage.m
//  Mage
//
//

#import "ObservationImage.h"
#import "Server+helper.h"
#import <Event+helper.h>

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
    if (variantField != nil && [observation.properties objectForKey:variantField] != nil) {
        [iconProperties addObject: [observation.properties objectForKey:variantField]];
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
        } else {
            if ([iconProperties count] == 0) {
                foundIcon = YES;
            }
            [iconProperties removeLastObject];
        }
    }
    return nil;
}

+ (UIImage *) imageForObservation:(Observation *) observation scaledToWidth: (NSNumber *) width {
    NSString *imagePath = [ObservationImage imageNameForObservation:observation];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    if (image == nil) {
        image = [UIImage imageNamed:@"defaultMarker"];
    }
    
    [image setAccessibilityIdentifier:imagePath];
    
    if (width != nil && image != nil) {
        float oldWidth = image.size.width;
        float scaleFactor = [width floatValue] / oldWidth;
        
        float newHeight = image.size.height * scaleFactor;
        float newWidth = oldWidth * scaleFactor;
        
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
