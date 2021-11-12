//
//  ConsentViewController.m
//  MAGE
//
//

#import "DisclaimerViewController.h"

@interface DisclaimerViewController ()
@property (weak, nonatomic) IBOutlet UITextView *consentText;
@property (weak, nonatomic) IBOutlet UITextView *consentTitle;
@property (weak, nonatomic) IBOutlet UILabel *wandLabel;
@property (weak, nonatomic) IBOutlet UILabel *mageLabel;
@property (weak, nonatomic) IBOutlet UIButton *disagreeButton;
@property (weak, nonatomic) IBOutlet UIButton *agreeButton;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;

@end

@implementation DisclaimerViewController

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
    self.view.backgroundColor = self.scheme.colorScheme.surfaceColor;
    self.consentText.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.consentTitle.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
    self.wandLabel.textColor = self.scheme.colorScheme.primaryColorVariant;
    self.mageLabel.textColor = self.scheme.colorScheme.primaryColorVariant;
    self.disagreeButton.backgroundColor = self.scheme.colorScheme.primaryColorVariant;
    self.agreeButton.backgroundColor = self.scheme.colorScheme.primaryColorVariant;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.navigationController && self.agreeButton) {
        self.navigationController.navigationBarHidden = YES;
    }
    self.navigationItem.title = @"Disclaimer";
    self.wandLabel.text = @"\U0000f0d0";
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self.consentTitle setText:[defaults valueForKeyPath:@"disclaimerTitle"]];
    [self.consentText setText:[defaults valueForKeyPath:@"disclaimerText"]];
}

- (IBAction)agreeTapped:(id)sender {
    [self.delegate disclaimerAgree];
}

- (IBAction)disagreeTapped:(id)sender {
    [self.delegate disclaimerDisagree];
}

@end
