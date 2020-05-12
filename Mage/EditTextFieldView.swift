//
//  EditTextFieldView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/6/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCTextField;

class EditTextFieldView : UIView {
    private var controller: MDCTextInputControllerUnderline = MDCTextInputControllerUnderline();
    private var field: NSDictionary!;
    private var multiline: Bool = false;
    private var value: String?;
    private var delegate: ObservationEditListener?;
    
    lazy var multilineTextField: MDCMultilineTextField = {
        let multilineTextField = MDCMultilineTextField(forAutoLayout: ());
        multilineTextField.textView?.delegate = self;
        controller.textInput = multilineTextField;
        if (value != nil) {
            multilineTextField.text = value;
        }
        return multilineTextField;
    }()
    
    lazy var textField: MDCTextField = {
        let textField = MDCTextField(forAutoLayout: ());
        textField.delegate = self;
        controller.textInput = textField;
        if (value != nil) {
            textField.text = value;
        }
        return textField;
    }()
    
    private lazy var accessoryView: UIToolbar = {
        let toolbar = UIToolbar(forAutoLayout: ());
        toolbar.autoSetDimension(.height, toSize: 44);
        
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed));
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed));
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil);
        
        toolbar.items = [cancelBarButton, flexSpace, doneBarButton];
        return toolbar;
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureForAutoLayout();
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(field: NSDictionary, value: Any? = nil, multiline: Bool = false, delegate: ObservationEditListener? = nil) {
        self.init(frame: CGRect.zero);
        self.configureForAutoLayout();
        self.field = field;
        self.multiline = multiline;
        self.value = value as? String;
        self.delegate = delegate;
        if (multiline) {
            self.addSubview(multilineTextField);
            multilineTextField.autoPinEdgesToSuperviewEdges();
        } else {
            self.addSubview(textField);
            textField.autoPinEdgesToSuperviewEdges();
        }
        controller.placeholderText = field.object(forKey: "title") as? String
        if ((field.object(forKey: "required") as? Bool) == true) {
            controller.placeholderText = (controller.placeholderText ?? "") + " *"
        }
//        controller?.setErrorText("error text", errorAccessibilityValue: nil);
//        controller?.helperText = "Helper text";
    }
    
    func setValue(_ value: Any?) {
        if (self.multiline) {
            multilineTextField.text = value as? String;
        } else {
            textField.text = value as? String;
        }
    }
    
    func isEmpty() -> Bool {
        if (self.multiline) {
            return (multilineTextField.text ?? "").count == 0;
        } else {
            return (textField.text ?? "").count == 0;
        }
    }
    
    func setValid(_ valid: Bool) {
        if (valid) {
            controller.setErrorText(nil, errorAccessibilityValue: nil);
        } else {
            controller.setErrorText(((field.object(forKey: "title") as? String) ?? "Field ") + " is required", errorAccessibilityValue: nil);
        }
    }
    
    func isValid(enforceRequired: Bool = false) -> Bool {
        if ((field.object(forKey: "required") as? Bool) == true && enforceRequired && isEmpty()) {
            return false;
        }
        return true;
    }
}

// Toolbar methods
extension EditTextFieldView {
    func resignFieldFirstResponder() {
        if (self.multiline) {
            multilineTextField.resignFirstResponder();
        } else {
            textField.resignFirstResponder();
        }
    }
    
    @objc func doneButtonPressed() {
        self.resignFieldFirstResponder();
    }
    
    @objc func cancelButtonPressed() {
        setValue(self.value ?? nil);
        self.resignFieldFirstResponder();
    }
}

extension EditTextFieldView: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if (value != textField.text) {
            value = textField.text;
            self.delegate?.observationField(self.field, valueChangedTo: value, reloadCell: false);
        }
    }
}

extension EditTextFieldView: UITextViewDelegate {
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if (value != textField.text) {
            value = textField.text;
            self.delegate?.observationField(self.field, valueChangedTo: value, reloadCell: false);
        }
    }
}
