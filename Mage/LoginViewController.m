//
//  LoginViewController.m
//  MAGE
//
//  Created by William Newman on 11/4/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

@import SkyFloatingLabelTextField;

#import "LoginViewController.h"
#import "UserUtility.h"
#import "MagicalRecord+MAGE.h"
#import "MageOfflineObservationManager.h"
#import "DeviceUUID.h"
#import <GoogleSignIn/GoogleSignIn.h>
#import "Theme+UIResponder.h"

@interface LoginViewController () <UITextFieldDelegate, GIDSignInUIDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UIView *googleInstructionView;
@property (weak, nonatomic) IBOutlet UIButton *serverURL;
@property (weak, nonatomic) IBOutlet UIView *googleView;
@property (weak, nonatomic) IBOutlet UIView *dividerView;
@property (weak, nonatomic) IBOutlet UIView *localView;
@property (weak, nonatomic) IBOutlet UIView *statusView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loginIndicator;
@property (weak, nonatomic) IBOutlet SkyFloatingLabelTextField *usernameField;
@property (weak, nonatomic) IBOutlet SkyFloatingLabelTextField *passwordField;
@property (weak, nonatomic) IBOutlet UISwitch *showPassword;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UITextView *loginStatus;
@property (weak, nonatomic) IBOutlet UIButton *statusButton;
@property (weak, nonatomic) IBOutlet UILabel *mageLabel;
@property (weak, nonatomic) IBOutlet UILabel *wandLabel;
@property (weak, nonatomic) IBOutlet UIView *signupContainerView;
@property (strong, nonatomic) MageServer *server;
@property (nonatomic) BOOL allowLogin;
@property (nonatomic) BOOL loginFailure;
@property (strong, nonatomic) UIFont *passwordFont;
@property (strong, nonatomic) id<LoginDelegate> delegate;
@property (weak, nonatomic) IBOutlet GIDSignInButton *googleSignInButton;
@property (strong, nonatomic) User *user;
@property (weak, nonatomic) IBOutlet UILabel *showPasswordLabel;
@property (weak, nonatomic) IBOutlet UILabel *signupDescription;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;

@end

@implementation LoginViewController

- (instancetype) initWithMageServer: (MageServer *) server andDelegate:(id<LoginDelegate>) delegate {
    self = [super initWithNibName:@"LoginView" bundle:nil];
    if (!self) return nil;
    
    self.delegate = delegate;
    self.server = server;
    
    return self;
}

- (instancetype) initWithMageServer:(MageServer *)server andUser: (User *) user andDelegate:(id<LoginDelegate>)delegate {
    if (self = [self initWithMageServer:server andDelegate:delegate]) {
        self.user = user;
    }
    return self;
}

- (void) setMageServer: (MageServer *) server {
    self.server = server;
}

#pragma mark - Theme Changes

- (void) themeDidChange:(MageTheme)theme {
    self.view.backgroundColor = [UIColor background];
    
    self.usernameField.textColor = [UIColor primaryText];
    self.usernameField.selectedLineColor = [UIColor brand];
    self.usernameField.selectedTitleColor = [UIColor brand];
    self.usernameField.placeholderColor = [UIColor secondaryText];
    self.usernameField.lineColor = [UIColor secondaryText];
    self.usernameField.titleColor = [UIColor secondaryText];
    self.usernameField.errorColor = [UIColor redColor];
    self.usernameField.errorColor = [[UIColor redColor] colorWithAlphaComponent:.65f];
    
    self.passwordField.textColor = [UIColor primaryText];
    self.passwordField.selectedLineColor = [UIColor brand];
    self.passwordField.selectedTitleColor = [UIColor brand];
    self.passwordField.placeholderColor = [UIColor secondaryText];
    self.passwordField.lineColor = [UIColor secondaryText];
    self.passwordField.titleColor = [UIColor secondaryText];
    self.passwordField.errorColor = [UIColor redColor];
    self.passwordField.errorColor = [[UIColor redColor] colorWithAlphaComponent:.65f];

    self.mageLabel.textColor = [UIColor brand];
    self.wandLabel.textColor = [UIColor brand];
    self.loginButton.backgroundColor = [UIColor themedButton];
    self.showPasswordLabel.textColor = [UIColor secondaryText];
    self.signupDescription.textColor = [UIColor secondaryText];
    self.loginStatus.textColor = [UIColor secondaryText];
    [self.serverURL setTitleColor:[UIColor flatButton] forState:UIControlStateNormal];
    self.versionLabel.textColor = [UIColor secondaryText];
    [self.signupButton setTitleColor:[UIColor flatButton] forState:UIControlStateNormal];
    self.showPassword.onTintColor = [UIColor themedButton];
}

#pragma mark -

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self registerForThemeChanges];
    
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    tap.delegate = self;
    
    [self.view addGestureRecognizer:tap];
    self.wandLabel.text = @"\U0000f0d0";
    
    self.passwordFont = self.passwordField.font;
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (touch.view == self.googleSignInButton) return false;
    return true;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.googleSignInButton.style = kGIDSignInButtonStyleWide;
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
    
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [self.versionLabel setText:[NSString stringWithFormat:@"v%@", versionString]];
    
    NSURL *url = [MageServer baseURL];
    [self.serverURL setTitle:[url absoluteString] forState:UIControlStateNormal];
    
    [self resetLogin:YES];
    [self.passwordField setDelegate:self];
    
    if (self.user) {
        self.usernameField.enabled = NO;
        self.usernameField.backgroundColor = [UIColor lightGrayColor];
        self.usernameField.text = self.user.username;
        self.serverURL.enabled = NO;
        self.signupContainerView.hidden = YES;
    }
}

- (void) authenticationWasSuccessful {
    [self resetLogin:YES];
    [self endLogin];
}

- (void) authenticationHadFailure: (NSString *) errorString {
    self.statusView.hidden = NO;
    
    self.loginStatus.text = [errorString isEqualToString:@"Unauthorized"] ? @"The username or password you entered is incorrect" : errorString;
    self.usernameField.errorMessage = @"Username";
    self.passwordField.errorMessage = @"Password";
    
    self.loginFailure = YES;
    [self endLogin];
}

- (void) registrationWasSuccessful {
    [self resetLogin:NO];
    [self endLogin];
}

- (void) unableToAuthenticate {
    [self endLogin];
}

- (void) resetLogin: (BOOL) clear {
    self.usernameField.errorMessage = nil;
    self.passwordField.errorMessage = nil;
    
    self.loginFailure = NO;
    self.statusView.hidden = YES;
    
    if (clear) {
        [self.usernameField setText:@""];
        [self.passwordField setText:@""];
    }
}

- (void) endLogin {
    [self.loginButton setEnabled:YES];
    [self.loginIndicator stopAnimating];
    [self.usernameField setEnabled:YES];
    [self.passwordField setEnabled:YES];
    [self.showPassword setEnabled:YES];
}

- (void) startLogin {
    [self.loginButton setEnabled:NO];
    [self.loginIndicator startAnimating];
    [self.usernameField setEnabled:NO];
    [self.passwordField setEnabled:NO];
    [self.showPassword setEnabled:NO];
}

- (void) verifyLogin {
    if (!self.allowLogin) return;
    
    [self startLogin];
    NSUUID *deviceUUID = [DeviceUUID retrieveDeviceUUID];
    NSString *uidString = deviceUUID.UUIDString;
    NSLog(@"uid: %@", uidString);
    
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey: @"CFBundleShortVersionString"];
    NSString *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                self.usernameField.text, @"username",
                                self.passwordField.text, @"password",
                                uidString, @"uid",
                                [NSString stringWithFormat:@"%@-%@", appVersion, buildNumber], @"appVersion",
                                nil];
    
    __weak __typeof__(self) weakSelf = self;
    [self.delegate loginWithParameters:parameters complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
        if (authenticationStatus == AUTHENTICATION_SUCCESS) {
            [weakSelf authenticationWasSuccessful];
        } else if (authenticationStatus == REGISTRATION_SUCCESS) {
            [weakSelf registrationWasSuccessful];
        } else if (authenticationStatus == UNABLE_TO_AUTHENTICATE) {
            [weakSelf unableToAuthenticate];
        } else {
            [weakSelf authenticationHadFailure:errorString];
        }
    }];
}

- (IBAction)googleSignInTapped:(id)sender {
    
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
    
    self.usernameField.textColor = self.passwordField.textColor = [UIColor primaryText];
    
    return NO;
}

- (BOOL) textFieldShouldReturn:(UITextField *) textField {
    if (textField == self.passwordField) {
        [self localLoginButtonPress:textField];
    }
    return YES;
}

- (IBAction)signupTapped:(id)sender {
    [self.delegate createAccount];
}

- (void) setupAuthentication {
    BOOL localAuthentication = [self.server serverHasLocalAuthenticationStrategy];
    BOOL googleAuthentication = [self.server serverHasGoogleAuthenticationStrategy];
    
    if (googleAuthentication) {
        [GIDSignIn sharedInstance].uiDelegate = self;
    }
    
    self.googleView.hidden = self.googleInstructionView.hidden = !googleAuthentication;
    self.localView.hidden = !localAuthentication;
    self.dividerView.hidden = !(googleAuthentication && localAuthentication);
    self.statusView.hidden = !(!self.allowLogin || self.loginFailure);
}

@end
