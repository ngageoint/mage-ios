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

@interface ServerURLController ()
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UITextField *serverURL;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *errorButton;
@property (weak, nonatomic) IBOutlet UITextView *errorStatus;
@end

@implementation ServerURLController

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
    __weak __typeof__(self) weakSelf = self;
    [MageServer serverWithURL:url success:^(MageServer *mageServer) {
        [weakSelf.activityIndicator stopAnimating];
        weakSelf.errorStatus.hidden = YES;
        weakSelf.errorButton.hidden = YES;
        
        [MagicalRecord deleteAndSetupMageCoreDataStack];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    } failure:^(NSError *error) {
        [weakSelf.activityIndicator stopAnimating];
        
        weakSelf.errorStatus.hidden = NO;
        weakSelf.errorButton.hidden = NO;
        weakSelf.errorStatus.text = error.localizedDescription;
        weakSelf.serverURL.textColor = [[UIColor redColor] colorWithAlphaComponent:.65f];
    }];
}

- (IBAction)onCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
