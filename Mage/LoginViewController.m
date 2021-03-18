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
#import "Theme+UIResponder.h"
#import "IDPLoginView.h"
#import "LocalLoginView.h"
#import "LdapLoginView.h"
#import "OrView.h"

@interface LoginViewController () <UITextFieldDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UIButton *serverURL;
@property (weak, nonatomic) IBOutlet UIView *statusView;
@property (weak, nonatomic) IBOutlet UITextView *loginStatus;
@property (weak, nonatomic) IBOutlet UIButton *statusButton;
@property (weak, nonatomic) IBOutlet UILabel *mageLabel;
@property (weak, nonatomic) IBOutlet UILabel *wandLabel;
@property (weak, nonatomic) IBOutlet UIView *signupContainerView;
@property (strong, nonatomic) MageServer *server;
@property (nonatomic) BOOL loginFailure;
@property (strong, nonatomic) id<LoginDelegate, IDPButtonDelegate> delegate;
@property (strong, nonatomic) User *user;
@property (weak, nonatomic) IBOutlet UIStackView *loginsStackView;

@end

@implementation LoginViewController

- (instancetype) initWithMageServer: (MageServer *) server andDelegate:(id<LoginDelegate, IDPButtonDelegate>) delegate {
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
    self.versionLabel.textColor = [UIColor secondaryText];
    
    if (self.user) {
        [self.serverURL setTitleColor:[UIColor secondaryText] forState:UIControlStateNormal];
    } else {
        [self.serverURL setTitleColor:[UIColor flatButton] forState:UIControlStateNormal];
    }
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.server) {
        self.statusView.hidden = YES;
    } else {
        self.statusView.hidden = NO;
    }
    
    if (self.user) {
        self.serverURL.enabled = NO;
    }

    [self setupAuthentication];
    
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [self.versionLabel setText:[NSString stringWithFormat:@"v%@", versionString]];
    
    NSURL *url = [MageServer baseURL];
    [self.serverURL setTitle:[url absoluteString] forState:UIControlStateNormal];
}

- (IBAction)serverURLTapped:(id)sender {
    [self.delegate changeServerURL];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void) setupAuthentication {
    NSArray *strategies = [self.server getStrategies];
    
    for (UIView *subview in [self.loginsStackView subviews]) {
        [subview removeFromSuperview];
    }
    
    BOOL localAuth = NO;
    for (NSDictionary *strategy in strategies) {
        if ([[strategy valueForKey:@"identifier"] isEqualToString:@"local"]) {
            localAuth = YES;
            LocalLoginView *view = [[[UINib nibWithNibName:@"local-authView" bundle:nil] instantiateWithOwner:self options:nil] objectAtIndex:0];
            view.strategy = strategy;
            view.delegate = self.delegate;
            view.user = self.user;
            [self.loginsStackView addArrangedSubview:view];
        } else if ([[strategy valueForKey:@"identifier"] isEqualToString:@"ldap"]) {
            LdapLoginView *view = [[[UINib nibWithNibName:@"ldap-authView" bundle:nil] instantiateWithOwner:self options:nil] objectAtIndex:0];
            view.strategy = strategy;
            view.delegate = self.delegate;
            [self.loginsStackView addArrangedSubview:view];
        } else {
            IDPLoginView *view = [[[UINib nibWithNibName:@"idp-authView" bundle:nil] instantiateWithOwner:self options:nil] objectAtIndex:0];
            view.strategy = strategy;
            view.delegate = self.delegate;
            [self.loginsStackView addArrangedSubview:view];
        }
    }
    
    if (strategies.count > 1 && localAuth) {
        OrView *view = [[[UINib nibWithNibName:@"orView" bundle:nil] instantiateWithOwner:self options:nil] objectAtIndex:0];
        [self.loginsStackView insertArrangedSubview:view atIndex:self.loginsStackView.arrangedSubviews.count-1];
    }
    
    self.statusView.hidden = !self.loginFailure;
}

@end
