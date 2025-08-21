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
#import "IdpAuthentication.h"
#import "NBAsYouTypeFormatter.h"
#import "ServerAuthentication.h"
#import "DBZxcvbn.h"
#import "UIColor+Hex.h"
#import "MAGE-Swift.h"

@interface SignUpViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet MDCFilledTextField *displayName;
@property (weak, nonatomic) IBOutlet MDCFilledTextField *username;
@property (weak, nonatomic) IBOutlet MDCFilledTextField *password;
@property (weak, nonatomic) IBOutlet MDCFilledTextField *passwordConfirm;
@property (weak, nonatomic) IBOutlet MDCFilledTextField *email;
@property (weak, nonatomic) IBOutlet MDCFilledTextField *phone;
@property (weak, nonatomic) IBOutlet MDCFilledTextField *captchaText;
@property (weak, nonatomic) IBOutlet UIProgressView *passwordStrengthBar;
@property (weak, nonatomic) IBOutlet UILabel *passwordStrengthLabel;
@property (strong, nonatomic) DBZxcvbn *zxcvbn;
@property (weak, nonatomic) IBOutlet UIButton *mageServerURL;
@property (weak, nonatomic) IBOutlet UILabel *mageVersion;
@property (strong, nonatomic) id<SignupDelegate> delegate;
@property (weak, nonatomic) IBOutlet MDCButton *cancelButton;
@property (weak, nonatomic) IBOutlet MDCButton *signupButton;
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
    
    self.view.backgroundColor = self.scheme.colorScheme.backgroundColor;
    [self.mageServerURL setTitleColor:[self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6] forState:UIControlStateNormal];
    self.mageVersion.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    [self.signupButton applyContainedThemeWithScheme:self.scheme];
    [self.cancelButton applyContainedThemeWithScheme:self.scheme];
    self.showPassword.onTintColor = self.scheme.colorScheme.primaryColorVariant;
    self.passwordStrengthText.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.showPasswordText.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    
    [self.username applyThemeWithScheme:containerScheme];
    [self.displayName applyThemeWithScheme:containerScheme];
    [self.password applyThemeWithScheme:containerScheme];
    [self.passwordConfirm applyThemeWithScheme:containerScheme];
    [self.email applyThemeWithScheme:containerScheme];
    [self.phone applyThemeWithScheme:containerScheme];
    [self.captchaText applyThemeWithScheme:containerScheme];
    
    self.username.leadingView.tintColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.displayName.leadingView.tintColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.password.leadingView.tintColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.passwordConfirm.leadingView.tintColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.email.leadingView.tintColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.phone.leadingView.tintColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.captchaText.leadingView.tintColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];

    self.captchaProgressView.backgroundColor = self.scheme.colorScheme.surfaceColor;
    self.captchaProgressLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.captchaProgess.color = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];

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
    
    UIImageView *meImage = [[UIImageView alloc] initWithImage:[[[UIImage systemImageNamed:@"person.fill"] aspectResizeTo:CGSizeMake(24, 24)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [self.username setLeadingView:meImage];
    self.username.leadingViewMode = UITextFieldViewModeAlways;
    self.username.accessibilityLabel = @"Username";
    self.username.placeholder = @"Username *";
    self.username.label.text = @"Username *";
    self.username.leadingAssistiveLabel.text = @" ";
    [self.username sizeToFit];
    
    UIImageView *displayNameImage = [[UIImageView alloc] initWithImage:[[[UIImage imageNamed:@"contact_card"] aspectResizeTo:CGSizeMake(24, 24)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [self.displayName setLeadingView:displayNameImage];
    self.displayName.leadingViewMode = UITextFieldViewModeAlways;
    self.displayName.accessibilityLabel = @"Display Name";
    self.displayName.placeholder = @"Display Name *";
    self.displayName.label.text = @"Display Name *";
    self.displayName.leadingAssistiveLabel.text = @" ";
    [self.displayName sizeToFit];
    
    UIImageView *emailImage = [[UIImageView alloc] initWithImage:[[[UIImage systemImageNamed:@"envelope"] aspectResizeTo:CGSizeMake(24, 24)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [self.email setLeadingView:emailImage];
    self.email.leadingViewMode = UITextFieldViewModeAlways;
    self.email.accessibilityLabel = @"Email";
    self.email.placeholder = @"Email";
    self.email.label.text = @"Email";
    self.email.leadingAssistiveLabel.text = @" ";
    [self.email sizeToFit];
    
    UIImageView *phoneImage = [[UIImageView alloc] initWithImage:[[[UIImage systemImageNamed:@"phone.fill"] aspectResizeTo:CGSizeMake(24, 24)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [self.phone setLeadingView:phoneImage];
    self.phone.leadingViewMode = UITextFieldViewModeAlways;
    self.phone.accessibilityLabel = @"Phone";
    self.phone.placeholder = @"Phone";
    self.phone.label.text = @"Phone";
    self.phone.leadingAssistiveLabel.text = @" ";
    [self.phone sizeToFit];
    
    UIImageView *passwordImage = [[UIImageView alloc] initWithImage:[[[UIImage systemImageNamed:@"key.fill"] aspectResizeTo:CGSizeMake(24, 24)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [self.password setLeadingView:passwordImage];
    self.password.leadingViewMode = UITextFieldViewModeAlways;
    self.password.accessibilityLabel = @"Password";
    self.password.placeholder = @"Password *";
    self.password.label.text = @"Password *";
    self.password.leadingAssistiveLabel.text = @" ";
    [self.password sizeToFit];
    
    UIImageView *passwordConfirmImage = [[UIImageView alloc] initWithImage:[[[UIImage systemImageNamed:@"key.fill"] aspectResizeTo:CGSizeMake(24, 24)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [self.passwordConfirm setLeadingView:passwordConfirmImage];
    self.passwordConfirm.leadingViewMode = UITextFieldViewModeAlways;
    self.passwordConfirm.accessibilityLabel = @"Confirm Password";
    self.passwordConfirm.placeholder = @"Confirm Password *";
    self.passwordConfirm.label.text = @"Confirm Password *";
    self.passwordConfirm.leadingAssistiveLabel.text = @" ";
    [self.passwordConfirm sizeToFit];
    
    UIImageView *captchaImage = [[UIImageView alloc] initWithImage:[[[UIImage systemImageNamed:@"checkmark"] aspectResizeTo:CGSizeMake(24, 24)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [self.captchaText setLeadingView:captchaImage];
    self.captchaText.leadingViewMode = UITextFieldViewModeAlways;
    self.captchaText.accessibilityLabel = @"Captcha";
    self.captchaText.placeholder = @"Captcha Text *";
    self.captchaText.label.text = @"Captcha Text *";
    self.captchaText.leadingAssistiveLabel.text = @" ";
    [self.captchaText sizeToFit];

    self.zxcvbn = [[DBZxcvbn alloc] init];
    self.password.delegate = self;
    self.captchaText.delegate = self;
    self.password.returnKeyType = UIReturnKeyGo;
    self.captchaText.returnKeyType = UIReturnKeyGo;
    
    [self.signupButton setTitle:@"Sign Up" forState:UIControlStateNormal];
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    
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
    
    if (textField == self.captchaText) {
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
        [self markFieldError:_username errorText:@"Required"];
        [requiredFields addObject:@"Username"];
    }
    if ([self.displayName.text length] == 0) {
        [self markFieldError:self.displayName errorText:@"Required"];
        [requiredFields addObject:@"Display Name"];
    }
    if ([self.password.text length] == 0) {
        [self markFieldError:self.password errorText:@"Required"];
        [requiredFields addObject:@"Password"];
    }
    if ([self.passwordConfirm.text length] == 0) {
        [self markFieldError:self.passwordConfirm errorText:@"Required"];
        [requiredFields addObject:@"Confirm Password"];
    }
    if ([requiredFields count] != 0) {
        [self showDialogForRequiredFields:requiredFields];
    } else if (![self.password.text isEqualToString:self.passwordConfirm.text]) {
        [self markFieldError:self.password errorText:@"Passwords Do Not Match"];
        [self markFieldError:self.passwordConfirm errorText:@"Passwords Do Not Match"];
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
                [weakSelf markFieldError:self.captchaText errorText: @"Username is not available"];
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
    
    [self.passwordConfirm setSecureTextEntry:!self.passwordConfirm.secureTextEntry];
    self.passwordConfirm.clearsOnBeginEditing = NO;
}

- (IBAction) onCancel:(id) sender {
    [self.delegate signupCanceled];
}

- (void) clearFieldErrors {
    self.displayName.leadingAssistiveLabel.text = @" ";
    self.username.leadingAssistiveLabel.text = @" ";
    self.password.leadingAssistiveLabel.text = @" ";
    self.passwordConfirm.leadingAssistiveLabel.text = @" ";
    self.email.leadingAssistiveLabel.text = @" ";
    self.phone.leadingAssistiveLabel.text = @" ";
    self.captchaText.leadingAssistiveLabel.text = @" ";
    
    [self.displayName applyThemeWithScheme:self.scheme];
    [self.username applyThemeWithScheme:self.scheme];
    [self.password applyThemeWithScheme:self.scheme];
    [self.passwordConfirm applyThemeWithScheme:self.scheme];
    [self.email applyThemeWithScheme:self.scheme];
    [self.phone applyThemeWithScheme:self.scheme];
    [self.captchaText applyThemeWithScheme:self.scheme];
}

- (void) markFieldError: (MDCFilledTextField *) field errorText: (NSString *) errorText {
    field.leadingAssistiveLabel.text = errorText;
    [field applyErrorThemeWithScheme:self.scheme];
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
