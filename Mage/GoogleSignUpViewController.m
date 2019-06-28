//
//  GoogleSignUpViewController.m
//  MAGE
//
//  Created by Dan Barela on 9/14/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "GoogleSignUpViewController.h"
#import "UIColor+Mage.h"

@interface GoogleSignUpViewController ()

@property (strong, nonatomic) MageServer *server;
@property (strong, nonatomic) GIDGoogleUser *googleUser;
@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (weak, nonatomic) IBOutlet UILabel *fullNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UITextField *displayNameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *phoneField;
@property (weak, nonatomic) IBOutlet UIButton *mageServerURL;
@property (weak, nonatomic) IBOutlet UILabel *mageVersion;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (strong, nonatomic) id<SignUpDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *mageLabel;
@property (weak, nonatomic) IBOutlet UILabel *wandLabel;

@end

@implementation GoogleSignUpViewController

- (instancetype) initWithServer: (MageServer *) server andGoogleUser: (GIDGoogleUser *) googleUser andDelegate: (id<SignUpDelegate>) delegate {
    if (self = [super initWithNibName:@"GoogleSignUpView" bundle:nil]) {
        self.server = server;
        self.googleUser = googleUser;
        self.delegate = delegate;
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.emailLabel.text = self.googleUser.profile.email;
    self.fullNameLabel.text = self.googleUser.profile.name;
    self.profileImage.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[self.googleUser.profile imageURLWithDimension:42]]];
    self.displayNameField.text = self.googleUser.profile.name;
    self.emailField.text = self.googleUser.profile.email;
    
    self.mageLabel.textColor = [UIColor primary];
    self.wandLabel.textColor = [UIColor primary];
    
    self.wandLabel.text = @"\U0000f0d0";
    
    self.displayNameField.layer.borderColor = self.emailField.layer.borderColor = self.phoneField.layer.borderColor = [[UIColor primary] CGColor];
    self.displayNameField.layer.borderWidth = self.emailField.layer.borderWidth = self.phoneField.layer.borderWidth = 1.0f;
    self.displayNameField.layer.cornerRadius = self.emailField.layer.cornerRadius = self.phoneField.layer.cornerRadius = 5.0f;
    
    [super viewWillAppear:animated];
    NSURL *url = [MageServer baseURL];
    [self.mageServerURL setTitle:[url absoluteString] forState:UIControlStateNormal];
    
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [self.mageVersion setText:[NSString stringWithFormat:@"v%@", versionString]];
}

- (IBAction)signupTapped:(id)sender {
    NSMutableArray *requiredFields = [[NSMutableArray alloc] init];

    if ([self.displayNameField.text length] == 0) {
        [self markFieldError:self.displayNameField];
        [requiredFields addObject:@"Display Name"];
    }
    if ([requiredFields count] != 0) {
        [self showDialogForRequiredFields:requiredFields];
    } else {
        // delegate signup
        
        // All fields validated
        
        NSDictionary *parameters = @{
                                     @"token": self.googleUser.authentication.idToken,
                                     @"userID": self.googleUser.userID,
                                     @"displayName": [self.displayNameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                                     @"email": [self.emailField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                                     @"phone": [self.phoneField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                                     };
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [MageServer baseURL], @"auth/google/signup"]];
        [self.delegate signUpWithParameters:parameters atURL:url];
    }

}

- (void) markFieldError: (UITextField *) field {
    UIColor *red = [UIColor colorWithRed:1.0 green:0 blue:0 alpha:.8];
    field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:field.placeholder attributes:@{NSForegroundColorAttributeName: red}];
    field.textColor = red;
}

- (void) showDialogForRequiredFields:(NSArray *) fields {
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:[NSString stringWithFormat:@"Missing Required Fields"]
                                 message:[NSString stringWithFormat:@"Please fill out the required fields: '%@'", [fields componentsJoinedByString:@", "]]
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)cancelTapped:(id)sender {
    [self.delegate signUpCanceled];
}


@end
