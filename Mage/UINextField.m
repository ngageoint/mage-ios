//
//  UINextField.m
//  Mage
//
//

#import "UINextField.h"
#import <objc/runtime.h>

@implementation UITextField(UINextField)

static char UIB_NEXT_FIELD_KEY;

@dynamic nextField;

- (void) setNextField:(UITextField *)nextField {
    objc_setAssociatedObject(self, &UIB_NEXT_FIELD_KEY, nextField, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UITextField *) nextField {
    return (UITextField *) objc_getAssociatedObject(self, &UIB_NEXT_FIELD_KEY);
}

@end
