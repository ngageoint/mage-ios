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

- (id) populateCellWithUser:(User *) user {
	[self.icon setImage:[PersonImage imageForUser:user constrainedWithSize:self.icon.frame.size]];
	self.name.text = user.name;
	self.username.text = user.username;
	self.timestamp.text = user.location.timestamp.timeAgoSinceNow;
	
	if ([user.currentUser boolValue]) {
		self.myself.hidden = NO;
	} else {
		self.myself.hidden = YES;
	}
	
	return self;
}

@end
