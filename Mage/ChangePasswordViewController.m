//
//  ChangePasswordViewController.m
//  MAGE
//
//  Created by Dan Barela on 12/4/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ChangePasswordViewController.h"
#import "UINextField.h"
#import "ServerAuthentication.h"
#import "MageSessionManager.h"
#import "AppDelegate.h"
#import "DBZxcvbn.h"
#import "MAGE-Swift.h"

@import MaterialComponents;

@interface ChangePasswordViewController () <ChangePasswordDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *currentPasswordView;
@property (weak, nonatomic) IBOutlet MDCFilledTextField *usernameField;
@property (weak, nonatomic) IBOutlet MDCFilledTextField *currentPasswordField;
@property (weak, nonatomic) IBOutlet UISwitch *showCurrentPasswordSwitch;
@property (weak, nonatomic) IBOutlet UILabel *showCurrentPasswordLabel;
@property (weak, nonatomic) IBOutlet UILabel *showNewPasswordLabel;
@property (weak, nonatomic) IBOutlet MDCFilledTextField *passwordField;
@property (weak, nonatomic) IBOutlet MDCFilledTextField *confirmPasswordField;
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
@property (weak, nonatomic) IBOutlet UILabel *passwordStrengthNameLabel;

@property (nonatomic) BOOL loggedIn;
@property (strong, nonatomic) id<ChangePasswordDelegate> delegate;
@property (strong, nonatomic) DBZxcvbn *zxcvbn;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@property (strong, nonatomic) NSManagedObjectContext *context;
@end

@implementation ChangePasswordViewController

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }

    self.view.backgroundColor = self.scheme.colorScheme.surfaceColor;
    [self.usernameField applyThemeWithScheme:containerScheme];
    [self.passwordField applyThemeWithScheme:containerScheme];
    [self.currentPasswordField applyThemeWithScheme:containerScheme];
    [self.confirmPasswordField applyThemeWithScheme:containerScheme];
    
    self.usernameField.leadingView.tintColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.passwordField.leadingView.tintColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.confirmPasswordField.leadingView.tintColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.currentPasswordField.leadingView.tintColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];

    self.mageLabel.textColor = self.scheme.colorScheme.primaryColorVariant;
    self.wandLabel.textColor = self.scheme.colorScheme.primaryColorVariant;

    self.showCurrentPasswordLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
    self.showNewPasswordLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
    self.passwordStrengthNameLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
    [self.mageServerURL setTitleColor:self.scheme.colorScheme.primaryColorVariant forState:UIControlStateNormal];
    self.mageVersion.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.showPasswordSwitch.onTintColor = self.scheme.colorScheme.primaryColorVariant;
    self.showCurrentPasswordSwitch.onTintColor = self.scheme.colorScheme.primaryColorVariant;
}

#pragma mark -

- (instancetype) initWithLoggedIn: (BOOL) loggedIn scheme: (id<MDCContainerScheming>)containerScheme context: (NSManagedObjectContext *) context {
    if (self = [super initWithNibName:@"ChangePasswordView" bundle:nil]) {
        self.loggedIn = loggedIn;
        // modify this and the init method when coordinator pattern is implmeented
        self.delegate = self;
        self.scheme = containerScheme;
        self.context = context;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView *meImage = [[UIImageView alloc] initWithImage:[[[UIImage systemImageNamed:@"person.fill"] aspectResizeTo:CGSizeMake(24, 24)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [self.usernameField setLeadingView:meImage];
    self.usernameField.leadingViewMode = UITextFieldViewModeAlways;
    self.usernameField.accessibilityLabel = @"Username";
    self.usernameField.placeholder = @"Username";
    self.usernameField.label.text = @"Username";
    self.usernameField.leadingAssistiveLabel.text = @" ";
    [self.usernameField sizeToFit];
    
    UIImageView *keyImage = [[UIImageView alloc] initWithImage:[[[UIImage systemImageNamed:@"key.fill"] aspectResizeTo:CGSizeMake(24, 24)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [self.passwordField setLeadingView:keyImage];
    self.passwordField.leadingViewMode = UITextFieldViewModeAlways;
    self.passwordField.accessibilityLabel = @"New Password";
    self.passwordField.placeholder = @"New Password";
    self.passwordField.label.text = @"New Password";
    self.passwordField.leadingAssistiveLabel.text = @" ";
    [self.passwordField sizeToFit];
    
    UIImageView *keyImage2 = [[UIImageView alloc] initWithImage:[[[UIImage systemImageNamed:@"key.fill"] aspectResizeTo:CGSizeMake(24, 24)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [self.confirmPasswordField setLeadingView:keyImage2];
    self.confirmPasswordField.leadingViewMode = UITextFieldViewModeAlways;
    self.confirmPasswordField.accessibilityLabel = @"Confirm New Password";
    self.confirmPasswordField.placeholder = @"Confirm New Password";
    self.confirmPasswordField.label.text = @"Confirm New Password";
    self.confirmPasswordField.leadingAssistiveLabel.text = @" ";
    [self.confirmPasswordField sizeToFit];
    
    UIImageView *keyImage3 = [[UIImageView alloc] initWithImage:[[[UIImage systemImageNamed:@"key.fill"] aspectResizeTo:CGSizeMake(24, 24)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [self.currentPasswordField setLeadingView:keyImage3];
    self.currentPasswordField.leadingViewMode = UITextFieldViewModeAlways;
    self.currentPasswordField.accessibilityLabel = @"Current Password";
    self.currentPasswordField.placeholder = @"Current Password";
    self.currentPasswordField.label.text = @"Current Password";
    self.currentPasswordField.leadingAssistiveLabel.text = @" ";
    [self.currentPasswordField sizeToFit];
    
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.changeButton setTitle:@"Change" forState:UIControlStateNormal];
        
    [self applyThemeWithContainerScheme:self.scheme];

    self.zxcvbn = [[DBZxcvbn alloc] init];
    
    self.wandLabel.text = @"\U0000f0d0";
    
    self.passwordField.delegate = self;
}

- (BOOL) textFieldShouldReturn:(UITextField *) textField {
    
    BOOL didResign = [textField resignFirstResponder];
    if (!didResign) return NO;
    
    if ([textField respondsToSelector:@selector(nextField)] && [textField nextField]) {
        [[textField nextField] becomeFirstResponder];
    }
    
    if (textField == self.confirmPasswordField) {
        [self changeButtonTapped:_changeButton];
    }
    
    return YES;
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == _passwordField) {
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
    [MageServer serverWithUrl: url
    success:^(MageServer *mageServer) {
        weakSelf.usernameField.enabled = !weakSelf.loggedIn;
        User *user = [User fetchCurrentUserWithContext:self.context];
        weakSelf.usernameField.text = user.username;
        weakSelf.changePasswordView.hidden = NO;
        weakSelf.informationView.hidden = YES;
        
        if ([mageServer serverHasLocalAuthenticationStrategy]) {
            ServerAuthentication *server = [mageServer.authenticationModules objectForKey:@"local"];

            weakSelf.passwordField.placeholder = @"New Password";
            weakSelf.confirmPasswordField.placeholder = @"Confirm New Password";
            
            if ([server.parameters valueForKey:@"passwordMinLength"] != nil) {
                weakSelf.passwordField.leadingAssistiveLabel.text = [NSString stringWithFormat:@"minimum %@ characters", [server.parameters valueForKey:@"passwordMinLength"]];
                weakSelf.confirmPasswordField.leadingAssistiveLabel.text = [NSString stringWithFormat:@"minimum %@ characters", [server.parameters valueForKey:@"passwordMinLength"]];
            }
        }
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
    
    [self.confirmPasswordField setSecureTextEntry:!self.confirmPasswordField.secureTextEntry];
    self.confirmPasswordField.clearsOnBeginEditing = NO;
}

- (IBAction)showCurrentPasswordChanged:(id)sender {
    [self.currentPasswordField setSecureTextEntry:!self.currentPasswordField.secureTextEntry];
    self.currentPasswordField.clearsOnBeginEditing = NO;
}

- (void) showDialogForRequiredFields:(NSArray *) fields {
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:[NSString stringWithFormat:@"Missing Required Fields"]
                                 message:[NSString stringWithFormat:@"Please fill out the required fields: '%@'", [fields componentsJoinedByString:@", "]]
                                 preferredStyle:UIAlertControllerStyleAlert];
    alert.accessibilityLabel = @"Missing Required Fields";
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)cancelButtonTapped:(id)sender {
    [self.delegate changePasswordCanceled];
}

- (void) clearErrors {
    self.usernameField.leadingAssistiveLabel.text = @" ";
    self.currentPasswordField.leadingAssistiveLabel.text = @" ";
    self.passwordField.leadingAssistiveLabel.text = @" ";
    self.confirmPasswordField.leadingAssistiveLabel.text = @" ";
    
    [self.usernameField applyThemeWithScheme:self.scheme];
    [self.currentPasswordField applyThemeWithScheme:self.scheme];
    [self.passwordField applyThemeWithScheme:self.scheme];
    [self.confirmPasswordField applyThemeWithScheme:self.scheme];
}

- (IBAction)changeButtonTapped:(id)sender {
    [self clearErrors];
    NSMutableArray *requiredFields = [[NSMutableArray alloc] init];
    if ([self.usernameField.text length] == 0) {
        self.usernameField.leadingAssistiveLabel.text = @"Required";
        [self.usernameField applyErrorThemeWithScheme:self.scheme];
        [requiredFields addObject:@"Username"];
    }
    if ([self.currentPasswordField.text length] == 0) {
        self.currentPasswordField.leadingAssistiveLabel.text = @"Required";
        [self.currentPasswordField applyErrorThemeWithScheme:self.scheme];
        [requiredFields addObject:@"Current Password"];
    }
    if ([self.passwordField.text length] == 0) {
        self.passwordField.leadingAssistiveLabel.text = @"Required";
        [self.passwordField applyErrorThemeWithScheme:self.scheme];
        [requiredFields addObject:@"New Password"];
    }
    if ([self.confirmPasswordField.text length] == 0) {
        self.confirmPasswordField.leadingAssistiveLabel.text = @"Required";
        [self.confirmPasswordField applyErrorThemeWithScheme:self.scheme];
        [requiredFields addObject:@"Confirm New Password"];
    }
    if ([requiredFields count] != 0) {
        [self showDialogForRequiredFields:requiredFields];
    } else if (![self.passwordField.text isEqualToString:self.confirmPasswordField.text]) {
        self.passwordField.leadingAssistiveLabel.text = @"Passwords Do Not Match";
        self.confirmPasswordField.leadingAssistiveLabel.text = @"Passwords Do Not Match";
        [self.passwordField applyErrorThemeWithScheme:self.scheme];
        [self.confirmPasswordField applyErrorThemeWithScheme:self.scheme];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Passwords Do Not Match"
                                     message:@"Please update password fields to match."
                                     preferredStyle:UIAlertControllerStyleAlert];
        alert.accessibilityLabel = @"Passwords Do Not Match";
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }  else if ([self.passwordField.text isEqualToString:self.currentPasswordField.text]) {
        self.passwordField.leadingAssistiveLabel.text = @"Password cannot be the same as the current password";
        [self.passwordField applyErrorThemeWithScheme:self.scheme];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Password cannot be the same as the current password"
                                     message:@"Please choose a new password."
                                     preferredStyle:UIAlertControllerStyleAlert];
        alert.accessibilityLabel = @"Password cannot be the same as the current password";
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
    
    MageSessionManager *manager = [MageSessionManager sharedManager];
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
