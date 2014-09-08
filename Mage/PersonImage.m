//
//  PersonIcon.m
//  Mage
//
//  Created by Billy Newman on 7/14/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "PersonImage.h"

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
    
    UIImage *image = [UIImage imageNamed:imageName];
    [image setAccessibilityIdentifier:imageName];
    
	return image;
}

@end