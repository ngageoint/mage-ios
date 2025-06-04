//
//  LoginViewController.m
//  MAGE
//
//  Created by William Newman on 11/4/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "LoginViewController.h"
#import "MagicalRecord+MAGE.h"
#import "MageOfflineObservationManager.h"
#import "IDPLoginView.h"
#import "LocalLoginView.h"
#import "LdapLoginView.h"
#import "OrView.h"
#import <PureLayout.h>

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
@property (weak, nonatomic) id<LoginDelegate, IDPButtonDelegate> delegate;
@property (strong, nonatomic) User *user;
//@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@property (strong, nonatomic) id<AuthenticationTheming> theme;
@property (weak, nonatomic) IBOutlet UIStackView *loginsStackView;
@property (strong, nonatomic) IBOutlet UITextView *messageView;
@property (strong, nonatomic) UIButton *messageDetailButton;
@property (strong, nonatomic) NSString *errorMessageDetail;
@property (strong, nonatomic) OrView *orView;
@property (strong, nonatomic) UITapGestureRecognizer *gestureRecognizer;

@end

@implementation LoginViewController

- (instancetype) initWithMageServer: (MageServer *) server andDelegate:(id<LoginDelegate, IDPButtonDelegate>) delegate andTheme: (id<AuthenticationTheming>) authenticationTheme {
    self = [super initWithNibName:@"LoginView" bundle:nil];
    if (!self) return nil;
    
    self.delegate = delegate;
    self.server = server;
    self.theme = authenticationTheme;
    
    return self;
}

- (instancetype) initWithMageServer:(MageServer *)server andUser: (User *) user andDelegate:(id<LoginDelegate>)delegate andTheme: (id<AuthenticationTheming>) authenticationTheme {
    
    if (self = [self initWithMageServer:server andDelegate:delegate andTheme:authenticationTheme]) {
        self.user = user;
    }
    return self;
}

- (void) setMageServer: (MageServer *) server {
    self.server = server;
}

#pragma mark - Theme Changes
- (void) applyTheme:(id<AuthenticationTheming>)authenticationTheme {
    if (authenticationTheme != nil) {
        self.theme = authenticationTheme;
    }
    
//    self.view.backgroundColor = self.theme.backgroundColor;
//    self.mageLabel.textColor = self.theme.primaryColorVariant;
//    self.wandLabel.textColor = self.theme.primaryColorVariant;
    
    self.loginStatus.textColor = [self.theme.onSurfaceColor colorWithAlphaComponent:0.6];
    if (self.user) {
        [self.serverURL setTitleColor:[self.theme.onSurfaceColor colorWithAlphaComponent:0.6] forState:UIControlStateNormal];
    } else {
        [self.serverURL setTitleColor:[self.theme.onSurfaceColor colorWithAlphaComponent:0.6] forState:UIControlStateNormal];
    }
    
    self.versionLabel.textColor = [self.theme.onSurfaceColor colorWithAlphaComponent:0.6];
    if (self.orView) {
        [self.orView applyTheme:self.theme];
    }
}

#pragma mark -

- (void) viewDidLoad {
    [super viewDidLoad];
        
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    tap.delegate = self;
    
    [self.view addGestureRecognizer:tap];
    self.wandLabel.text = @"\U0000f0d0";
    
    [self applyTheme:self.theme];
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
    NSArray *strategies = self.server.strategies;
    
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
            [view applyTheme:_theme];
            [self.loginsStackView addArrangedSubview:view];
        } else if ([[strategy valueForKey:@"identifier"] isEqualToString:@"ldap"]) {
            LdapLoginView *view = [[[UINib nibWithNibName:@"ldap-authView" bundle:nil] instantiateWithOwner:self options:nil] objectAtIndex:0];
            view.strategy = strategy;
            view.delegate = self.delegate;
            [view applyTheme:_theme];
            [self.loginsStackView addArrangedSubview:view];
        } else {
            IDPLoginView *view = [[[UINib nibWithNibName:@"idp-authView" bundle:nil] instantiateWithOwner:self options:nil] objectAtIndex:0];
            view.strategy = strategy;
            view.delegate = self.delegate;
            [view applyTheme:self.theme];
            [self.loginsStackView addArrangedSubview:view];
        }
    }
    
    if (strategies.count > 1 && localAuth) {
        self.orView = [[[UINib nibWithNibName:@"orView" bundle:nil] instantiateWithOwner:self options:nil] objectAtIndex:0];
        [self.orView applyTheme:_theme];
        [self.loginsStackView insertArrangedSubview:self.orView atIndex:self.loginsStackView.arrangedSubviews.count-1];
    }
    
    self.messageView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.loginsStackView.bounds.size.width, self.loginsStackView.bounds.size.height)];
    self.messageView.hidden = YES;
    self.messageView.editable = NO;
    [self.loginsStackView addArrangedSubview:self.messageView];
    
    UIView *messageDetailButtonContainer = [UIView newAutoLayoutView];
    self.messageDetailButton = [[MDCButton alloc] init];
//    [self.messageDetailButton applyTextThemeWithScheme:_scheme];
    [self.messageDetailButton setTitle:@"Copy Error Message Detail" forState:UIControlStateNormal];
    [self.messageDetailButton addTarget:self action:@selector(copyDetail) forControlEvents:UIControlEventTouchUpInside];
    self.messageDetailButton.hidden = YES;
    
    [messageDetailButtonContainer addSubview:self.messageDetailButton];
    [self.messageDetailButton autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 16, 0, 16)];
    
    [self.loginsStackView addArrangedSubview:messageDetailButtonContainer];
    
    self.statusView.hidden = !self.loginFailure;
}

- (void) copyDetail {
    UIPasteboard.generalPasteboard.string = self.errorMessageDetail;
    [MDCSnackbarManager.defaultManager showMessage:[MDCSnackbarMessage messageWithText: @"Error detail copied to clipboard"]];
}

- (void) setContactInfo:(ContactInfo *) contactInfo {
    self.messageView.attributedText = contactInfo.messageWithContactInfo;
    self.messageView.accessibilityLabel = contactInfo.title;
    self.messageView.isAccessibilityElement = true;
    self.messageView.textAlignment = NSTextAlignmentCenter;
    
//    self.messageView.font = self.scheme.typographyScheme.body1;
//    self.messageView.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    
    self.messageView.backgroundColor = [UIColor clearColor];
    self.messageView.scrollEnabled = false;
    [self.messageView sizeToFit];
    self.messageView.hidden = NO;
    
    if (contactInfo.detailedInfo) {
        self.messageDetailButton.hidden = NO;
        self.errorMessageDetail = contactInfo.detailedInfo;
    } else {
        self.messageDetailButton.hidden = YES;
        self.errorMessageDetail = nil;
    }
    
    if([self.loginsStackView.superview isMemberOfClass:[UIScrollView class]]) {
        [self.loginsStackView.superview layoutIfNeeded];
        dispatch_async(dispatch_get_main_queue(), ^{
            UIScrollView * scrollView = (UIScrollView *)self.loginsStackView.superview;
            
            if([scrollView isScrollEnabled] && [scrollView showsVerticalScrollIndicator]) {
                [scrollView scrollRectToVisible:CGRectMake(scrollView.contentSize.width - 1,scrollView.contentSize.height - 1, 1, 1) animated:YES];
            }
        });
    }
}

@end
