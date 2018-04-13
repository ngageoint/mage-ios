//
//  ConsentViewController.m
//  MAGE
//
//

#import "DisclaimerViewController.h"
#import "UserUtility.h"
#import "Theme+UIResponder.h"

@interface DisclaimerViewController ()
@property (weak, nonatomic) IBOutlet UITextView *consentText;
@property (weak, nonatomic) IBOutlet UITextView *consentTitle;
@property (strong, nonatomic) id<DisclaimerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *wandLabel;
@property (weak, nonatomic) IBOutlet UILabel *mageLabel;
@property (weak, nonatomic) IBOutlet UIButton *disagreeButton;
@property (weak, nonatomic) IBOutlet UIButton *agreeButton;
@end

@implementation DisclaimerViewController

- (instancetype) initWithDelegate: (id<DisclaimerDelegate>) delegate {
    self = [super init];
    if (!self) return nil;
    
    self.delegate = delegate;
    
    return self;
}

- (void) themeDidChange:(MageTheme)theme {
    self.view.backgroundColor = [UIColor background];
    self.consentText.textColor = [UIColor secondaryText];
    self.consentTitle.textColor = [UIColor primaryText];
    self.wandLabel.textColor = [UIColor brand];
    self.mageLabel.textColor = [UIColor brand];
    self.disagreeButton.backgroundColor = [UIColor themedButton];
    self.agreeButton.backgroundColor = [UIColor themedButton];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self registerForThemeChanges];
    
    if (self.navigationController && self.agreeButton) {
        self.navigationController.navigationBarHidden = YES;
    }
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
