//
//  ServerURLController.m
//  MAGE
//
//  Created by William Newman on 11/16/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

@import MaterialComponents;

#import "ServerURLController.h"
#import "MageServer.h"
#import "MagicalRecord+MAGE.h"

@interface ServerURLController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *setServerUrlText;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet MDCTextField *serverURL;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *errorButton;
@property (weak, nonatomic) IBOutlet UIButton *okButton;
@property (weak, nonatomic) IBOutlet UITextView *errorStatus;
@property (strong, nonatomic) id<ServerURLDelegate> delegate;
@property (strong, nonatomic) NSString *error;
@property (weak, nonatomic) IBOutlet UILabel *mageLabel;
@property (weak, nonatomic) IBOutlet UILabel *wandLabel;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@property (strong, nonatomic) MDCTextInputControllerUnderline *serverUrlController;

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
    self.cancelButton.backgroundColor = self.scheme.colorScheme.primaryColorVariant;
    self.okButton.backgroundColor = self.scheme.colorScheme.primaryColorVariant;
    self.errorStatus.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.setServerUrlText.textColor = self.scheme.colorScheme.primaryColor;
    
    [self.serverUrlController applyThemeWithScheme:containerScheme];
    // these appear to be deficiencies in the underline controller and these colors are not set
    self.serverUrlController.textInput.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
    self.serverUrlController.textInput.clearButton.tintColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
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
    self.serverUrlController = [[MDCTextInputControllerUnderline alloc] initWithTextInput:self.serverURL];
    UIImageView *worldImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"world"]];
    [self addLeadingIconConstraints:worldImage];
    [self.serverURL setLeadingView:worldImage];
    self.serverURL.leadingViewMode = UITextFieldViewModeAlways;
    self.serverURL.accessibilityLabel = @"Server URL";
    self.serverUrlController.placeholderText = @"Server URL";
    self.serverUrlController.floatingEnabled = true;
    
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
    [self.serverUrlController setErrorText:error errorAccessibilityValue:nil];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [self onOk:textField];
    return YES;
}

@end
