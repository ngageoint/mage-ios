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
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    if ([user iconUrl] != nil) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?access_token=%@", user.avatarUrl, [defaults valueForKeyPath:@"loginParameters.token"]]];
        [self.icon setImageWithURLRequest:[NSURLRequest requestWithURL:url] placeholderImage:nil success:nil failure:nil];
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
