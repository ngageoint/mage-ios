//
//  ServerURLController.m
//  MAGE
//
//  Created by William Newman on 11/16/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ServerURLController.h"
#import "MageServer.h"
#import "MagicalRecord+MAGE.h"
#import "UIColor+UIColor_Mage.h"

@interface ServerURLController ()
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UITextField *serverURL;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *errorButton;
@property (weak, nonatomic) IBOutlet UIButton *okButton;
@property (weak, nonatomic) IBOutlet UITextView *errorStatus;
@property (strong, nonatomic) id<ServerURLDelegate> delegate;
@end

@implementation ServerURLController

- (instancetype) initWithDelegate: (id<ServerURLDelegate>) delegate {
    if (self = [self initWithNibName:@"ServerURLView" bundle:nil]) {
        self.delegate = delegate;
    }
    
    return self;
}

- (void) viewDidLoad {
    self.view.backgroundColor = [UIColor primaryColor];
    self.cancelButton.backgroundColor = [UIColor darkerPrimary];
    [self.cancelButton setTitleColor:[UIColor secondaryColor] forState:UIControlStateNormal];
    self.okButton.backgroundColor = [UIColor darkerPrimary];
    [self.okButton setTitleColor:[UIColor secondaryColor] forState:UIControlStateNormal];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSURL *url = [MageServer baseURL];
    self.serverURL.text = [url absoluteString];
    
    if ([url absoluteString].length == 0) {
        [self.cancelButton removeFromSuperview];
    }
}

- (IBAction)onOk:(id)sender {
    NSURL *url = [NSURL URLWithString:self.serverURL.text];

    [self.activityIndicator startAnimating];
    [self.delegate setServerURL: url];
}

- (IBAction)onCancel:(id)sender {
    [self.delegate cancelSetServerURL];
}

- (void) showError: (NSString *) error {
    [self.activityIndicator stopAnimating];
    
    self.errorStatus.hidden = NO;
    self.errorButton.hidden = NO;
    self.errorStatus.text = error;
    self.serverURL.textColor = [[UIColor redColor] colorWithAlphaComponent:.65f];
}

@end
