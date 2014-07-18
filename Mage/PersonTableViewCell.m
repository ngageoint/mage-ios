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
