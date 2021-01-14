//
//  PersonTableViewCell.m
//  Mage
//
//

@import DateTools;

#import "PersonTableViewCell.h"
#import "User.h"
#import "Location.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

@implementation PersonTableViewCell

- (id) populateCellWithUser:(User *) user {
    self.user = user;
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString* avatarFile = [documentsDirectory stringByAppendingPathComponent:user.avatarUrl];
    if(user.avatarUrl && [[NSFileManager defaultManager] fileExistsAtPath:avatarFile]) {
        self.icon.image = [UIImage imageWithContentsOfFile:avatarFile];
    } else {
        self.icon.image = [UIImage imageNamed:@"avatar_small"];
    }
    
    self.name.text = user.name;
    self.timestamp.text = user.location.timestamp.timeAgoSinceNow;
        
    return self;
}

- (IBAction)onMapTapped:(id)sender {
    if ([self.userActionsDelegate respondsToSelector:@selector(userMapTapped:)]) {
        [self.userActionsDelegate userMapTapped:self];
    }
}

@end
