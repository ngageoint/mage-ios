//
//  SignUpViewController.m
//  MAGE
//
//  Created by William Newman on 11/5/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

@import SkyFloatingLabelTextField;

#import "SignUpViewController.h"
#import "UINextField.h"
#import "MageSessionManager.h"
#import "MageServer.h"
#import "IdpAuthentication.h"
#import "NBAsYouTypeFormatter.h"
#import "ServerAuthentication.h"
#import "DBZxcvbn.h"

@interface SignUpViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet SkyFloatingLabelTextFieldWithIcon *displayName;
@property (weak, nonatomic) IBOutlet SkyFloatingLabelTextFieldWithIcon *username;
@property (weak, nonatomic) IBOutlet SkyFloatingLabelTextFieldWithIcon *password;
@property (weak, nonatomic) IBOutlet SkyFloatingLabelTextFieldWithIcon *passwordConfirm;
@property (weak, nonatomic) IBOutlet SkyFloatingLabelTextFieldWithIcon *email;
@property (weak, nonatomic) IBOutlet SkyFloatingLabelTextFieldWithIcon *phone;
@property (weak, nonatomic) IBOutlet UIView *dividerView;
@property (weak, nonatomic) IBOutlet UIView *signupView;
@property (weak, nonatomic) IBOutlet UIView *errorView;
@property (strong, nonatomic) MageServer *server;
@property (weak, nonatomic) IBOutlet UIButton *mageServerURL;
@property (weak, nonatomic) IBOutlet UILabel *mageVersion;
@property (strong, nonatomic) id<SignUpDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;
@property (weak, nonatomic) IBOutlet UIProgressView *passwordStrengthBar;
@property (weak, nonatomic) IBOutlet UILabel *passwordStrengthLabel;
@property (strong, nonatomic) DBZxcvbn *zxcvbn;
@property (weak, nonatomic) IBOutlet UILabel *mageLabel;
@property (weak, nonatomic) IBOutlet UILabel *wandLabel;
@property (weak, nonatomic) IBOutlet UISwitch *showPassword;
@property (weak, nonatomic) IBOutlet UILabel *passwordStrengthText;
@property (weak, nonatomic) IBOutlet UILabel *showPasswordText;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;

@end

@implementation SignUpViewController

- (instancetype) initWithServer: (MageServer *) server andDelegate: (id<SignUpDelegate>) delegate andScheme:(id<MDCContainerScheming>) containerScheme {
    if (self = [super initWithNibName:@"SignupView" bundle:nil]) {
        self.server = server;
        self.delegate = delegate;
        self.scheme = containerScheme;
    }
    return self;
}

#pragma mark - Theme Changes

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
    
    self.view.backgroundColor = self.scheme.colorScheme.surfaceColor;
    self.mageLabel.textColor = self.scheme.colorScheme.primaryColorVariant;
    self.wandLabel.textColor = self.scheme.colorScheme.primaryColorVariant;
    [self.mageServerURL setTitleColor:self.scheme.colorScheme.primaryColor forState:UIControlStateNormal];
    self.mageVersion.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.signupButton.backgroundColor = self.scheme.colorScheme.primaryColorVariant;
    self.cancelButton.backgroundColor = self.scheme.colorScheme.primaryColorVariant;
    self.showPassword.onTintColor = self.scheme.colorScheme.primaryColorVariant;
    self.passwordStrengthText.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.showPasswordText.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    
    [self themeTextField:self.username];
    [self themeTextField:self.displayName];
    [self themeTextField:self.password];
    [self themeTextField:self.passwordConfirm];
    [self themeTextField:self.email];
    [self themeTextField:self.phone];
    
    self.username.iconText = @"\U0000f007";
    self.password.iconText = @"\U0000f084";
    self.passwordConfirm.iconText = @"\U0000f084";
    self.email.iconText = @"\U0000f0e0";
    self.phone.iconText = @"\U0000f095";
    self.displayName.iconText = @"\U0000f2bc";
    
    if ([self.server serverHasLocalAuthenticationStrategy]) {
        self.passwordConfirm.attributedPlaceholder = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Confirm Password *"] attributes:@{NSForegroundColorAttributeName: [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6]}];
        self.password.attributedPlaceholder = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Password *"] attributes:@{NSForegroundColorAttributeName: [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6]}];
    }
}

- (void) themeTextField: (SkyFloatingLabelTextFieldWithIcon *) field {
    field.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
    field.selectedLineColor = self.scheme.colorScheme.primaryColor;
    field.selectedTitleColor = self.scheme.colorScheme.primaryColor;
    field.placeholderColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    field.lineColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    field.titleColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    field.errorColor = self.scheme.colorScheme.errorColor;
    field.iconFont = [UIFont fontWithName:@"FontAwesome" size:15];
}

#pragma mark -

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self setupAuthentication];
    self.zxcvbn = [[DBZxcvbn alloc] init];
    self.wandLabel.text = @"\U0000f0d0";
    self.password.delegate = self;
    
    [self applyThemeWithContainerScheme:self.scheme];
}

- (BOOL) textFieldShouldReturn:(UITextField *) textField {
    
    BOOL didResign = [textField resignFirstResponder];
    if (!didResign) return NO;
    
    if ([textField respondsToSelector:@selector(nextField)] && [textField nextField]) {
        [[textField nextField] becomeFirstResponder];
    }
    
    if (textField == self.passwordConfirm) {
        [self onSignup:textField];
    }
    
    return YES;
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (textField == _phone) {
        NSString *textFieldString = [[textField text] stringByReplacingCharactersInRange:range withString:string];
        
        NSString *rawString = [textFieldString stringByReplacingOccurrencesOfString:@"[^0-9]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [textFieldString length])];
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
        alert.accessibilityLabel = @"Passwords Do Not Match";
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

- (void) markFieldError: (SkyFloatingLabelTextFieldWithIcon *) field {
    field.errorMessage = field.placeholder;
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

- (void) setupAuthentication {
    BOOL localAuthentication = [self.server serverHasLocalAuthenticationStrategy];
    self.signupView.hidden = !localAuthentication;
}


@end
