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
#import "Theme+UIResponder.h"

@implementation PersonTableViewCell

- (void) themeDidChange:(MageTheme)theme {
    self.name.textColor = [UIColor primaryText];
    self.backgroundColor = [UIColor background];
    self.timestamp.textColor = [UIColor secondaryText];
    self.icon.tintColor = [UIColor secondaryText];
}

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
    
    [self registerForThemeChanges];
    
    return self;
}

- (IBAction)onMapTapped:(id)sender {
    if ([self.userActionsDelegate respondsToSelector:@selector(userMapTapped:)]) {
        [self.userActionsDelegate userMapTapped:self];
    }
}

@end
