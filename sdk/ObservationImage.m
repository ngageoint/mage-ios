//
//  ObservationImage.m
//  Mage
//
//

#import "ObservationImage.h"
#import "Server.h"
#import "MAGE-Swift.h"

const CGFloat annotationScaleWidth = 35.0;

@interface ObservationImage()

+ (NSCache *) imageCache;

@end

@implementation ObservationImage

+ (NSCache *) imageCache {
    static NSCache *imageDictionary = nil;
    if (imageDictionary == nil) {
        imageDictionary = [[NSCache alloc] init];
        imageDictionary.countLimit = 100;
    }
    return imageDictionary;
}

+ (NSString *) imageNameForObservation:(Observation *) observation {
    if (!observation) return nil;
    
    NSString *primaryField = [observation getPrimaryField];
    NSString *secondaryField = [observation getSecondaryField];
    NSMutableArray *iconProperties = [[NSMutableArray alloc] init];
    NSDictionary *primaryObservationForm = [observation getPrimaryObservationForm];
    
    if (primaryObservationForm) {
        [iconProperties addObject:[primaryObservationForm objectForKey:@"formId"]];
    }
    
    NSString *rootIconFolder = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat: @"/events/icons-%@/icons", observation.eventId]];
    
    if (primaryField != nil && [[primaryObservationForm objectForKey:primaryField] length]) {
        [iconProperties addObject: [primaryObservationForm objectForKey:primaryField]];
    }
    if (secondaryField != nil && [[primaryObservationForm objectForKey:secondaryField] length]) {
        [iconProperties addObject: [primaryObservationForm objectForKey:secondaryField]];
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
    NSString *imagePath = [ObservationImage imageNameForObservation:observation];
    UIImage *image = [[ObservationImage imageCache] objectForKey:imagePath];
    if (!image) {
        image = [UIImage imageWithContentsOfFile:imagePath];
        float scale = image.size.width / annotationScaleWidth;
        
        UIImage *scaledImage = [UIImage imageWithCGImage:[image CGImage] scale:scale orientation:image.imageOrientation];
        [[ObservationImage imageCache] setObject:scaledImage forKey:imagePath];
        image = scaledImage;
    }
    if (image == nil) {
        image = [UIImage imageNamed:@"defaultMarker"];
    }
    
    [image setAccessibilityIdentifier:imagePath];
    
    return image;
}

@end
