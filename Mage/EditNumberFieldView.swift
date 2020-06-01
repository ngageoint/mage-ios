//
//  EditNumberFieldView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/26/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCTextField;

class EditNumberFieldView : BaseFieldView {
    private var number: NSNumber?;
    private var min: NSNumber?;
    private var max: NSNumber?;
    
    private lazy var helperText: String? = {
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
    
    private lazy var titleLabel: UILabel = {
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
        let toolbar = UIToolbar(forAutoLayout: ());
        toolbar.autoSetDimension(.height, toSize: 44);
        
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed));
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed));
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil);
        
        toolbar.items = [cancelBarButton, flexSpace, UIBarButtonItem(customView: titleLabel), flexSpace, doneBarButton];
        return toolbar;
    }()
    
    lazy var textField: MDCTextField = {
        let textField = MDCTextField(forAutoLayout: ());
        textField.delegate = self;
        controller.textInput = textField;
        self.addSubview(textField);
        textField.sizeToFit();
        textField.autoPinEdgesToSuperviewEdges();
        return textField;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(field: [String: Any], delegate: ObservationEditListener? = nil) {
        self.init(field: field, delegate: delegate, value: nil);
    }
    
    init(field: [String: Any], delegate: ObservationEditListener? = nil, value: String?) {
        super.init(field: field, delegate: delegate, value: value);
        
        self.min = self.field[FieldKey.min.key] as? NSNumber;
        self.max = self.field[FieldKey.max.key] as? NSNumber;
        
        setValue(value);
        setupInputView(textField: textField);
        setupController();
        controller.helperText = helperText;
    }
    
    func setupInputView(textField: MDCTextField) {
        textField.inputAccessoryView = accessoryView;
        textField.keyboardType = .decimalPad;
    }
    
    override func getValue() -> Any? {
        return number;
    }
    
    func setValue(_ value: String?) {
        number = nil;
        if (value != nil) {
            number = formatter.number(from: value!);
        }
        setTextFieldValue();
    }
    
    func setTextFieldValue() {
        if (self.number != nil) {
            textField.text = number?.stringValue
        } else {
            textField.text = nil;
        }
    }
    
    @objc func doneButtonPressed() {
        textField.resignFirstResponder();
    }
    
    @objc func cancelButtonPressed() {
        setTextFieldValue();
        textField.resignFirstResponder();
    }
    
    override func isEmpty() -> Bool{
        if let checkText = textField.text {
            return checkText.count == 0;
        }
        return true;
    }
    
    override func setValid(_ valid: Bool) {
        if (valid) {
            controller.setErrorText(nil, errorAccessibilityValue: nil);
        } else {
            if (helperText != nil) {
                controller.setErrorText(helperText, errorAccessibilityValue: nil);
            } else {
                print("MUST BE A NUMBER")
                controller.setErrorText("Must be a number", errorAccessibilityValue: nil);
            }
        }
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
}

extension EditNumberFieldView: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text: String = textField.text {
            let number = formatter.number(from: text);
            if (number == nil) {
                if (self.number != nil) {
                    textField.text = formatter.string(from: self.number!);
                }
                return;
            }
            let valid = isValid(enforceRequired: true, number: number);
            setValid(valid);
            if (valid && self.number?.stringValue != textField.text) {
                self.number = number;
                self.delegate?.observationField(field, valueChangedTo: self.number, reloadCell: false);
            }
        }
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
