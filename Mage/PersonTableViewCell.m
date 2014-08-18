//
//  PersonTableViewCell.m
//  Mage
//
//  Created by Billy Newman on 7/14/14.
//

#import "PersonTableViewCell.h"
#import "User+helper.h"
#import "Location+helper.h"
#import "NSDate+DateTools.h"
#import "PersonImage.h"

@implementation PersonTableViewCell

- (void) layoutSubviews {
    UIView *view = [[UIView alloc] initWithFrame:self.bounds];
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = view.bounds;
	gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor whiteColor] CGColor], (id)[[UIColor colorWithRed:207/255.0 green:207/255.0 blue:207/255.0 alpha:51/255.0] CGColor], nil];
	
	[self setBackgroundView:[[UIView alloc] init]];
	[self.backgroundView.layer insertSublayer:gradient atIndex:0];
	
	[super layoutSubviews];
}

- (id) populateCellWithUser:(User *) user {
	NSDate *date = user.location.timestamp;
	
	[self.icon setImage:[PersonImage imageForTimestamp:date]];
	self.name.text = user.name;
	self.username.text = user.username;
	self.timestamp.text = date.timeAgoSinceNow;
	
	if ([user.currentUser boolValue]) {
		self.myself.hidden = NO;
	} else {
		self.myself.hidden = YES;
	}
	
	return self;
}

@end
