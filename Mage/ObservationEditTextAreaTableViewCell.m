//
//  ObservationEditTextAreaTableViewCell.m
//  MAGE
//
//

#import "ObservationEditTextAreaTableViewCell.h"
#import "Theme+UIResponder.h"

@import SkyFloatingLabelTextField;
@import HexColors;

@interface ObservationEditTextAreaTableViewCell ()
@property (weak, nonatomic) IBOutlet SkyFloatingLabelTextFieldWithIcon *valueField;
@property (strong, nonatomic) NSString *value;
@property (nonatomic) BOOL valueBeingEdited;
@end

@implementation ObservationEditTextAreaTableViewCell

- (void) didMoveToSuperview {
    [self registerForThemeChanges];
}

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor background];
    
    self.textArea.textColor = [UIColor primaryText];
    self.textArea.keyboardAppearance = [UIColor keyboardAppearance];
    UIToolbar *toolbar = (UIToolbar *)self.textArea.inputAccessoryView;
    toolbar.tintColor = [UIColor flatButton];
    toolbar.barTintColor = [UIColor dialog];
    
    self.valueField.textColor = [UIColor primaryText];
    if (!self.valueBeingEdited) {
        self.valueField.selectedLineColor = [UIColor brand];
        self.valueField.selectedTitleColor = [UIColor brand];
        self.valueField.lineColor = [UIColor secondaryText];
        self.valueField.titleColor = [UIColor secondaryText];
    } else {
        self.valueField.lineColor = [UIColor brand];
        self.valueField.titleColor = [UIColor brand];
        self.valueField.selectedLineColor = [UIColor secondaryText];
        self.valueField.selectedTitleColor = [UIColor secondaryText];
    }
    
    self.valueField.placeholderColor = [UIColor secondaryText];
    self.valueField.errorColor = [UIColor colorWithHexString:@"F44336" alpha:.87];
    self.valueField.iconFont = [UIFont fontWithName:@"FontAwesome" size:15];
    self.valueField.iconText = @"\U0000f044";
    self.valueField.iconColor = [UIColor secondaryText];
}

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

- (void) populateCellWithFormField: (id) field andValue: (id) value {
    self.valueBeingEdited = NO;
    [self.textArea setText:value];    
    self.value = self.textArea.text;
    
    if (!self.value || [self.value isEqualToString:@""]) {
        self.valueField.text = nil;
    } else {
        self.valueField.text = @" ";
    }
    
    self.valueField.placeholder = ![[field objectForKey: @"required"] boolValue] ? [field objectForKey:@"title"] : [NSString stringWithFormat:@"%@ %@", [field objectForKey:@"title"], @"*"];
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

- (void) textViewDidChange:(UITextView *)textView {
    
    if ([textView.text isEqualToString:@""]) {
        self.valueField.text = nil;
    } else {
        self.valueField.text = @" ";
    }
    
    id view = [self superview];
    
    while (view && [view isKindOfClass:[UITableView class]] == NO) {
        view = [view superview];
    }
    
    UITableView *tableView = (UITableView *)view;
    CGPoint offset = tableView.contentOffset;
    [UIView setAnimationsEnabled:NO];
    [tableView beginUpdates];
    [tableView endUpdates];
    [UIView setAnimationsEnabled:YES];
    [tableView setContentOffset:offset];
}

- (void) textViewDidBeginEditing:(UITextView *)textView {
    self.valueBeingEdited = YES;
    [self themeDidChange:TheCurrentTheme];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    self.valueBeingEdited = NO;
    [self themeDidChange:TheCurrentTheme];
    if (![self.value isEqualToString:self.textArea.text]) {
        self.value = self.textArea.text;
        if (self.delegate && [self.delegate respondsToSelector:@selector(observationField:valueChangedTo:reloadCell:)]) {
            [self.delegate observationField:self.fieldDefinition valueChangedTo:self.value reloadCell:NO];
        }
    }
}

- (void) setValid:(BOOL) valid {
    [super setValid:valid];
    
    if (valid) {
        self.valueField.errorMessage = nil;
    } else {
        self.valueField.errorMessage = self.valueField.placeholder;
    }
}

- (BOOL) isEmpty {
    return [self.textArea.text length] == 0;
}

@end
