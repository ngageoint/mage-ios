//
//  ServerURLController.m
//  MAGE
//
//  Created by William Newman on 11/16/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

@import MaterialComponents;

#import "ServerURLController.h"
#import "MagicalRecord+MAGE.h"
#import "MAGE-Swift.h"

@interface ServerURLController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *setServerUrlText;
@property (weak, nonatomic) IBOutlet MDCButton *cancelButton;
@property (weak, nonatomic) IBOutlet MDCFilledTextField *serverURL;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *errorButton;
@property (weak, nonatomic) IBOutlet MDCButton *okButton;
@property (weak, nonatomic) IBOutlet UITextView *errorStatus;
@property (strong, nonatomic) id<ServerURLDelegate> delegate;
@property (strong, nonatomic) NSString *error;
@property (weak, nonatomic) IBOutlet UILabel *mageLabel;
@property (weak, nonatomic) IBOutlet UILabel *wandLabel;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;

@end

@implementation ServerURLController

- (instancetype) initWithDelegate: (id<ServerURLDelegate>) delegate andScheme: (id<MDCContainerScheming>) containerScheme {
    if (self = [self initWithNibName:@"ServerURLView" bundle:nil]) {
        self.delegate = delegate;
        self.scheme = containerScheme;
    }
    
    return self;
}

- (instancetype) initWithDelegate: (id<ServerURLDelegate>) delegate andError:(NSString *)error andScheme: (id<MDCContainerScheming>) containerScheme {
    if (self = [self initWithDelegate:delegate andScheme:containerScheme]) {
        self.error = error;
    }
    
    return self;
}

#pragma mark - Theme Changes

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>) containerScheme {
    if (containerScheme != nil) {
        _scheme = containerScheme;
    }
    self.view.backgroundColor = self.scheme.colorScheme.surfaceColor; // [UIColor background];
    self.mageLabel.textColor = self.scheme.colorScheme.primaryColorVariant;
    self.wandLabel.textColor = self.scheme.colorScheme.primaryColorVariant;
    [self.cancelButton applyContainedThemeWithScheme:self.scheme];
    [self.okButton applyContainedThemeWithScheme:self.scheme];
    self.errorStatus.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.setServerUrlText.textColor = self.scheme.colorScheme.primaryColor;
    
    [self.serverURL applyThemeWithScheme:containerScheme];
    self.serverURL.leadingView.tintColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
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
    
    [self.okButton setTitle:@"OK" forState:UIControlStateNormal];
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    
    UIImageView *worldImage = [[UIImageView alloc] initWithImage:[[[UIImage imageNamed:@"world"] aspectResizeTo:CGSizeMake(24, 24)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [self.serverURL setLeadingView:worldImage];
    self.serverURL.leadingViewMode = UITextFieldViewModeAlways;
    self.serverURL.accessibilityLabel = @"Server URL";
    self.serverURL.placeholder = @"Server URL";
    self.serverURL.label.text = @"Server URL";
    [self.serverURL sizeToFit];
    
    [self applyThemeWithContainerScheme:self.scheme];
    
    self.wandLabel.text = @"\U0000f0d0";
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSURL *url = [MageServer baseURL];

    if (self.error != nil) {
        [self showError:self.error];
        [self.cancelButton removeFromSuperview];
        self.serverURL.text = [url absoluteString];
    } else {
        [self.serverURL applyThemeWithScheme:self.scheme];
    }
    
    if ([url absoluteString].length == 0) {
        [self.cancelButton removeFromSuperview];
    } else {
        self.serverURL.text = [url absoluteString];
    }
}

- (IBAction)onOk:(id)sender {
    NSURL *url = [NSURL URLWithString:self.serverURL.text];
    
    if (url && [url scheme] && [url host]) {
        [self.activityIndicator startAnimating];
        self.errorStatus.hidden = YES;
        self.errorButton.hidden = YES;
        [self.delegate setServerURL: url];
        [self.serverURL applyThemeWithScheme:self.scheme];
    } else {
        [self showError:@"Invalid URL"];
    }
}

- (IBAction)onCancel:(id)sender {
    [self.delegate cancelSetServerURL];
}

- (void) showError: (NSString *) error {
    [self.activityIndicator stopAnimating];
    
    self.errorStatus.hidden = NO;
    self.errorButton.hidden = NO;
    self.errorStatus.text = error;
    self.serverURL.leadingAssistiveLabel.text = error;
    [self.serverURL applyErrorThemeWithScheme:self.scheme];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [self onOk:textField];
    return YES;
}

@end
