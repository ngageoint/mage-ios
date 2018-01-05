//
//  ChangePasswordViewController.m
//  MAGE
//
//  Created by Dan Barela on 12/4/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ChangePasswordViewController.h"
#import "UINextField.h"
#import "UIColor+UIColor_Mage.h"
#import <MageServer.h>
#import <ServerAuthentication.h>
#import <MageSessionManager.h>
#import "AppDelegate.h"
#import <User.h>
#import <DBZxcvbn.h>

@interface ChangePasswordViewController () <ChangePasswordDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *currentPasswordView;
@property (weak, nonatomic) IBOutlet UINextField *usernameField;
@property (weak, nonatomic) IBOutlet UINextField *currentPasswordField;
@property (weak, nonatomic) IBOutlet UISwitch *showCurrentPasswordSwitch;
@property (weak, nonatomic) IBOutlet UINextField *passwordField;
@property (weak, nonatomic) IBOutlet UINextField *confirmPasswordField;
@property (weak, nonatomic) IBOutlet UISwitch *showPasswordSwitch;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *mageServerURL;
@property (weak, nonatomic) IBOutlet UILabel *mageVersion;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIView *changePasswordView;
@property (weak, nonatomic) IBOutlet UIButton *changeButton;
@property (weak, nonatomic) IBOutlet UIView *informationView;
@property (weak, nonatomic) IBOutlet UILabel *informationLabel;
@property (weak, nonatomic) IBOutlet UILabel *passwordStrengthLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *passwordStrengthBar;
@property (weak, nonatomic) IBOutlet UILabel *mageLabel;
@property (weak, nonatomic) IBOutlet UILabel *wandLabel;

@property (strong, nonatomic) MageServer *server;
@property (nonatomic) BOOL loggedIn;
@property (strong, nonatomic) id<ChangePasswordDelegate> delegate;
@property (strong, nonatomic) DBZxcvbn *zxcvbn;

@end

@implementation ChangePasswordViewController

- (instancetype) initWithLoggedIn: (BOOL) loggedIn {
    if (self = [super initWithNibName:@"ChangePasswordView" bundle:nil]) {
        self.loggedIn = loggedIn;
        // modify this and the init method when coordinator pattern is implmeented
        self.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.zxcvbn = [[DBZxcvbn alloc] init];

    self.view.backgroundColor = [UIColor whiteColor];
    self.cancelButton.backgroundColor = [UIColor primaryColor];
    [self.cancelButton setTitleColor:[UIColor secondaryColor] forState:UIControlStateNormal];
    self.changeButton.backgroundColor = [UIColor primaryColor];
    [self.changeButton setTitleColor:[UIColor secondaryColor] forState:UIControlStateNormal];
    
    self.mageLabel.textColor = [UIColor primaryColor];
    self.wandLabel.textColor = [UIColor primaryColor];
    self.wandLabel.text = @"\U0000f0d0";
    
    self.usernameField.layer.borderColor = self.currentPasswordField.layer.borderColor = self.passwordField.layer.borderColor = self.confirmPasswordField.layer.borderColor = [[UIColor primaryColor] CGColor];
    self.usernameField.layer.borderWidth = self.currentPasswordField.layer.borderWidth = self.passwordField.layer.borderWidth = self.confirmPasswordField.layer.borderWidth = 1.0f;
    self.usernameField.layer.cornerRadius = self.currentPasswordField.layer.cornerRadius = self.confirmPasswordField.layer.cornerRadius = 5.0f;
    
    self.passwordField.delegate = self;
    
    if ([self.server serverHasLocalAuthenticationStrategy]) {
        ServerAuthentication *server = [self.server.authenticationModules objectForKey:@"server"];
        self.passwordField.placeholder = [NSString stringWithFormat:@"New Password (minimum %@ characters)", [server.parameters valueForKey:@"passwordMinLength"]];
        self.confirmPasswordField.placeholder = [NSString stringWithFormat:@"Confirm New Password (minimum %@ characters)", [server.parameters valueForKey:@"passwordMinLength"]];
    }
}

- (BOOL) textFieldShouldReturn:(UITextField *) textField {
    
    BOOL didResign = [textField resignFirstResponder];
    if (!didResign) return NO;
    
    if ([textField isKindOfClass:[UINextField class]]) {
        [[(UINextField *)textField nextField] becomeFirstResponder];
    }
    
    return YES;
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *password = [self.passwordField.text stringByReplacingCharactersInRange:range withString:string];
    NSArray *userInputs = @[self.usernameField.text, self.currentPasswordField.text];
    DBResult *passwordStrength = [self.zxcvbn passwordStrength:password userInputs:userInputs];
    [self.passwordStrengthBar setProgress:(1+passwordStrength.score)/5.0];
    switch (passwordStrength.score) {
        case 0:
            // weak
            self.passwordStrengthLabel.text = @"Weak";
            self.passwordStrengthBar.progressTintColor = self.passwordStrengthLabel.textColor = [UIColor colorWithRed:(244.0/255.0) green:(67.0/255.0) blue:(54.0/255.0) alpha:1];
            break;
        case 1:
            // fair
            self.passwordStrengthLabel.text = @"Fair";
            self.passwordStrengthBar.progressTintColor = self.passwordStrengthLabel.textColor = [UIColor colorWithRed:1.0 green:(152/255.0) blue:0.0 alpha:1];
            
            break;
        case 2:
            // good
            self.passwordStrengthLabel.text = @"Good";
            self.passwordStrengthBar.progressTintColor = self.passwordStrengthLabel.textColor = [UIColor colorWithRed:1.0 green:(193.0/255.0) blue:(7.0/255.0) alpha:1];
            
            break;
            
        case 3:
            // strong
            self.passwordStrengthLabel.text = @"Strong";
            self.passwordStrengthBar.progressTintColor = self.passwordStrengthLabel.textColor = [UIColor colorWithRed:(33.0/255.0) green:(150.0/255.0) blue:(243.0/255.0) alpha:1];
            
            break;
            
        case 4:
            // excell
            self.passwordStrengthLabel.text = @"Excellent";
            self.passwordStrengthBar.progressTintColor = self.passwordStrengthLabel.textColor = [UIColor colorWithRed:(76.0/255.0) green:(175.0/255.0) blue:(80.0/255.0) alpha:1];
            
            break;
    }
    return YES;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSURL *url = [MageServer baseURL];
    [self.mageServerURL setTitle:[url absoluteString] forState:UIControlStateNormal];
    
    self.changePasswordView.hidden = YES;
    self.informationView.hidden = NO;
    
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [self.mageVersion setText:[NSString stringWithFormat:@"v%@", versionString]];
    __weak __typeof__(self) weakSelf = self;
    [MageServer serverWithURL: url
    success:^(MageServer *mageServer) {
        weakSelf.usernameField.enabled = !weakSelf.loggedIn;
        User *user = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
        weakSelf.usernameField.text = user.username;
        weakSelf.changePasswordView.hidden = NO;
        weakSelf.informationView.hidden = YES;
    } failure:^(NSError *error) {
        NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Unable to contact the MAGE server"
                                                                       message:errResponse
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf.navigationController popViewControllerAnimated:YES];
            }
        ]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.navigationController presentViewController:alert animated:YES completion:nil];
        });
    }];
}

- (IBAction)showPasswordChanged:(id)sender {
    [self.passwordField setSecureTextEntry:!self.passwordField.secureTextEntry];
    self.passwordField.clearsOnBeginEditing = NO;
    
    // This is a hack to fix the fact that ios changes the font when you
    // enable/disable the secure text field
    self.passwordField.font = nil;
    self.passwordField.font = [UIFont systemFontOfSize:14];
    
    [self.confirmPasswordField setSecureTextEntry:!self.confirmPasswordField.secureTextEntry];
    self.confirmPasswordField.clearsOnBeginEditing = NO;
    
    // This is a hack to fix the fact that ios changes the font when you
    // enable/disable the secure text field
    self.confirmPasswordField.font = nil;
    self.confirmPasswordField.font = [UIFont systemFontOfSize:14];
}

- (IBAction)showCurrentPasswordChanged:(id)sender {
    [self.currentPasswordField setSecureTextEntry:!self.currentPasswordField.secureTextEntry];
    self.currentPasswordField.clearsOnBeginEditing = NO;
    
    // This is a hack to fix the fact that ios changes the font when you
    // enable/disable the secure text field
    self.currentPasswordField.font = nil;
    self.currentPasswordField.font = [UIFont systemFontOfSize:14];
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

- (IBAction)cancelButtonTapped:(id)sender {
    [self.delegate changePasswordCanceled];
}

- (IBAction)changeButtonTapped:(id)sender {
    NSMutableArray *requiredFields = [[NSMutableArray alloc] init];
    if ([self.usernameField.text length] == 0) {
        [self markFieldError:self.usernameField];
        [requiredFields addObject:@"Username"];
    }
    if ([self.currentPasswordField.text length] == 0) {
        [self markFieldError:self.currentPasswordField];
        [requiredFields addObject:@"Current Password"];
    }
    if ([self.passwordField.text length] == 0) {
        [self markFieldError:self.passwordField];
        [requiredFields addObject:@"New Password"];
    }
    if ([self.confirmPasswordField.text length] == 0) {
        [self markFieldError:self.confirmPasswordField];
        [requiredFields addObject:@"Confirm New Password"];
    }
    if ([requiredFields count] != 0) {
        [self showDialogForRequiredFields:requiredFields];
    } else if (![self.passwordField.text isEqualToString:self.confirmPasswordField.text]) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Passwords Do Not Match"
                                     message:@"Please update password fields to match."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }  else if ([self.passwordField.text isEqualToString:self.currentPasswordField.text]) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Password cannot be the same as the current password"
                                     message:@"Please choose a new password."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        // delegate signup
        
        // All fields validated
        
        NSDictionary *parameters = @{
                                     @"username": [self.usernameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                                     @"password": [self.currentPasswordField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                                     @"newPassword": [self.passwordField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                                     @"newPasswordConfirm": [self.confirmPasswordField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                                     };
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [MageServer baseURL], @"api/users/myself/password"]];
        [self.delegate changePasswordWithParameters:parameters atURL:url];
    }
}

// this will ultimately move to the coordinator
# pragma mark - ChangePasswordDelegate implementation

- (void) changePasswordWithParameters:(NSDictionary *)parameters atURL:(NSURL *)url {
    __weak typeof(self) weakSelf = self;
    
    MageSessionManager *manager = [MageSessionManager manager];
    NSURLSessionDataTask *task = [manager PUT_TASK:[url absoluteString] parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Password Has Been Changed"
                                                                       message:@"Your password has successfully been changed.  For security purposes you will now be redirected to the login page to log back in with your new password."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            [appDelegate logout];
        }]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf presentViewController:alert animated:YES completion:nil];
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error Changing Password"
                                                                       message:errResponse
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf presentViewController:alert animated:YES completion:nil];
        });
    }];
    
    [manager addTask:task];
}

- (void) changePasswordCanceled {
    [self dismissViewControllerAnimated:YES completion:nil];
}

# pragma

@end
