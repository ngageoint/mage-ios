//
//  PersonTableViewCell.m
//  Mage
//
//

#import "PersonTableViewCell.h"
#import "User.h"
#import "Location.h"
#import "NSDate+DateTools.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

@implementation PersonTableViewCell

- (id) populateCellWithUser:(User *) user {    
    if ([user avatarUrl] != nil) {
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
        self.icon.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", documentsDirectory, user.avatarUrl]];
    } else {
        self.icon.image = [UIImage imageNamed:@"avatar"];
    }
    
    self.name.text = user.name;
    self.timestamp.text = user.location.timestamp.timeAgoSinceNow;
    
    return self;
}

@end
