//
//  KeyboardConstraint.m
//  MAGE
//
//  Created by Dan Barela on 2/17/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "KeyboardConstraint.h"
#import "UIResponder+FirstResponder.h"

@implementation KeyboardConstraint

CGFloat initialConstant;

- (void) awakeFromNib {
    [super awakeFromNib];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    initialConstant = self.constant;
}

-(void)keyboardWillShow: (NSNotification *) notification {
    NSDictionary *userInfo = notification.userInfo;
    CGRect r = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.constant = initialConstant + r.size.height;
    UITableView *table = self.secondItem;
    UIView *responder = [UIResponder currentFirstResponder];
    UIView *cell = responder.superview.superview;
    [table setContentOffset:CGPointMake(table.contentOffset.x, cell.frame.origin.y+initialConstant)];
}

-(void)keyboardWillHide: (NSNotification *) notification {
    self.constant = initialConstant;
}


@end
