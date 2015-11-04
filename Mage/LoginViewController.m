//
//  LoginViewController.m
//  Mage
//
//

#import "LoginViewController.h"
#import "LocalAuthentication.h"
#import "User+helper.h"
#import <Observation+helper.h>

#import <Location+helper.h>
#import <Layer+helper.h>
#import <Form.h>
#import <Mage.h>
#import "AppDelegate.h"
#import <HttpManager.h>
#import "MageRootViewController.h"
#import <UserUtility.h>
#import "DeviceUUID.h"
#import "MageServer.h"
#import "Observations.h"
#import "MagicalRecord+delete.h"
#import "LoginDataSource.h"

@interface LoginViewController ()

    @property (weak, nonatomic) IBOutlet UITextField *serverUrlField;
    @property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loginIndicator;
    @property (weak, nonatomic) IBOutlet UIButton *lockButton;
    @property (weak, nonatomic) IBOutlet UIButton *statusButton;
    @property (weak, nonatomic) IBOutlet UILabel *versionLabel;
    @property (weak, nonatomic) IBOutlet UIActivityIndicatorView *serverVerificationIndicator;
    @property (weak, nonatomic) IBOutlet UITableView *tableView;
    @property (strong, nonatomic) IBOutlet LoginDataSource *dataSource;
    @property (strong, nonatomic) MageServer *server;
    @property (nonatomic) BOOL allowLogin;
@end

@implementation LoginViewController

- (void) authenticationWasSuccessful {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults objectForKey:@"showDisclaimer"] == nil || ![[defaults objectForKey:@"showDisclaimer"] boolValue]) {
        [[UserUtility singleton ] acceptConsent];
        [self performSegueWithIdentifier:@"SkipDisclaimerSegue" sender:nil];
    } else {
        [self performSegueWithIdentifier:@"LoginSegue" sender:nil];
    }
    
    self.dataSource.usernameField.textColor = [UIColor blackColor];
    self.dataSource.passwordField.textColor = [UIColor blackColor];
    
    self.dataSource.loginStatus.hidden = YES;
    self.statusButton.hidden = YES;
    
    [self resetLogin];
}

- (void) authenticationHadFailure {
    self.statusButton.hidden = NO;
    self.dataSource.loginStatus.hidden = NO;
    self.dataSource.loginStatus.text = @"The username or password you entered is incorrect";
    self.dataSource.usernameField.textColor = [[UIColor redColor] colorWithAlphaComponent:.65f];
    self.dataSource.passwordField.textColor = [[UIColor redColor] colorWithAlphaComponent:.65f];

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
    [self.dataSource.loginButton setEnabled:YES];
    [self.loginIndicator stopAnimating];
    [self.dataSource.usernameField setEnabled:YES];
    [self.dataSource.usernameField setBackgroundColor:[UIColor whiteColor]];
    [self.dataSource.passwordField setEnabled:YES];
    [self.dataSource.passwordField setBackgroundColor:[UIColor whiteColor]];
    [self.serverUrlField setEnabled:YES];
    [self.serverUrlField setBackgroundColor:[UIColor whiteColor]];
    [self.lockButton setEnabled:YES];
    [self.dataSource.showPassword setEnabled:YES];
}

- (void) startLogin {
    [self.dataSource.loginButton setEnabled:NO];
    [self.loginIndicator startAnimating];
    [self.dataSource.usernameField setEnabled:NO];
    [self.dataSource.usernameField setBackgroundColor:[UIColor lightGrayColor]];
    [self.dataSource.passwordField setEnabled:NO];
    [self.dataSource.passwordField setBackgroundColor:[UIColor lightGrayColor]];
    [self.serverUrlField setEnabled:NO];
    [self.serverUrlField setBackgroundColor:[UIColor lightGrayColor]];
    [self.lockButton setEnabled:NO];
    [self.dataSource.showPassword setEnabled:NO];
}

- (void) verifyLogin {
    if (!self.allowLogin) return;
    if (self.server.reachabilityManager.reachable && ([self usernameChanged] || [self serverUrlChanged])) {
        [MagicalRecord deleteCoreDataStack];
        [MagicalRecord setupCoreDataStackWithStoreNamed:@"Mage.sqlite"];
    }
    
	// setup authentication
    [self startLogin];
    NSUUID *deviceUUID = [DeviceUUID retrieveDeviceUUID];
	NSString *uidString = deviceUUID.UUIDString;
    NSLog(@"uid: %@", uidString);
	NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
														 self.dataSource.usernameField.text, @"username",
														 self.dataSource.passwordField.text, @"password",
														 uidString, @"uid",
														 nil];
	
	[self.server.authentication loginWithParameters: parameters];
}

- (BOOL) usernameChanged {
    NSDictionary *loginParameters = [self.server.authentication loginParameters];
    NSString *username = [loginParameters objectForKey:@"username"];
    return [username length] != 0 && ![self.dataSource.usernameField.text isEqualToString:username];
}

- (BOOL) serverUrlChanged {
    NSDictionary *loginParameters = [self.server.authentication loginParameters];
    NSString *serverUrl = [loginParameters objectForKey:@"serverUrl"];
    return [serverUrl length] != 0 && ![self.serverUrlField.text isEqualToString:serverUrl];
}

- (BOOL) changeTextViewFocus: (id)sender {
    if ([[self.dataSource.usernameField text] isEqualToString:@""]) {
        [self.dataSource.usernameField becomeFirstResponder];
		return YES;
    } else if ([[self.dataSource.passwordField text] isEqualToString:@""]) {
        [self.dataSource.passwordField becomeFirstResponder];
		return YES;
    } else {
		return NO;
	}
}

- (IBAction)toggleUrlField:(id)sender {
    if (self.serverUrlField.enabled) {
		NSURL *url = [NSURL URLWithString:self.serverUrlField.text];
        [self initMageServerWithURL:url];
    } else {
        [self.dataSource.usernameField setEnabled:NO];
        [self.dataSource.passwordField setEnabled:NO];
        [self.serverUrlField setEnabled:YES];
        [self.lockButton setImage:[UIImage imageNamed:@"unlock.png"] forState:UIControlStateNormal];
    }
}

//  When we are done editing on the keyboard
- (IBAction)resignAndLogin:(id) sender {
    if (![self changeTextViewFocus: sender]) {
		[sender resignFirstResponder];
		[self verifyLogin];
	}
}

- (IBAction)loginButtonPress:(id)sender {
    if (![self changeTextViewFocus: sender]) {
        [sender resignFirstResponder];
        if ([self.dataSource.usernameField isFirstResponder]) {
            [self.dataSource.usernameField resignFirstResponder];
        } else if([self.dataSource.passwordField isFirstResponder]) {
            [self.dataSource.passwordField resignFirstResponder];
        }
        
        [self verifyLogin];
    }

}

//  When the view reappears after logout we want to wipe the username and password fields
- (void)viewWillAppear:(BOOL)animated {
    
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *buildString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    [self.versionLabel setText:[NSString stringWithFormat:@"v%@ b%@", versionString, buildString]];
    
    [self.dataSource.usernameField setText:@""];
    [self.dataSource.passwordField setText:@""];
    [self.dataSource.passwordField setDelegate:self];
}

- (void) setupAuthentication {
    [self.dataSource setAuthenticationWithServer:self.server];
    [self.tableView reloadData];
}

- (void) viewDidAppear:(BOOL)animated {
    NSURL *url = [MageServer baseURL];
    if ([@"" isEqualToString:url.absoluteString]) {
        [self toggleUrlField:NULL];
        [self.serverUrlField becomeFirstResponder];
        return;
    } else {
        [self.serverUrlField setText:[url absoluteString]];
        [self initMageServerWithURL:url];
        
        self.allowLogin = YES;
    }
}

- (void) viewDidLoad {
    self.tableView.estimatedRowHeight = 68.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.alwaysBounceVertical = NO;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
}

- (void) initMageServerWithURL:(NSURL *) url {
    [self.serverVerificationIndicator startAnimating];
    [self.lockButton setHidden:YES];
    __weak __typeof__(self) weakSelf = self;
    [MageServer serverWithURL:url authenticationDelegate:self success:^(MageServer *mageServer) {
        weakSelf.server = mageServer;
        
        [weakSelf.serverUrlField setEnabled:NO];
        [weakSelf.lockButton setImage:[UIImage imageNamed:@"lock.png"] forState:UIControlStateNormal];
        
        weakSelf.dataSource.loginStatus.hidden = YES;
        weakSelf.statusButton.hidden = YES;
        [weakSelf.dataSource.usernameField setEnabled:YES];
        [weakSelf.dataSource.passwordField setEnabled:YES];
        [weakSelf.lockButton setHidden:NO];
        [weakSelf.serverVerificationIndicator stopAnimating];
        weakSelf.allowLogin = YES;
        
        [self setupAuthentication];
    } failure:^(NSError *error) {
        weakSelf.allowLogin = NO;
        weakSelf.dataSource.loginStatus.hidden = NO;
        weakSelf.statusButton.hidden = NO;
        weakSelf.dataSource.loginStatus.text = error.localizedDescription;
        weakSelf.serverUrlField.textColor = [[UIColor redColor] colorWithAlphaComponent:.65f];
        [weakSelf.lockButton setHidden:NO];
        [weakSelf.serverVerificationIndicator stopAnimating];
    }];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (IBAction)showPasswordSwitchAction:(id)sender {
    [self.dataSource.passwordField setSecureTextEntry:!self.dataSource.passwordField.secureTextEntry];
    self.dataSource.passwordField.clearsOnBeginEditing = NO;
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
