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
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?access_token=%@", user.iconUrl, [defaults valueForKeyPath:@"loginParameters.token"]]];
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:[NSURLRequest requestWithURL:url]];
    requestOperation.responseSerializer = [AFImageResponseSerializer serializer];
    
    __weak __typeof(self) weakSelf = self;
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        __strong __typeof (weakSelf) strongSelf = weakSelf;
        UIImage *image = responseObject;
        if (!image) {
            strongSelf.image = [strongSelf blueCircle];
            return;
        }
        
        UIImage *resizedImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(37, 10000) interpolationQuality:kCGInterpolationLow];
        [resizedImage setAccessibilityIdentifier:[url absoluteString]];
        
        strongSelf.image = [strongSelf mergeImage:resizedImage withDot:[strongSelf blueCircle]];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

    }];
    
    [requestOperation start];
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
