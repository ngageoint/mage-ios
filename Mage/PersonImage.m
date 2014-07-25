//
//  PersonIcon.m
//  Mage
//
//  Created by Billy Newman on 7/14/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "PersonImage.h"

@implementation PersonImage

+ (NSString *) imageNameForTimestamp:(NSDate *) timestamp {
	if (!timestamp) return @"person";
	
	NSString *format = @"person_%@";
	NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:timestamp];
	if (interval <= 600) {
		return [NSString stringWithFormat:format, @"low"];
	} else if (interval <= 1200) {
		return [NSString stringWithFormat:format, @"medium"];
	} else {
		return [NSString stringWithFormat:format, @"high"];
	}
}
	
+ (UIImage *) imageForTimestamp:(NSDate *) timestamp {
	return [UIImage imageNamed:[PersonImage imageNameForTimestamp:timestamp]];
}

@end