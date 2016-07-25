//
//  LoginViewController.m
//  Mage
//
//

#import "LoginTableViewController.h"
#import "LocalAuthentication.h"
#import "User.h"
#import "Observation.h"

#import <Location.h>
#import <Layer.h>
#import <Form.h>
#import <Mage.h>
#import "AppDelegate.h"
#import <HttpManager.h>
#import "MageRootViewController.h"
#import <UserUtility.h>
#import "DeviceUUID.h"
#import "MageServer.h"
#import "Observations.h"
#import "MagicalRecord+MAGE.h"
#import "SignUpTableViewController.h"
#import "OAuthViewController.h"
#import "OAuthAuthentication.h"
#import "UINextField.h"

@interface LoginTableViewController ()
    @property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loginIndicator;
    @property (weak, nonatomic) IBOutlet UITextField *usernameField;
    @property (weak, nonatomic) IBOutlet UITextField *passwordField;
    @property (weak, nonatomic) IBOutlet UISwitch *showPassword;
    @property (weak, nonatomic) IBOutlet UIButton *loginButton;
    @property (weak, nonatomic) IBOutlet UITextView *loginStatus;
    @property (weak, nonatomic) IBOutlet UIButton *statusButton;
    @property (strong, nonatomic) MageServer *server;
    @property (nonatomic) BOOL allowLogin;
    @property (strong, nonatomic) UIFont *passwordFont;
@end

@implementation LoginTableViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.alwaysBounceVertical = NO;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    self.passwordFont = self.passwordField.font;
}

//  When the view reappears after logout we want to wipe the username and password fields
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.usernameField setText:@""];
    [self.passwordField setText:@""];
    [self.passwordField setDelegate:self];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSURL *url = [MageServer baseURL];
    if ([@"" isEqualToString:url.absoluteString]) {
        // TODO segue to URL picker
        return;
    } else {
        [self initMageServerWithURL:url];
        self.allowLogin = YES;
    }
}

- (void) authenticationWasSuccessful {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults objectForKey:@"showDisclaimer"] == nil || ![[defaults objectForKey:@"showDisclaimer"] boolValue]) {
        [[UserUtility singleton ] acceptConsent];
        [self performSegueWithIdentifier:@"SkipDisclaimerSegue" sender:nil];
    } else {
        [self performSegueWithIdentifier:@"LoginSegue" sender:nil];
    }
    
    self.usernameField.textColor = [UIColor blackColor];
    self.passwordField.textColor = [UIColor blackColor];
    
    self.usernameField.text = @"";
    self.passwordField.text = @"";
    
    self.loginStatus.hidden = YES;
    self.statusButton.hidden = YES;
    
    [self resetLogin];
}

- (void) authenticationHadFailure {
    self.statusButton.hidden = NO;
    self.loginStatus.hidden = NO;
    self.loginStatus.text = @"The username or password you entered is incorrect";
    self.usernameField.textColor = [[UIColor redColor] colorWithAlphaComponent:.65f];
    self.passwordField.textColor = [[UIColor redColor] colorWithAlphaComponent:.65f];

    [self resetLogin];
}

- (void) registrationWasSuccessful {
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Registration Sent"
                          message:@"Your device has been registered.  \nAn administrator has been notified to approve this device."
                          delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
	
	[alert show];
    [self resetLogin];
}

- (void) resetLogin {
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
    
    if (self.server.reachabilityManager.reachable && ([self userChanged])) {
        [MagicalRecord deleteAndSetupMageCoreDataStack];
    }
    
	// setup authentication
    [self startLogin];
    NSUUID *deviceUUID = [DeviceUUID retrieveDeviceUUID];
	NSString *uidString = deviceUUID.UUIDString;
    NSLog(@"uid: %@", uidString);
	NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
														 self.usernameField.text, @"username",
														 self.passwordField.text, @"password",
														 uidString, @"uid",
														 nil];
    
    id<Authentication> authenticationModule = [self.server.authenticationModules objectForKey:[Authentication authenticationTypeToString:SERVER]];
    if (!authenticationModule) {
        authenticationModule = [self.server.authenticationModules objectForKey:[Authentication authenticationTypeToString:LOCAL]];
    }
    
    __weak __typeof__(self) weakSelf = self;
    [authenticationModule loginWithParameters:parameters complete:^(AuthenticationStatus authenticationStatus) {
        if (authenticationStatus == AUTHENTICATION_SUCCESS) {
            [weakSelf authenticationWasSuccessful];
        } else if (authenticationStatus == REGISTRATION_SUCCESS) {
            [weakSelf registrationWasSuccessful];
        } else {
            [weakSelf authenticationHadFailure];
        }
    }];
}

- (BOOL) userChanged {
    User *currentUser = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
    return (currentUser != nil && ![currentUser.username isEqualToString:self.usernameField.text]);
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

- (void) initMageServerWithURL:(NSURL *) url {
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicator.center = self.view.center;
    [activityIndicator startAnimating];
    [self.view addSubview:activityIndicator];
    [activityIndicator setHidesWhenStopped:YES];
    
    __weak __typeof__(self) weakSelf = self;
    [MageServer serverWithURL:url success:^(MageServer *mageServer) {
        weakSelf.server = mageServer;
        
        weakSelf.loginStatus.hidden = YES;
        weakSelf.statusButton.hidden = YES;
        [weakSelf.usernameField setEnabled:YES];
        [weakSelf.passwordField setEnabled:YES];
        weakSelf.allowLogin = YES;
        
        [activityIndicator stopAnimating];
        
        [self setupAuthentication];
    } failure:^(NSError *error) {
        [activityIndicator stopAnimating];
        
        weakSelf.allowLogin = NO;
        weakSelf.loginStatus.hidden = NO;
        weakSelf.statusButton.hidden = NO;
        weakSelf.loginStatus.text = error.localizedDescription;
        
        [self setupAuthentication];
    }];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"SignUpSegue"]) {
        SignUpTableViewController *signUpViewController = [segue destinationViewController];
        [signUpViewController setServer:self.server];
    } else if ([[segue identifier] isEqualToString:@"OAuthSegue"]) {
        OAuthViewController *viewController = [segue destinationViewController];
        NSString *url = [NSString stringWithFormat:@"%@/%@", [[MageServer baseURL] absoluteString], @"auth/google/signin"];
        [viewController setUrl:url];
        [viewController setAuthenticationType:GOOGLE];
        [viewController setRequestType:SIGNIN];
    }
}

- (void) setupAuthentication {
    [self.tableView reloadData];
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
        case 4:
            return self.allowLogin ? 0 : 1;
        default:
            return localAuthentication || googleAuthentication ? 1 : 0;
    }
}

@end
