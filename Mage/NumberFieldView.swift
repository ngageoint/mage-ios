//
//  NumberFieldView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/26/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCTextField;

class NumberFieldView : BaseFieldView {
    private var shouldResign: Bool = false;
    private var number: NSNumber?;
    private var min: NSNumber?;
    private var max: NSNumber?;
    
    lazy var helperText: String? = {
        var helper: String? = nil;
        if (self.min != nil && self.max != nil) {
            helper = "Must be between \(self.min!) and \(self.max!)";
        } else if (self.min != nil) {
            helper = "Must be greater than \(self.min!) ";
        } else if (self.max != nil) {
            helper = "Must be less than \(self.max!)";
        }
        return helper;
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel(forAutoLayout: ());
        label.text = helperText;
        label.sizeToFit();
        return label;
    }()
    
    private lazy var formatter: NumberFormatter = {
        let formatter = NumberFormatter();
        formatter.numberStyle = .decimal;
        return formatter;
    }()
    
    private lazy var accessoryView: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44));
        toolbar.autoSetDimension(.height, toSize: 44);
        
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed));
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed));
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil);
        
        toolbar.items = [cancelBarButton, flexSpace, UIBarButtonItem(customView: titleLabel), flexSpace, doneBarButton];
        return toolbar;
    }()
    
    lazy var textField: MDCFilledTextField = {
        let textField = MDCFilledTextField(frame: CGRect(x: 0, y: 0, width: 200, height: 100));
        textField.delegate = self;
        textField.accessibilityLabel = field[FieldKey.name.key] as? String ?? "";
        textField.leadingAssistiveLabel.text = helperText ?? " ";
        textField.inputAccessoryView = accessoryView;
        textField.keyboardType = .decimalPad;
        setPlaceholder(textField: textField);
        textField.sizeToFit();
        return textField;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil) {
        self.init(field: field, delegate: delegate, value: nil);
    }
    
    init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, value: String?) {
        super.init(field: field, delegate: delegate, value: value, editMode: editMode);
        
        self.min = self.field[FieldKey.min.key] as? NSNumber;
        self.max = self.field[FieldKey.max.key] as? NSNumber;
        
        setupInputView();
        setValue(value);
    }
    
    override func applyTheme(withScheme scheme: MDCContainerScheming) {
        super.applyTheme(withScheme: scheme);
        textField.applyTheme(withScheme: scheme);
    }
    
    func setupInputView() {
        if (editMode) {
            viewStack.addArrangedSubview(textField);
        } else {
            viewStack.addArrangedSubview(fieldNameLabel);
            viewStack.addArrangedSubview(fieldValue);
            fieldValue.text = getValue()?.stringValue;
        }
    }
    
    override func getValue() -> Any? {
        return number;
    }
    
    func getValue() -> NSNumber? {
        return number;
    }
    
    override func setValue(_ value: Any?) {
        setValue(value as? String);
    }
    
    func setValue(_ value: String?) {
        number = nil;
        if (value != nil) {
            number = formatter.number(from: value!);
        }
        if (editMode) {
            setTextFieldValue();
        } else {
            fieldValue.text = number?.stringValue;
        }
    }
    
    func setTextFieldValue() {
        textField.text = number?.stringValue
    }
    
    @objc func doneButtonPressed() {
        shouldResign = true;
        textField.resignFirstResponder();
    }
    
    @objc func cancelButtonPressed() {
        shouldResign = true;
        setTextFieldValue();
        textField.resignFirstResponder();
    }
    
    override func isEmpty() -> Bool{
        if let checkText = textField.text {
            return checkText.count == 0;
        }
        return true;
    }
    
    override func getErrorMessage() -> String {
        if let safeHelp = helperText {
            return safeHelp
        }
        return "Must be a number";
    }
    
    override func isValid(enforceRequired: Bool = false) -> Bool {
        return self.isValid(enforceRequired: enforceRequired, number: self.number);
    }
    
    func isValid(enforceRequired: Bool = false, number: NSNumber?) -> Bool {
        return super.isValid(enforceRequired: enforceRequired) && isValidNumber(number);
    }
    
    func isValidNumber(_ number: NSNumber?) -> Bool {
        if (!isEmpty() && number == nil) {
            return false;
        }
        if let check = number {
            if ((self.min != nil && self.max != nil &&
                    ((check.doubleValue < self.min!.doubleValue) || (check.doubleValue > self.max!.doubleValue)
                    )
                )
                || (self.min != nil && check.doubleValue < min!.doubleValue)
                || (self.max != nil && check.doubleValue > max!.doubleValue)) {
                    return false;
            }
        }
        return true;
    }
    
    override func setValid(_ valid: Bool) {
        super.setValid(valid);
        if (valid) {
            textField.leadingAssistiveLabel.text = helperText;
            if let safeScheme = scheme {
                textField.applyTheme(withScheme: safeScheme);
            }
        } else {
            textField.applyErrorTheme(withScheme: globalErrorContainerScheme());
            textField.leadingAssistiveLabel.text = getErrorMessage();
        }
    }
}

extension NumberFieldView: UITextFieldDelegate {
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return shouldResign;
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text: String = textField.text {
            let number = formatter.number(from: text);
            let valid = isValid(enforceRequired: true, number: number);
            setValid(valid);
            if (valid && (number == nil || (self.number?.stringValue != textField.text))) {
                delegate?.fieldValueChanged(field, value: number);
            }
            self.number = number;
        }
        shouldResign = false;
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // allow backspace
        if (string.count == 0) {
            return true;
        }
        
        if let text = textField.text as NSString? {
            let txtAfterUpdate = text.replacingCharacters(in: range, with: string);
            let number = formatter.number(from: txtAfterUpdate);
            if (number == nil) {
                return false;
            }
            setValid(isValidNumber(number));
            return true;
        }
        
        return false;
    }
}
