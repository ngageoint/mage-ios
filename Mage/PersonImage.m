//
//  PersonIcon.m
//  Mage
//
//  Created by Billy Newman on 7/14/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "PersonImage.h"
#import <User.h>
#import "UIImage+Resize.h"

@implementation PersonImage

+ (UIImage *) imageForUser: (User *) user constrainedWithSize: (CGSize) size {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    if ([user iconUrl] != nil) {
        NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?access_token=%@", user.iconUrl, [defaults valueForKeyPath:@"loginParameters.token"]]]];
        UIImage *image = [UIImage imageWithData:data];
        
        UIImage *resizedImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:size interpolationQuality:kCGInterpolationLow];
        [resizedImage setAccessibilityIdentifier:user.iconUrl];
        return resizedImage;
    }
    return nil;
}

+ (UIImage *) imageForLocation:(Location *) location {
    UIImage *personImage = [self imageForUser:location.user constrainedWithSize:CGSizeMake(37, 10000)];
    return [PersonImage mergeImage:personImage withDot:[PersonImage blueCircle]];
}

+ (UIImage *)blueCircle {
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

+ (UIImage *)mergeImage: (UIImage *)image withDot: (UIImage *)dot {
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