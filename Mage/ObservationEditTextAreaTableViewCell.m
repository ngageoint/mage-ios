//
//  ObservationEditTextAreaTableViewCell.m
//  MAGE
//
//

#import "ObservationEditTextAreaTableViewCell.h"
#import "Theme+UIResponder.h"

@interface ObservationEditTextAreaTableViewCell ()
@property (strong, nonatomic) NSString *value;
@end

@implementation ObservationEditTextAreaTableViewCell

- (void) awakeFromNib {
    [super awakeFromNib];
    
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
    UIBarButtonItem *cancelBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    toolbar.items = [NSArray arrayWithObjects:cancelBarButton, flexSpace, barButton, nil];
    self.textArea.inputAccessoryView = toolbar;
    [self.textArea setDelegate: self];
}

- (void) didMoveToSuperview {
    [self registerForThemeChanges];
}

- (void) populateCellWithFormField: (id) field andValue: (id) value {
    [self.textArea setText:value];    
    self.value = self.textArea.text;
    
    [self.keyLabel setText:[field objectForKey:@"title"]];
    [self.requiredIndicator setHidden: ![[field objectForKey: @"required"] boolValue]];
}

- (void) selectRow {
    [self.textArea becomeFirstResponder];
}

- (void) cancelButtonPressed {
    self.textArea.text = self.value;
    [self.textArea resignFirstResponder];
}

- (void) doneButtonPressed {
    [self.textArea resignFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (![self.value isEqualToString:self.textArea.text]) {
        self.value = self.textArea.text;
        if (self.delegate && [self.delegate respondsToSelector:@selector(observationField:valueChangedTo:reloadCell:)]) {
            [self.delegate observationField:self.fieldDefinition valueChangedTo:self.value reloadCell:NO];
        }
    }
}

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor dialog];
    self.keyLabel.textColor = [UIColor primaryText];
    self.textArea.textColor = [UIColor primaryText];
    self.textArea.backgroundColor = [UIColor dialog];
    
    CALayer *border = [CALayer layer];
    CGFloat borderWidth = 1.0;
    border.frame = CGRectMake(0, self.textArea.frame.size.height - borderWidth, self.textArea.frame.size.width, 1);
    border.borderWidth = borderWidth;
    [self.textArea.layer addSublayer:border];
    self.textArea.layer.masksToBounds = YES;
    
    if (self.fieldValueValid) {
        border.borderColor = [UIColor brand].CGColor;
        self.requiredIndicator.textColor = [UIColor primaryText];
    } else {
        border.borderColor = [UIColor redColor].CGColor;
        self.requiredIndicator.textColor = [UIColor redColor];
    }
}

- (void) setValid:(BOOL) valid {
    [super setValid:valid];
    
    [self themeDidChange:TheCurrentTheme];
}

- (BOOL) isEmpty {
    return [self.textArea.text length] == 0;
}

@end
