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
#import <AFNetworking/UIImageView+AFNetworking.h>

@implementation PersonTableViewCell

- (id) populateCellWithUser:(User *) user {    
    if ([user avatarUrl] != nil) {
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
        self.icon.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", documentsDirectory, user.avatarUrl]];
    } else {
        self.icon.image = nil;
    }
    
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
