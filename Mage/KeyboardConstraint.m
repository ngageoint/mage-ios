//
//  KeyboardConstraint.m
//  MAGE
//
//

#import "KeyboardConstraint.h"
#import "UIResponder+FirstResponder.h"

@implementation KeyboardConstraint

CGFloat initialConstant;

- (void) awakeFromNib {
    [super awakeFromNib];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    initialConstant = self.constant;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

-(void)keyboardDidShow: (NSNotification *) notification {
    
    UIView *view = self.firstItem;
    CGRect frame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardFrameInViewCoordinates = [view convertRect:frame fromView:nil];
    self.constant = CGRectGetHeight(view.bounds) - keyboardFrameInViewCoordinates.origin.y;
    
    [view layoutIfNeeded];
}

-(void)keyboardWillHide: (NSNotification *) notification {
    self.constant = initialConstant;
}


@end
