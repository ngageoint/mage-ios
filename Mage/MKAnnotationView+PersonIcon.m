//
//  MKAnnotationView+PersonIcon.m
//  MAGE
//
//

#import "MKAnnotationView+PersonIcon.h"
#import "UIImage+Resize.h"
#import <Location.h>
#import <NSDate+DateTools.h>
#import "StoredPassword.h"

@implementation MKAnnotationView (PersonIcon)

- (UIColor *) colorForUser: (User *) user {
    NSDate *timestamp = user.location.timestamp;
    NSDate *now = [NSDate date];
    if ([timestamp isEarlierThanOrEqualTo: [now dateBySubtractingMinutes:30]]) {
        return [UIColor orangeColor];
    } else if ([timestamp isEarlierThanOrEqualTo: [now dateBySubtractingMinutes:10]]) {
        return [UIColor yellowColor];
    }
    
    return [UIColor blueColor];
}

- (void) setImageForUser:(User *) user {
    [self setAccessibilityLabel:@"Person"];
    [self setAccessibilityValue:@"Person"];
    
    if (!user.iconUrl) {
        self.image = [self circleWithColor:[self colorForUser:user]];
        return;
    }
    
    UIImage *image = nil;
    if ([[user.iconUrl lowercaseString] hasPrefix:@"http"]) {
        NSString *token = [StoredPassword retrieveStoredToken];
        image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?access_token=%@", user.iconUrl, token]]]];
    } else {
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
        image = [UIImage imageWithData:[NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", documentsDirectory, user.iconUrl]]];
    }
    NSLog(@"Showing icon from %@", user.iconUrl);
    UIImage *resizedImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(37, 10000) interpolationQuality:kCGInterpolationLow];
    [resizedImage setAccessibilityIdentifier:user.iconUrl];
    self.image = [self mergeImage:resizedImage withDot:[self circleWithColor:[self colorForUser:user]]];
}

- (UIImage *) circleWithColor: (UIColor *) color {
    UIImage *blueCircle = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(15.f, 15.f), NO, 0.0f);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSaveGState(ctx);
        
        CGRect rect = CGRectMake(1, 1, 13, 13);
        CGContextSetFillColorWithColor(ctx, color.CGColor);
        CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
        CGContextSetLineWidth(ctx, 2);
        CGContextFillEllipseInRect(ctx, rect);
        CGContextStrokeEllipseInRect(ctx, rect);
        
        CGContextRestoreGState(ctx);
        blueCircle = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
//    });
    return blueCircle;
}

- (UIImage *)mergeImage: (UIImage *)image withDot: (UIImage *)dot {
    CGSize size = CGSizeMake(image.size.width, image.size.height + (dot.size.height/2));
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    
    CGPoint starredPoint = CGPointMake((size.width/2.0f) - (dot.size.width/2.0f), size.height - dot.size.height);
    [dot drawAtPoint:starredPoint];
    [image drawAtPoint:CGPointMake(0, 0)];
    
    UIImage *imageC = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageC;
}

@end
