//
//  SignUpViewController.m
//  MAGE
//
//  Created by William Newman on 11/5/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

@import MaterialComponents;

#import "SignUpViewController.h"
#import "UINextField.h"
#import "MageSessionManager.h"
#import "MageServer.h"
#import "IdpAuthentication.h"
#import "NBAsYouTypeFormatter.h"
#import "ServerAuthentication.h"
#import "DBZxcvbn.h"
#import "UIColor+Hex.h"

@interface SignUpViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet MDCTextField *displayName;
@property (weak, nonatomic) IBOutlet MDCTextField *username;
@property (weak, nonatomic) IBOutlet MDCTextField *password;
@property (weak, nonatomic) IBOutlet MDCTextField *passwordConfirm;
@property (weak, nonatomic) IBOutlet MDCTextField *email;
@property (weak, nonatomic) IBOutlet MDCTextField *phone;
@property (weak, nonatomic) IBOutlet MDCTextField *captchaText;
@property (strong, nonatomic) MDCTextInputControllerUnderline *displayNameController;
@property (strong, nonatomic) MDCTextInputControllerUnderline *usernameController;
@property (strong, nonatomic) MDCTextInputControllerUnderline *passwordController;
@property (strong, nonatomic) MDCTextInputControllerUnderline *passwordConfirmController;
@property (strong, nonatomic) MDCTextInputControllerUnderline *emailController;
@property (strong, nonatomic) MDCTextInputControllerUnderline *phoneController;
@property (strong, nonatomic) MDCTextInputControllerUnderline *captchaController;
@property (weak, nonatomic) IBOutlet UIProgressView *passwordStrengthBar;
@property (weak, nonatomic) IBOutlet UILabel *passwordStrengthLabel;
@property (strong, nonatomic) DBZxcvbn *zxcvbn;
@property (weak, nonatomic) IBOutlet UIButton *mageServerURL;
@property (weak, nonatomic) IBOutlet UILabel *mageVersion;
@property (strong, nonatomic) id<SignupDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;
@property (weak, nonatomic) IBOutlet UILabel *mageLabel;
@property (weak, nonatomic) IBOutlet UILabel *wandLabel;
@property (weak, nonatomic) IBOutlet UISwitch *showPassword;
@property (weak, nonatomic) IBOutlet UILabel *passwordStrengthText;
@property (weak, nonatomic) IBOutlet UILabel *showPasswordText;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;

@property (weak, nonatomic) IBOutlet WKWebView *captchaView;
@property (weak, nonatomic) IBOutlet UIView *captchaContainer;
@property (weak, nonatomic) IBOutlet UIButton *refreshCaptchaButton;
@property (weak, nonatomic) IBOutlet UIView *captchaProgressView;
@property (weak, nonatomic) IBOutlet UILabel *captchaProgressLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *captchaProgess;
@end

@implementation SignUpViewController

- (instancetype) initWithDelegate: (id<SignupDelegate>) delegate andScheme:(id<MDCContainerScheming>) containerScheme  {
    if (self = [super initWithNibName:@"SignupView" bundle:nil]) {
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
    
    [self themeTextField:self.username controller:self.usernameController];
    [self themeTextField:self.displayName controller:self.displayNameController];
    [self themeTextField:self.password controller:self.passwordController];
    [self themeTextField:self.passwordConfirm controller:self.passwordConfirmController];
    [self themeTextField:self.email controller:self.emailController];
    [self themeTextField:self.phone controller:self.phoneController];
    [self themeTextField:self.captchaText controller:self.captchaController];

    self.captchaProgressView.backgroundColor = self.scheme.colorScheme.surfaceColor;
    self.captchaProgressLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.captchaProgess.color = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];

    self.passwordConfirm.attributedPlaceholder = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Confirm Password *"] attributes:@{NSForegroundColorAttributeName: [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6]}];
    self.password.attributedPlaceholder = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Password *"] attributes:@{NSForegroundColorAttributeName: [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6]}];
    [self updateCGColors];
}

// this method updates the CG colors in reaction to a trait collection change
// CG Colors do not automtaically update themselves when the device changes from light to dark mode
- (void) updateCGColors {
    self.captchaContainer.layer.borderColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6].CGColor;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self updateCGColors];
}

- (void) themeTextField: (MDCTextField *) field controller: (MDCTextInputControllerUnderline *) controller {
    [controller applyThemeWithScheme:self.scheme];
    // these appear to be deficiencies in the underline controller and these colors are not set
    controller.textInput.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
    controller.textInput.clearButton.tintColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
    field.leadingView.tintColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
}

#pragma mark -

- (void) addLeadingIconConstraints: (UIImageView *) leadingIcon {
    NSLayoutConstraint *constraint0 = [NSLayoutConstraint constraintWithItem: leadingIcon attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0f constant: 30];
    NSLayoutConstraint *constraint1 = [NSLayoutConstraint constraintWithItem: leadingIcon attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0f constant: 20];
    [leadingIcon addConstraint:constraint0];
    [leadingIcon addConstraint:constraint1];
    leadingIcon.contentMode = UIViewContentModeScaleAspectFit;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.usernameController = [[MDCTextInputControllerUnderline alloc] initWithTextInput:self.username];
    UIImageView *meImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"me"]];
    [self addLeadingIconConstraints:meImage];
    [self.username setLeadingView:meImage];
    self.username.leadingViewMode = UITextFieldViewModeAlways;
    self.username.accessibilityLabel = @"Username";
    self.usernameController.placeholderText = @"Username *";
    self.usernameController.floatingEnabled = true;
    
    self.displayNameController = [[MDCTextInputControllerUnderline alloc] initWithTextInput:self.displayName];
    UIImageView *displayNameImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"contact_card"]];
    [self addLeadingIconConstraints:displayNameImage];
    [self.displayName setLeadingView:displayNameImage];
    self.displayName.leadingViewMode = UITextFieldViewModeAlways;
    self.displayName.accessibilityLabel = @"Display Name";
    self.displayNameController.placeholderText = @"Display Name *";
    self.displayNameController.floatingEnabled = true;
    
    self.emailController = [[MDCTextInputControllerUnderline alloc] initWithTextInput:self.email];
    UIImageView *emailImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"email"]];
    [self addLeadingIconConstraints:emailImage];
    [self.email setLeadingView:emailImage];
    self.email.leadingViewMode = UITextFieldViewModeAlways;
    self.email.accessibilityLabel = @"Email";
    self.emailController.placeholderText = @"Email";
    self.emailController.floatingEnabled = true;
    
    self.phoneController = [[MDCTextInputControllerUnderline alloc] initWithTextInput:self.phone];
    UIImageView *phoneImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"phone"]];
    [self addLeadingIconConstraints:phoneImage];
    [self.phone setLeadingView:phoneImage];
    self.phone.leadingViewMode = UITextFieldViewModeAlways;
    self.phone.accessibilityLabel = @"Phone";
    self.phoneController.placeholderText = @"Phone";
    self.phoneController.floatingEnabled = true;
    
    self.passwordController = [[MDCTextInputControllerUnderline alloc] initWithTextInput:self.password];
    UIImageView *passwordImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"key"]];
    [self addLeadingIconConstraints:passwordImage];
    [self.password setLeadingView:passwordImage];
    self.password.leadingViewMode = UITextFieldViewModeAlways;
    self.password.accessibilityLabel = @"Password";
    self.passwordController.placeholderText = @"Password *";
    self.passwordController.floatingEnabled = true;
    
    self.passwordConfirmController = [[MDCTextInputControllerUnderline alloc] initWithTextInput:self.passwordConfirm];
    UIImageView *passwordConfirmImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"key"]];
    [self addLeadingIconConstraints:passwordConfirmImage];
    [self.passwordConfirm setLeadingView:passwordConfirmImage];
    self.passwordConfirm.leadingViewMode = UITextFieldViewModeAlways;
    self.passwordConfirm.accessibilityLabel = @"Confirm Password";
    self.passwordConfirmController.placeholderText = @"Confirm Password *";
    self.passwordConfirmController.floatingEnabled = true;
    
    self.captchaController = [[MDCTextInputControllerUnderline alloc] initWithTextInput:self.captchaText];
    UIImageView *captchaImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"done"]];
    [self addLeadingIconConstraints:captchaImage];
    [self.captchaText setLeadingView:captchaImage];
    self.captchaText.leadingViewMode = UITextFieldViewModeAlways;
    self.captchaText.accessibilityLabel = @"Captcha";
    self.captchaController.placeholderText = @"Captcha Text *";
    self.captchaController.floatingEnabled = true;
    
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
                self.passwordStrengthLabel.text = @"Weak";
                self.passwordStrengthBar.progressTintColor = self.passwordStrengthLabel.textColor = [UIColor colorWithRed:(244.0/255.0) green:(67.0/255.0) blue:(54.0/255.0) alpha:1];
                break;
            case 1:
                self.passwordStrengthLabel.text = @"Fair";
                self.passwordStrengthBar.progressTintColor = self.passwordStrengthLabel.textColor = [UIColor colorWithRed:1.0 green:(152/255.0) blue:0.0 alpha:1];
                break;
            case 2:
                self.passwordStrengthLabel.text = @"Good";
                self.passwordStrengthBar.progressTintColor = self.passwordStrengthLabel.textColor = [UIColor colorWithRed:1.0 green:(193.0/255.0) blue:(7.0/255.0) alpha:1];
                
                break;
            case 3:
                self.passwordStrengthLabel.text = @"Strong";
                self.passwordStrengthBar.progressTintColor = self.passwordStrengthLabel.textColor = [UIColor colorWithRed:(33.0/255.0) green:(150.0/255.0) blue:(243.0/255.0) alpha:1];
                
                break;
            case 4:
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

- (IBAction)onUsernameChanged:(id)sender {
    __weak typeof(self) weakSelf = self;
    [self.delegate getCaptcha:self.username.text completion:^(NSString *captcha) {
        [weakSelf setCaptcha:captcha];
    }];
}

- (void) getCaptcha {
    __weak typeof(self) weakSelf = self;
    self.captchaProgressView.hidden = NO;
    [self.delegate getCaptcha:self.username.text completion:^(NSString *captcha) {
        [weakSelf setCaptcha:captcha];
        weakSelf.captchaProgressView.hidden = YES;
    }];
}

- (void) setCaptcha:(NSString *) captcha {
    if (captcha == nil) {
        self.captchaView.hidden = YES;
        self.refreshCaptchaButton.hidden = YES;
        return;
    }
    
    self.captchaView.hidden = NO;
    self.refreshCaptchaButton.hidden = NO;
    NSString *htmlTemplate = @"<html style=\"overflow: hidden\"><head><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, shrink-to-fit=no\"></head><body style=\"background-color: %@\";><div style=\"width:100%%; height:100%%;\"><img style=\"width:100%%; height:100%%;\" alt=\"\" src=\"%@\"></img><div></body></html>";
    NSString *htmlString = [NSString stringWithFormat:htmlTemplate, [self.scheme.colorScheme.surfaceColor hex], captcha];
    [self.captchaView loadHTMLString:htmlString baseURL:nil];
}

- (IBAction) onSignup:(id) sender {
    [self clearFieldErrors];
    NSMutableArray *requiredFields = [[NSMutableArray alloc] init];
    if ([_username.text length] == 0) {
        [self markFieldError:_usernameController errorText:@"Required"];
        [requiredFields addObject:@"Username"];
    }
    if ([self.displayName.text length] == 0) {
        [self markFieldError:self.displayNameController errorText:@"Required"];
        [requiredFields addObject:@"Display Name"];
    }
    if ([self.password.text length] == 0) {
        [self markFieldError:self.passwordController errorText:@"Required"];
        [requiredFields addObject:@"Password"];
    }
    if ([self.passwordConfirm.text length] == 0) {
        [self markFieldError:self.passwordConfirmController errorText:@"Required"];
        [requiredFields addObject:@"Confirm Password"];
    }
    if ([requiredFields count] != 0) {
        [self showDialogForRequiredFields:requiredFields];
    } else if (![self.password.text isEqualToString:self.passwordConfirm.text]) {
        [self markFieldError:self.passwordController errorText:@"Passwords Do Not Match"];
        [self markFieldError:self.passwordConfirmController errorText:@"Passwords Do Not Match"];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Passwords Do Not Match"
                                     message:@"Please update password fields to match."
                                     preferredStyle:UIAlertControllerStyleAlert];
        alert.accessibilityLabel = @"Passwords Do Not Match";
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        NSDictionary *parameters = @{
                                     @"username": [self.username.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                                     @"displayName": [self.displayName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                                     @"email": [self.email.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                                     @"phone": [self.phone.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                                     @"password": [self.password.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                                     @"passwordconfirm": [self.passwordConfirm.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                                     @"captchaText": [self.captchaText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                                     };
        
        __weak typeof(self) weakSelf = self;
        [self.delegate signupWithParameters:parameters completion:^(NSHTTPURLResponse *response) {
            if (response.statusCode == 401) {
                [weakSelf getCaptcha];
            } else if (response.statusCode == 409) {
                weakSelf.captchaText.text = @"";
                [weakSelf markFieldError:self.captchaController errorText: @"Username is not available"];
                [weakSelf setCaptcha:nil];
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:[NSString stringWithFormat:@"Username is not availble"]
                                             message:[NSString stringWithFormat:@"Please choose a different username and try again."]
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [weakSelf presentViewController:alert animated:YES completion:nil];
                
            }
        }];
    }
}

- (IBAction) onRefreshCaptcha:(id)sender {
    [self getCaptcha];
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
    [self.delegate signupCanceled];
}

- (void) clearFieldErrors {
    [self.displayNameController setErrorText:nil errorAccessibilityValue:nil];
    [self.usernameController setErrorText:nil errorAccessibilityValue:nil];
    [self.passwordController setErrorText:nil errorAccessibilityValue:nil];
    [self.passwordConfirmController setErrorText:nil errorAccessibilityValue:nil];
    [self.emailController setErrorText:nil errorAccessibilityValue:nil];
    [self.phoneController setErrorText:nil errorAccessibilityValue:nil];
    [self.captchaController setErrorText:nil errorAccessibilityValue:nil];
}

- (void) markFieldError: (MDCTextInputControllerUnderline *) field errorText: (NSString *) errorText {
    [field setErrorText:errorText errorAccessibilityValue:nil];
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

@end
