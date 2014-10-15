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
	
+ (UIImage *) imageForLocation:(Location *) location {
    NSString *imageName = nil;
    
    if (!location || !location.timestamp) imageName = @"person";
	
	NSString *format = @"person_%@";
	NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:location.timestamp];
	if (interval <= 600) {
		imageName = [NSString stringWithFormat:format, @"low"];
	} else if (interval <= 1200) {
		imageName = [NSString stringWithFormat:format, @"medium"];
	} else {
		imageName = [NSString stringWithFormat:format, @"high"];
	}
    
//    UIImage *image = [UIImage imageNamed:imageName];
    
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?access_token=%@", location.user.iconUrl, [defaults objectForKey:@"token"]]]];
    UIImage *image = [UIImage imageWithData:data];
    [image setAccessibilityIdentifier:location.user.iconUrl];
    UIImage *resizedImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(37, 10000) interpolationQuality:kCGInterpolationLow];
    
	return resizedImage;
}

@end