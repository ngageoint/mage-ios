//
//  SignUpViewController.m
//  MAGE
//
//  Created by William Newman on 11/5/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "SignUpViewController.h"
#import "UINextField.h"
#import "MageSessionManager.h"
#import "MageServer.h"
#import "OAuthViewController.h"
#import "OAuthAuthentication.h"
#import <NBAsYouTypeFormatter.h>
#import <ServerAuthentication.h>
#import <GoogleSignIn/GoogleSignIn.h>
#import "UIColor+UIColor_Mage.h"
#import <DBZxcvbn.h>

@interface SignUpViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *displayName;
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UITextField *passwordConfirm;
@property (weak, nonatomic) IBOutlet UITextField *email;
@property (weak, nonatomic) IBOutlet UITextField *phone;
@property (weak, nonatomic) IBOutlet UIView *googleView;
@property (weak, nonatomic) IBOutlet UIView *dividerView;
@property (weak, nonatomic) IBOutlet UIView *signupView;
@property (weak, nonatomic) IBOutlet UIView *errorView;
@property (weak, nonatomic) IBOutlet UIView *googleDividerView;
@property (strong, nonatomic) MageServer *server;
@property (weak, nonatomic) IBOutlet GIDSignInButton *googleSignInButton;
@property (weak, nonatomic) IBOutlet UIButton *mageServerURL;
@property (weak, nonatomic) IBOutlet UILabel *mageVersion;
@property (strong, nonatomic) id<SignUpDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;
@property (weak, nonatomic) IBOutlet UIProgressView *passwordStrengthBar;
@property (weak, nonatomic) IBOutlet UILabel *passwordStrengthLabel;
@property (strong, nonatomic) DBZxcvbn *zxcvbn;

@end

@implementation SignUpViewController

- (instancetype) initWithServer: (MageServer *) server andDelegate: (id<SignUpDelegate>) delegate {
    if (self = [super initWithNibName:@"SignupView" bundle:nil]) {
        self.server = server;
        self.delegate = delegate;
    }
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self setupAuthentication];
    
    self.zxcvbn = [[DBZxcvbn alloc] init];
    
    self.view.backgroundColor = [UIColor primaryColor];
    self.cancelButton.backgroundColor = [UIColor darkerPrimary];
    [self.cancelButton setTitleColor:[UIColor secondaryColor] forState:UIControlStateNormal];
    self.signupButton.backgroundColor = [UIColor darkerPrimary];
    [self.signupButton setTitleColor:[UIColor secondaryColor] forState:UIControlStateNormal];
    
    self.password.delegate = self;
    
    self.googleSignInButton.style = kGIDSignInButtonStyleWide;

    if ([self.server serverHasLocalAuthenticationStrategy]) {
        ServerAuthentication *server = [self.server.authenticationModules objectForKey:@"server"];
        self.password.placeholder = [NSString stringWithFormat:@"Password (minimum %@ characters)", [server.parameters valueForKey:@"passwordMinLength"]];
        self.passwordConfirm.placeholder = [NSString stringWithFormat:@"Confirm Password (minimum %@ characters)", [server.parameters valueForKey:@"passwordMinLength"]];
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
    } else if (textField == _password) {
        NSString *password = [self.password.text stringByReplacingCharactersInRange:range withString:string];
        NSArray *userInputs = @[];
        DBResult *passwordStrength = [self.zxcvbn passwordStrength:password userInputs:userInputs];
        [self.passwordStrengthBar setProgress:(1+passwordStrength.score)/5.0];
        switch (passwordStrength.score) {
            case 0:
                // weak
                
                self.passwordStrengthLabel.text = @"Weak";
                self.passwordStrengthBar.progressTintColor = self.passwordStrengthLabel.textColor = [UIColor colorWithRed:1 green:.36 blue:.36 alpha:1];
                break;
            case 1:
                // fair
                self.passwordStrengthLabel.text = @"Fair";
                self.passwordStrengthBar.progressTintColor = self.passwordStrengthLabel.textColor = [UIColor orangeColor];
                
                break;
            case 2:
                // good
                self.passwordStrengthLabel.text = @"Good";
                self.passwordStrengthBar.progressTintColor = self.passwordStrengthLabel.textColor = [UIColor yellowColor];
                
                break;
                
            case 3:
                // strong
                self.passwordStrengthLabel.text = @"Strong";
                self.passwordStrengthBar.progressTintColor = self.passwordStrengthLabel.textColor = [UIColor colorWithRed:(84.0/255.0) green:(199.0/255.0) blue:(252.0/255.0) alpha:1.0];
                
                break;
                
            case 4:
                // excell
                self.passwordStrengthLabel.text = @"Excellent";
                self.passwordStrengthBar.progressTintColor = self.passwordStrengthLabel.textColor = [UIColor greenColor];
                
                break;
        }
    }
    return YES;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSURL *url = [MageServer baseURL];
    [self.mageServerURL setTitle:[url absoluteString] forState:UIControlStateNormal];
    
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [self.mageVersion setText:[NSString stringWithFormat:@"v%@", versionString]];
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
        // delegate signup
        
        // All fields validated
        
        NSDictionary *parameters = @{
                                     @"username": [self.username.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                                     @"displayName": [self.displayName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                                     @"email": [self.email.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                                     @"phone": [self.phone.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                                     @"password": [self.password.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                                     @"passwordconfirm": [self.passwordConfirm.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                                     };
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [MageServer baseURL], @"api/users"]];
        [self.delegate signUpWithParameters:parameters atURL:url];
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
    [self.delegate signUpCanceled];
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

- (void) setupAuthentication {
    BOOL localAuthentication = [self.server serverHasLocalAuthenticationStrategy];
    BOOL googleAuthentication = [self.server serverHasGoogleAuthenticationStrategy];
    
    self.googleView.hidden = self.googleDividerView.hidden = !googleAuthentication;
    self.signupView.hidden = !localAuthentication;
    self.dividerView.hidden = !(googleAuthentication && localAuthentication);
}


@end
