//
//  ServerURLController.m
//  MAGE
//
//  Created by William Newman on 11/16/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

@import SkyFloatingLabelTextField;
@import HexColors;

#import "ServerURLController.h"
#import "MageServer.h"
#import "MagicalRecord+MAGE.h"
#import "Theme+UIResponder.h"

@interface ServerURLController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *setServerUrlText;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet SkyFloatingLabelTextFieldWithIcon *serverURL;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *errorButton;
@property (weak, nonatomic) IBOutlet UIButton *okButton;
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

- (void) applyScheme {
    self.view.backgroundColor = _scheme.colorScheme.surfaceColor; // [UIColor background];
    self.mageLabel.textColor = [UIColor brand];
    self.wandLabel.textColor = [UIColor brand];
    self.cancelButton.backgroundColor = [UIColor themedButton];
    self.okButton.backgroundColor = [UIColor themedButton];
    self.errorStatus.textColor = [_scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.setServerUrlText.textColor = _scheme.colorScheme.primaryColor;
    
    self.serverURL.textColor = [_scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
    self.serverURL.selectedLineColor = _scheme.colorScheme.primaryColor;
    self.serverURL.selectedTitleColor = _scheme.colorScheme.primaryColor;
    self.serverURL.placeholderColor = [_scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.serverURL.lineColor = [_scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.serverURL.titleColor = [_scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.serverURL.errorColor = [_scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.serverURL.iconFont = [UIFont fontWithName:@"FontAwesome" size:15];
    self.serverURL.iconText = @"\U0000f0ac";
}

#pragma mark -

- (void) viewDidLoad {
    [super viewDidLoad];
    [self applyScheme];
//    [self registerForThemeChanges];
    
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
    [self.serverURL setErrorMessage:@"Server URL"];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [self onOk:textField];
    return YES;
}

@end
