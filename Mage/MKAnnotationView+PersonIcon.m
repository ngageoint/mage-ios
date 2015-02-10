//
//  MKAnnotationView+PersonIcon.m
//  MAGE
//
//  Created by William Newman on 1/10/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MKAnnotationView+PersonIcon.h"
#import "AFHTTPRequestOperation.h"
#import "UIImage+Resize.h"

@implementation MKAnnotationView (PersonIcon)

- (void) setImageForUser:(User *) user {
    [self setAccessibilityLabel:@"Person"];
    [self setAccessibilityValue:@"Person"];
    
    if (!user.iconUrl) {
        self.image = [self blueCircle];
        return;
    }
    
    UIImage *image = nil;
    if ([[user.iconUrl lowercaseString] hasPrefix:@"http"]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?access_token=%@", user.iconUrl, [defaults valueForKeyPath:@"loginParameters.token"]]]]];
    } else {
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
        image = [UIImage imageWithData:[NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", documentsDirectory, user.iconUrl]]];
    }
    NSLog(@"Showing icon from %@", user.iconUrl);
    UIImage *resizedImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(37, 10000) interpolationQuality:kCGInterpolationLow];
    [resizedImage setAccessibilityIdentifier:user.iconUrl];
    self.image = [self mergeImage:resizedImage withDot:[self blueCircle]];
}

- (UIImage *) blueCircle {
    static UIImage *blueCircle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(15.f, 15.f), NO, 0.0f);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSaveGState(ctx);
        
        CGRect rect = CGRectMake(0, 0, 15, 15);
        CGContextSetFillColorWithColor(ctx, [UIColor blueColor].CGColor);
        CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
        CGContextSetLineWidth(ctx, 3);
        CGContextFillEllipseInRect(ctx, rect);
        CGContextStrokeEllipseInRect(ctx, rect);
        
        CGContextRestoreGState(ctx);
        blueCircle = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
    });
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
