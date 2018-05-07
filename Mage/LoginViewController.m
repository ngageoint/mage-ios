//
//  LoginViewController.m
//  MAGE
//
//  Created by William Newman on 11/4/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

@import SkyFloatingLabelTextField;
@import HexColors;

#import "LoginViewController.h"
#import "UserUtility.h"
#import "MagicalRecord+MAGE.h"
#import "MageOfflineObservationManager.h"
#import "DeviceUUID.h"
#import <GoogleSignIn/GoogleSignIn.h>
#import "Theme+UIResponder.h"
#import "OAuthLoginView.h"
#import "LoginGovLoginView.h"
#import "LocalLoginView.h"
#import "OrView.h"

@interface LoginViewController () <UITextFieldDelegate, GIDSignInUIDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UIButton *serverURL;
@property (weak, nonatomic) IBOutlet UIView *googleView;
@property (weak, nonatomic) IBOutlet UIView *statusView;
@property (weak, nonatomic) IBOutlet UITextView *loginStatus;
@property (weak, nonatomic) IBOutlet UIButton *statusButton;
@property (weak, nonatomic) IBOutlet UILabel *mageLabel;
@property (weak, nonatomic) IBOutlet UILabel *wandLabel;
@property (weak, nonatomic) IBOutlet UIView *signupContainerView;
@property (strong, nonatomic) MageServer *server;
@property (nonatomic) BOOL loginFailure;
@property (strong, nonatomic) id<LoginDelegate, OAuthButtonDelegate> delegate;
@property (weak, nonatomic) IBOutlet GIDSignInButton *googleSignInButton;
@property (strong, nonatomic) User *user;
@property (weak, nonatomic) IBOutlet UIStackView *loginsStackView;

@end

@implementation LoginViewController

- (instancetype) initWithMageServer: (MageServer *) server andDelegate:(id<LoginDelegate, OAuthButtonDelegate>) delegate {
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

    self.mageLabel.textColor = [UIColor brand];
    self.wandLabel.textColor = [UIColor brand];
    self.loginStatus.textColor = [UIColor secondaryText];
    [self.serverURL setTitleColor:[UIColor flatButton] forState:UIControlStateNormal];
    self.versionLabel.textColor = [UIColor secondaryText];
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
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (touch.view == self.googleSignInButton) return false;
    return true;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.googleSignInButton.style = kGIDSignInButtonStyleWide;
    self.googleSignInButton.colorScheme = kGIDSignInButtonColorSchemeDark;
    if (self.server) {
        self.statusView.hidden = YES;
    } else {
        self.statusView.hidden = NO;
    }

    [self setupAuthentication];
    
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [self.versionLabel setText:[NSString stringWithFormat:@"v%@", versionString]];
    
    NSURL *url = [MageServer baseURL];
    [self.serverURL setTitle:[url absoluteString] forState:UIControlStateNormal];
}

- (IBAction)googleSignInTapped:(id)sender {
    
}

- (IBAction)serverURLTapped:(id)sender {
    [self.delegate changeServerURL];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void) setupAuthentication {
    BOOL googleAuthentication = [self.server serverHasGoogleAuthenticationStrategy];
    
    if (googleAuthentication) {
        [GIDSignIn sharedInstance].uiDelegate = self;
    }
    NSArray *strategies = [self.server getStrategies];
    
    for (UIView *subview in [self.loginsStackView subviews]) {
        [subview removeFromSuperview];
    }
    
    BOOL localAuth = NO;
    
    for (NSDictionary *strategy in strategies) {
        if ([[strategy valueForKey:@"identifier"] isEqualToString:@"login-gov"]) {
            OAuthLoginView *view = [[OAuthLoginView alloc] init];
            view.strategy = strategy;
            view.delegate = self.delegate;
            [self.loginsStackView insertArrangedSubview:view atIndex:0];
        } else if ([[strategy valueForKey:@"identifier"] isEqualToString:@"local"]) {
            localAuth = YES;
            LocalLoginView *view = [[LocalLoginView alloc] init];
            view.strategy = strategy;
            view.delegate = self.delegate;
            view.user = self.user;
            [self.loginsStackView insertArrangedSubview:view atIndex:self.loginsStackView.arrangedSubviews.count];
        } else {
            OAuthLoginView *view = [[OAuthLoginView alloc] init];
            view.strategy = strategy;
            view.delegate = self.delegate;
            [self.loginsStackView insertArrangedSubview:view atIndex:0];
        }
    }
    
    if (strategies.count > 1 && localAuth) {
        OrView *orView = [[OrView alloc] init];
        [self.loginsStackView insertArrangedSubview:orView atIndex:self.loginsStackView.arrangedSubviews.count-1];
    }
    
    self.statusView.hidden = !self.loginFailure;
}

@end
