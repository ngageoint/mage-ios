//
//  SignUpViewController.m
//  Mage
//
//

#import "SignUpTableViewController.h"
#import "UINextField.h"
#import "HttpManager.h"
#import "MageServer.h"
#import "OAuthViewController.h"
#import "OAuthAuthentication.h"

@interface SignUpTableViewController ()
    @property (weak, nonatomic) IBOutlet UITextField *displayName;
    @property (weak, nonatomic) IBOutlet UITextField *username;
    @property (weak, nonatomic) IBOutlet UITextField *password;
    @property (weak, nonatomic) IBOutlet UITextField *passwordConfirm;
    @property (weak, nonatomic) IBOutlet UITextField *email;
@end

@implementation SignUpTableViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.alwaysBounceVertical = NO;
}

- (BOOL) textFieldShouldReturn:(UITextField *) textField {
    
    BOOL didResign = [textField resignFirstResponder];
    if (!didResign) return NO;
    
    if ([textField isKindOfClass:[UINextField class]]) {
        [[(UINextField *)textField nextField] becomeFirstResponder];
    }
    
    return YES;
    
}

- (IBAction) onSignup:(id) sender {
    if ([_username.text length] == 0) {
        [self showDialogForRequiredField:@"Username"];
    } else if ([self.displayName.text length] == 0) {
        [self showDialogForRequiredField:@"Display Name"];
    } else if ([self.password.text length] == 0) {
        [self showDialogForRequiredField:@"Password"];
    } else if ([self.passwordConfirm.text length] == 0) {
        [self showDialogForRequiredField:@"Password Confirm"];
    } else if (![self.password.text isEqualToString:self.passwordConfirm.text]) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Error"
                              message:@"Passwords do not match"
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        
        [alert show];
    } else {
        // All fields validated
        NSDictionary *parameters = @{
            @"username": [self.username.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
            @"displayName": [self.displayName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
            @"email": [self.email.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
            @"password": [self.password.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
            @"passwordconfirm": [self.passwordConfirm.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
        };
        
        NSURL *url = [MageServer baseURL];
        [self signupWithParameters:parameters url:[url absoluteString]];
    }
}

- (void) showDialogForRequiredField:(NSString *) field {
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Missing required field"
                          message:[NSString stringWithFormat:@"'%@' is required.", field]
                          delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
	
	[alert show];
}

- (void) signupWithParameters:(NSDictionary *) parameters url:(NSString *) baseUrl {
    NSString *url = [NSString stringWithFormat:@"%@/%@", baseUrl, @"api/users"];
    [[HttpManager singleton].manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
        NSString *username = [response objectForKey:@"username"];
        NSString *displayName = [response objectForKey:@"displayName"];
		
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"User Creation Success"
                              message:[NSString stringWithFormat:@"%@ (%@) has been successfully created.  An administrator must approve your account before you can login", displayName, username]
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        
        [alert show];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"User Creation Failed"
                              message:[operation responseString]
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        
        [alert show];
    }];
}

- (void)alertView:(UIAlertView *) alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self performSegueWithIdentifier:@"unwindToInitial" sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([[segue identifier] isEqualToString:@"OAuthSegue"]) {
        OAuthViewController *viewController = [segue destinationViewController];
        NSString *url = [NSString stringWithFormat:@"%@/%@", [[MageServer baseURL] absoluteString], @"auth/google/signup"];
        [viewController setUrl:url];
        [viewController setAuthenticationType:GOOGLE];
        [viewController setRequestType:SIGNUP];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    BOOL localAuthentication = [self.server serverHasLocalAuthenticationStrategy];
    BOOL googleAuthentication = [self.server serverHasGoogleAuthenticationStrategy];
    
    switch (section) {
        case 0:
            return googleAuthentication ? 1 : 0;
        case 1:
            return googleAuthentication && localAuthentication ? 1 : 0;
        case 2:
            return localAuthentication ? 1 : 0;
        default:
            return localAuthentication || googleAuthentication ? 1 : 0;
    }
}


@end
