//
//  LoginViewController.m
//  MAGE
//
//  Created by William Newman on 11/4/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "LoginViewController.h"
#import <UserUtility.h>
#import "MagicalRecord+MAGE.h"
#import "MageOfflineObservationManager.h"
#import "DeviceUUID.h"

@interface LoginViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UIButton *serverURL;
@property (weak, nonatomic) IBOutlet UIView *googleView;
@property (weak, nonatomic) IBOutlet UIView *dividerView;
@property (weak, nonatomic) IBOutlet UIView *localView;
@property (weak, nonatomic) IBOutlet UIView *statusView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loginIndicator;
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UISwitch *showPassword;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UITextView *loginStatus;
@property (weak, nonatomic) IBOutlet UIButton *statusButton;
@property (strong, nonatomic) MageServer *server;
@property (nonatomic) BOOL allowLogin;
@property (nonatomic) BOOL loginFailure;
@property (strong, nonatomic) UIFont *passwordFont;
@property (strong, nonatomic) id<LoginDelegate> delegate;

@end

@implementation LoginViewController

- (instancetype) initWithMageServer: (MageServer *) server andDelegate:(id<LoginDelegate>) delegate {
    self = [super initWithNibName:@"LoginView" bundle:nil];
    if (!self) return nil;
    
    self.delegate = delegate;
    self.server = server;
    
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    if (self.server) {
        self.statusView.hidden = YES;
        [self.usernameField setEnabled:YES];
        [self.passwordField setEnabled:YES];
        self.allowLogin = YES;
    } else {
        self.allowLogin = NO;
        self.statusView.hidden = NO;
    }

    
    [self setupAuthentication];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    self.passwordFont = self.passwordField.font;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [self.versionLabel setText:[NSString stringWithFormat:@"v%@", versionString]];
    
    NSURL *url = [MageServer baseURL];
    [self.serverURL setTitle:[url absoluteString] forState:UIControlStateNormal];
    
    [self resetLogin:YES];
    [self.passwordField setDelegate:self];
}

- (void) authenticationWasSuccessful {
    [self resetLogin:YES];
    [self endLogin];
}

- (void) authenticationHadFailure {
    self.statusView.hidden = NO;
    
    self.loginStatus.text = @"The username or password you entered is incorrect";
    self.usernameField.textColor = [[UIColor redColor] colorWithAlphaComponent:.65f];
    self.passwordField.textColor = [[UIColor redColor] colorWithAlphaComponent:.65f];
    
    self.loginFailure = YES;
    [self endLogin];
}

- (void) registrationWasSuccessful {
    [self resetLogin:NO];
    [self endLogin];
}

- (void) resetLogin: (BOOL) clear {
    
    self.loginFailure = NO;
    self.statusView.hidden = YES;
    self.usernameField.textColor = [UIColor blackColor];
    self.passwordField.textColor = [UIColor blackColor];
    
    if (clear) {
        [self.usernameField setText:@""];
        [self.passwordField setText:@""];
    }
}

- (void) endLogin {
    [self.loginButton setEnabled:YES];
    [self.loginIndicator stopAnimating];
    [self.usernameField setEnabled:YES];
    [self.usernameField setBackgroundColor:[UIColor whiteColor]];
    [self.passwordField setEnabled:YES];
    [self.passwordField setBackgroundColor:[UIColor whiteColor]];
    [self.showPassword setEnabled:YES];
}

- (void) startLogin {
    [self.loginButton setEnabled:NO];
    [self.loginIndicator startAnimating];
    [self.usernameField setEnabled:NO];
    [self.usernameField setBackgroundColor:[UIColor lightGrayColor]];
    [self.passwordField setEnabled:NO];
    [self.passwordField setBackgroundColor:[UIColor lightGrayColor]];
    [self.showPassword setEnabled:NO];
}

- (void) verifyLogin {
    if (!self.allowLogin) return;
    
    [self startLogin];
    NSUUID *deviceUUID = [DeviceUUID retrieveDeviceUUID];
    NSString *uidString = deviceUUID.UUIDString;
    NSLog(@"uid: %@", uidString);
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                self.usernameField.text, @"username",
                                self.passwordField.text, @"password",
                                uidString, @"uid",
                                nil];
    
    __weak __typeof__(self) weakSelf = self;
    [self.delegate loginWithParameters:parameters complete:^(AuthenticationStatus authenticationStatus) {
        if (authenticationStatus == AUTHENTICATION_SUCCESS) {
            [weakSelf authenticationWasSuccessful];
        } else if (authenticationStatus == REGISTRATION_SUCCESS) {
            [weakSelf registrationWasSuccessful];
        } else {
            [weakSelf authenticationHadFailure];
        }
    }];
    
}

- (BOOL) changeTextViewFocus: (id)sender {
    if ([[self.usernameField text] isEqualToString:@""]) {
        [self.usernameField becomeFirstResponder];
        return YES;
    } else if ([[self.passwordField text] isEqualToString:@""]) {
        [self.passwordField becomeFirstResponder];
        return YES;
    } else {
        return NO;
    }
}

//  When we are done editing on the keyboard
- (IBAction)resignAndLogin:(id) sender {
    if (![self changeTextViewFocus: sender]) {
        [sender resignFirstResponder];
        [self verifyLogin];
    }
}

- (IBAction)localLoginButtonPress:(id)sender {
    if (![self changeTextViewFocus: sender]) {
        [sender resignFirstResponder];
        if ([self.usernameField isFirstResponder]) {
            [self.usernameField resignFirstResponder];
        } else if([self.passwordField isFirstResponder]) {
            [self.passwordField resignFirstResponder];
        }
        
        [self verifyLogin];
    }
}

- (IBAction)serverURLTapped:(id)sender {
    [self.delegate changeServerURL];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (IBAction)showPasswordSwitchAction:(id)sender {
    [self.passwordField setSecureTextEntry:!self.passwordField.secureTextEntry];
    self.passwordField.clearsOnBeginEditing = NO;
    
    // This is a hack to fix the fact that ios changes the font when you
    // enable/disable the secure text field
    self.passwordField.font = nil;
    self.passwordField.font = [UIFont systemFontOfSize:14];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *updatedString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    // if we override this we need to check if its \n
    if ([string isEqualToString:@"\n"]) {
        [textField resignFirstResponder];
    } else {
        textField.text = updatedString;
    }
    
    return NO;
}

- (BOOL) textFieldShouldReturn:(UITextField *) textField {
    return YES;
}

//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([[segue identifier] isEqualToString:@"SignUpSegue"]) {
//        SignUpTableViewController *signUpViewController = [segue destinationViewController];
//        [signUpViewController setServer:self.server];
//    } else if ([[segue identifier] isEqualToString:@"OAuthSegue"]) {
//        OAuthViewController *viewController = [segue destinationViewController];
//        NSString *url = [NSString stringWithFormat:@"%@/%@", [[MageServer baseURL] absoluteString], @"auth/google/signin"];
//        [viewController setUrl:url];
//        [viewController setAuthenticationType:GOOGLE];
//        [viewController setRequestType:SIGNIN];
//    }
//}

- (void) setupAuthentication {
    BOOL localAuthentication = [self.server serverHasLocalAuthenticationStrategy];
    BOOL googleAuthentication = [self.server serverHasGoogleAuthenticationStrategy];
    
    self.googleView.hidden = !googleAuthentication;
    self.localView.hidden = !localAuthentication;
    self.dividerView.hidden = !(googleAuthentication && localAuthentication);
    self.statusView.hidden = !(!self.allowLogin || self.loginFailure);
}

@end
