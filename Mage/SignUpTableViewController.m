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
#import "IdpAuthentication.h"
#import "NBAsYouTypeFormatter.h"
#import "ServerAuthentication.h"

@interface SignUpTableViewController ()
    @property (weak, nonatomic) IBOutlet UITextField *displayName;
    @property (weak, nonatomic) IBOutlet UITextField *username;
    @property (weak, nonatomic) IBOutlet UITextField *password;
    @property (weak, nonatomic) IBOutlet UITextField *passwordConfirm;
    @property (weak, nonatomic) IBOutlet UITextField *email;
    @property (weak, nonatomic) IBOutlet UITextField *phone;
@end

@implementation SignUpTableViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    if ([self.server serverHasLocalAuthenticationStrategy]) {
        ServerAuthentication *server = [self.server.authenticationModules objectForKey:@"server"];
        self.password.placeholder = [NSString stringWithFormat:@"Password (minimum %@ characters)", [server.parameters valueForKey:@"passwordMinLength"]];
        self.passwordConfirm.placeholder = [NSString stringWithFormat:@"Confirm Password (minimum %@ characters)", [server.parameters valueForKey:@"passwordMinLength"]];
    }
    
    self.tableView.alwaysBounceVertical = NO;
}

- (BOOL) textFieldShouldReturn:(UITextField *) textField {
    
    BOOL didResign = [textField resignFirstResponder];
    if (!didResign) return NO;
    
//    if ([textField isKindOfClass:[UINextField class]]) {
//        [[(UINextField *)textField nextField] becomeFirstResponder];
//    }
    
    return YES;
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    textField.textColor = [UIColor blackColor];

    if (textField == _phone) {
        NSString *textFieldString = [[textField text] stringByReplacingCharactersInRange:range withString:string];
        
        NSString *rawString = [textFieldString stringByReplacingOccurrencesOfString:@" " withString:@""];
        rawString = [rawString stringByReplacingOccurrencesOfString:@"-" withString:@""];
        
        NBAsYouTypeFormatter *aFormatter = [[NBAsYouTypeFormatter alloc] initWithRegionCode:[[NSLocale currentLocale] countryCode]];
        NSString *formattedString = [aFormatter inputString:rawString];
        
        if (aFormatter.isSuccessfulFormatting) {
            textField.text = formattedString;
        } else {
            textField.text = textFieldString;
        }
        
        return NO;
    }
    return YES;
}

- (IBAction) onSignup:(id) sender {
    NSMutableArray *requiredFields = [[NSMutableArray alloc] init];
    if ([_username.text length] == 0) {
        [self markFieldError:_username];
        [requiredFields addObject:@"Username"];
    }
    if ([self.displayName.text length] == 0) {
        [self markFieldError:self.displayName];
        [requiredFields addObject:@"Display Name"];
    }
    if ([self.password.text length] == 0) {
        [self markFieldError:self.password];
        [requiredFields addObject:@"Password"];
    }
    if ([self.passwordConfirm.text length] == 0) {
        [self markFieldError:self.passwordConfirm];
        [requiredFields addObject:@"Password Confirm"];
    }
    if ([requiredFields count] != 0) {
        [self showDialogForRequiredFields:requiredFields];
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
            @"phone": [self.phone.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
            @"password": [self.password.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
            @"passwordconfirm": [self.passwordConfirm.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
        };
        
        NSURL *url = [MageServer baseURL];
        [self signupWithParameters:parameters url:[url absoluteString]];
    }
}

- (IBAction)showPasswordChanged:(id)sender {
    [self.password setSecureTextEntry:!self.password.secureTextEntry];
    self.password.clearsOnBeginEditing = NO;
    
    // This is a hack to fix the fact that ios changes the font when you
    // enable/disable the secure text field
    self.password.font = nil;
    self.password.font = [UIFont systemFontOfSize:14];
    
    [self.passwordConfirm setSecureTextEntry:!self.passwordConfirm.secureTextEntry];
    self.passwordConfirm.clearsOnBeginEditing = NO;
    
    // This is a hack to fix the fact that ios changes the font when you
    // enable/disable the secure text field
    self.passwordConfirm.font = nil;
    self.passwordConfirm.font = [UIFont systemFontOfSize:14];
}

- (IBAction) onCancel:(id) sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) markFieldError: (UITextField *) field {
    UIColor *red = [UIColor colorWithRed:1.0 green:0 blue:0 alpha:.8];
    field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:field.placeholder attributes:@{NSForegroundColorAttributeName: red}];
    field.textColor = red;
}

- (void) showDialogForRequiredFields:(NSArray *) fields {
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:[NSString stringWithFormat:@"Missing Required Fields"]
                                 message:[NSString stringWithFormat:@"Please fill out the required fields: '%@'", [fields componentsJoinedByString:@", "]]
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
        NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error Creating Account"
                                                                       message:errResponse
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
