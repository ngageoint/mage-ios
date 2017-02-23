//
//  SignUpViewController.m
//  Mage
//
//

#import "SignUpTableViewController.h"
#import "UINextField.h"
#import "MageSessionManager.h"
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
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Passwords Do Not Match"
                                     message:@"Please update password fields to match."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
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

- (IBAction) onCancel:(id) sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) showDialogForRequiredField:(NSString *) field {
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:[NSString stringWithFormat:@"%@ Is Required", field]
                                 message:[NSString stringWithFormat:@"Please fill out the '%@' field.", field]
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) signupWithParameters:(NSDictionary *) parameters url:(NSString *) baseUrl {
    __weak typeof(self) weakSelf = self;
    NSString *url = [NSString stringWithFormat:@"%@/%@", baseUrl, @"api/users"];
    
    MageSessionManager *manager = [MageSessionManager manager];
    NSURLSessionDataTask *task = [manager POST_TASK:url parameters:parameters progress:nil success:^(NSURLSessionTask *task, id response) {
        NSString *username = [response objectForKey:@"username"];
        NSString *displayName = [response objectForKey:@"displayName"];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Account Created"
                                                                       message:[NSString stringWithFormat:@"%@ (%@) has been successfully created.  An administrator must approve your account before you can login", displayName, username]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        }]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf presentViewController:alert animated:YES completion:nil];
        });
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error Creating Account"
                                                                       message:operation.error.localizedDescription
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf presentViewController:alert animated:YES completion:nil];
        });
    }];
    
    [manager addTask:task];
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
