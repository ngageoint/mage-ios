//
//  AuthenticationCoordinator_Server5.m
//  MAGE
//
//  Created by William Newman on 3/17/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

#import "AuthenticationCoordinator_Server5.h"
#import "LoginViewController.h"
#import "SignUpViewController.h"
#import "IDPLoginView.h"
#import "IDPCoordinator.h"
#import "MAGE-Swift.h"
#import "MageOfflineObservationManager.h"
#import "MagicalRecord+MAGE.h"
#import "FadeTransitionSegue.h"
#import "MageSessionManager.h"
#import "AppDelegate.h"
#import "Authentication.h"

@interface AuthenticationCoordinator_Server5()

@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) LoginViewController *loginView;

@end

@implementation AuthenticationCoordinator_Server5

@dynamic navigationController;
@dynamic loginView;

- (void) signupWithParameters:(NSDictionary *) parameters completion:(void (^)(NSHTTPURLResponse *response)) completion  {
    __weak typeof(self) weakSelf = self;
    
    MageSessionManager *manager = [MageSessionManager sharedManager];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [MageServer baseURL], @"api/users"]];
    NSURLSessionDataTask *task = [manager POST_TASK:[url absoluteString] parameters:parameters progress:nil success:^(NSURLSessionTask *task, id response) {
        NSString *username = [response objectForKey:@"username"];
        NSString *displayName = [response objectForKey:@"displayName"];
        NSString *isActive = [response objectForKey:@"active"];
        NSString *msg = isActive.boolValue ? @"Your account is now active." : @"An administrator must approve your account before you can login";
      
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Account Created"
                                                                       message:[NSString stringWithFormat:@"%@ (%@) has been successfully created. %@", displayName, username, msg]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        alert.accessibilityLabel = @"Account Created";
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf.navigationController popToViewController:weakSelf.loginView animated:NO];
        }]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.navigationController presentViewController:alert animated:YES completion:nil];
        });
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error Creating Account"
                                                                       message:errResponse
                                                                preferredStyle:UIAlertControllerStyleAlert];
        alert.accessibilityLabel = @"Error Creating Account";
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.navigationController presentViewController:alert animated:YES completion:nil];
        });
    }];
    
    [manager addTask:task];

}

@end
