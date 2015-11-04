//
//  LoginDataSource.m
//  MAGE
//
//  Created by William Newman on 10/23/15.
//

#import "LoginDataSource.h"
#import "LocalAuthenticationTableViewCell.h"
#import "LoginStatusTableViewCell.h"

@interface LoginDataSource ()
@property (strong, nonatomic) NSMutableArray *tableViewCells;
@end

@implementation LoginDataSource

- (id) init {
    
    if (self = [super init]) {
        self.tableViewCells = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void) setAuthenticationWithServer: (MageServer *) server {
    [self.tableViewCells removeAllObjects];
    
    BOOL localAuthentication = [server serverHasLocalAuthenticationStrategy];
    BOOL googleAuthentication = [server serverHasGoogleAuthenticationStrategy];
    
    if (googleAuthentication) {
        [self.tableViewCells addObject:@"googleCell"];
    }
    
    if (localAuthentication && googleAuthentication) {
        [self.tableViewCells addObject:@"dividerCell"];
    }
    
    if (localAuthentication) {
        [self.tableViewCells addObject:@"localCell"];
    }
    
    [self.tableViewCells addObject:@"signUpCell"];
    [self.tableViewCells addObject:@"statusCell"];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableViewCells.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *tableCellIdentifier = [self.tableViewCells objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableCellIdentifier];
    
    if ([cell isKindOfClass:[LocalAuthenticationTableViewCell class]]) {
        LocalAuthenticationTableViewCell *localAuthenticationTableViewCell = (LocalAuthenticationTableViewCell *) cell;
        self.usernameField = localAuthenticationTableViewCell.usernameField;
        self.passwordField = localAuthenticationTableViewCell.passwordField;
        self.showPassword = localAuthenticationTableViewCell.showPassword;
        self.loginButton = localAuthenticationTableViewCell.loginButton;
    }
    
    if ([cell isKindOfClass:[LoginStatusTableViewCell class]]) {
        LoginStatusTableViewCell *loginStatusTableViewCell = (LoginStatusTableViewCell *) cell;
        self.loginStatus = loginStatusTableViewCell.loginStatus;
    }
    
    return cell;
}

@end
