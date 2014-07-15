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

- (void) populateCellWithLocation:(Location *) location {
	User *user = location.user;
	NSDate *date = location.timestamp;
	
	[self.icon setImage:[PersonImage imageForTimestamp:date]];
	self.name.text = user.name;
	self.email.text = user.email;
	self.timestamp.text = date.timeAgoSinceNow;
}


@end
