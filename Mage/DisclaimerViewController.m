//
//  ConsentViewController.m
//  MAGE
//
//

#import "DisclaimerViewController.h"
#import <UserUtility.h>

@interface DisclaimerViewController ()
@property (weak, nonatomic) IBOutlet UITextView *consentText;
@property (weak, nonatomic) IBOutlet UITextView *consentTitle;
@property (strong, nonatomic) id<DisclaimerDelegate> delegate;
@end

@implementation DisclaimerViewController

- (instancetype) initWithDelegate: (id<DisclaimerDelegate>) delegate {
    self = [super init];
    if (!self) return nil;
    
    self.delegate = delegate;
    
    return self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
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
