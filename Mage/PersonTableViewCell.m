//
//  PersonTableViewCell.m
//  Mage
//
//  Created by Billy Newman on 7/14/14.
//

#import "PersonTableViewCell.h"
#import "User+helper.h"
#import "NSDate+DateTools.h"
#import "PersonImage.h"

@implementation PersonTableViewCell

- (void) awakeFromNib {
    UIView *view = [[UIView alloc] initWithFrame:self.frame];
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = view.bounds;
	gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor whiteColor] CGColor], (id)[[UIColor colorWithRed:207/255.0 green:207/255.0 blue:207/255.0 alpha:51/255.0] CGColor], nil];

    [self.layer insertSublayer:gradient atIndex:0];
}

- (id) populateCellWithLocation:(Location *) location {
	self.location = location;
	
	User *user = location.user;
	NSDate *date = location.timestamp;
	
	[self.icon setImage:[PersonImage imageForTimestamp:date]];
	self.name.text = user.name;
	self.username.text = user.username;
	self.timestamp.text = date.timeAgoSinceNow;
	
	return self;
}

@end
