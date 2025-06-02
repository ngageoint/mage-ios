//
//  AuthenticationButton.m
//  MAGE
//
//  Created by William Newman on 6/25/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "AuthenticationButton.h"
#import "AuthenticationTheming.h"
#import "UIColor+Adjust.h"

@import HexColors;

@interface AuthenticationButton()

@property (weak, nonatomic) IBOutlet UILabel *loginButtonLabel;
@property (weak, nonatomic) IBOutlet UIImageView *loginImage;
@property (weak, nonatomic) IBOutlet UIView *loginImageContainer;
@property (weak, nonatomic) UIStackView *authenticationButton;
@property (strong, nonatomic) UIColor *buttonColor;
@property (strong, nonatomic) UIColor *buttonColorHighlighted;
@property (strong, nonatomic) id<AuthenticationTheming> theme;
@end

@implementation AuthenticationButton

-(instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    self.authenticationButton = [[[NSBundle mainBundle] loadNibNamed:@"AuthenticationButton" owner:self options:nil] objectAtIndex:0];
    self.authenticationButton.frame = self.bounds;
    [self addSubview:self.authenticationButton];
    
    [self setUserInteractionEnabled:YES];
    
    return self;
}

- (void) setStrategy:(NSDictionary *)loginStrategy {
    _strategy = loginStrategy;
    
    NSDictionary *strategy = [loginStrategy objectForKey:@"strategy"];
    
    NSString *title = [strategy objectForKey:@"title"];
    self.loginButtonLabel.text = [NSString stringWithFormat:@"Sign in with %@", title];
    
    if ([strategy objectForKey:@"icon"] != NULL) {
        NSData *data = [[NSData alloc]initWithBase64EncodedString:[strategy valueForKey:@"icon"] options:NSDataBase64DecodingIgnoreUnknownCharacters];
        [self.loginImage setImage:[UIImage imageWithData:data]];
        [self.loginImageContainer setHidden:NO];
    } else {
        [self.loginImageContainer setHidden:YES];
    }
    
    if ([strategy objectForKey:@"buttonColor"] != NULL) {
        self.buttonColor = [UIColor hx_colorWithHexRGBAString:[strategy valueForKey:@"buttonColor"] alpha:1.0];
    } else {
        self.buttonColor = self.theme ? self.theme.surfaceColor : UIColor.whiteColor;
    }

    self.buttonColorHighlighted = [self.buttonColor brightness:15];
    [self setButtonBackgroundColor:self.buttonColor];

    if ([strategy objectForKey:@"textColor"] != NULL) {
        self.loginButtonLabel.textColor = [UIColor hx_colorWithHexRGBAString:[strategy valueForKey:@"textColor"] alpha:1.0];
    } else {
        self.loginButtonLabel.textColor = self.theme ? self.theme.onSurfaceColor : [UIColor labelColor];
    }
}

- (void) applyTheme:(id<AuthenticationTheming>)theme {
    self.theme = theme;
    [self.layer setShadowOffset:CGSizeMake(0, 1)];
    [self.layer setShadowColor:theme.onSurfaceColor.CGColor];
    [self.layer setShadowOpacity:.7];
    [self.layer setShadowRadius:2];
    [self setStrategy:self.strategy];
}


- (IBAction)onAuthenticationButtonTapped:(id)sender {
    [self.delegate onAuthenticationButtonTapped:sender];
}

-(void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self setButtonBackgroundColor:self.buttonColorHighlighted];
}

-(void) touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    [self setButtonBackgroundColor:self.buttonColor];
}

-(void) touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    [self setButtonBackgroundColor:self.buttonColor];
}

-(void) setButtonBackgroundColor:(UIColor *) color {
    self.authenticationButton.backgroundColor = color;
}

@end
