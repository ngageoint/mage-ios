//
//  EditTextFieldView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/6/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCTextField;

class EditTextFieldView : BaseFieldView {
    private var multiline: Bool = false;
    private var keyboardType: UIKeyboardType = .default;
    
    lazy var multilineTextField: MDCMultilineTextField = {
        let multilineTextField = MDCMultilineTextField(forAutoLayout: ());
        multilineTextField.textView?.delegate = self;
        multilineTextField.textView?.inputAccessoryView = accessoryView;
        multilineTextField.textView?.keyboardType = keyboardType;
        controller.textInput = multilineTextField;
        if (value != nil) {
            multilineTextField.text = value as? String;
        }
        return multilineTextField;
    }()
    
    lazy var textField: MDCTextField = {
        let textField = MDCTextField(forAutoLayout: ());
        textField.delegate = self;
        textField.inputAccessoryView = accessoryView;
        textField.keyboardType = keyboardType;
        controller.textInput = textField;
        if (value != nil) {
            textField.text = value as? String;
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
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(field: [String: Any], delegate: ObservationEditListener? = nil, keyboardType: UIKeyboardType = .default) {
        self.init(field: field, delegate: delegate, value: nil, multiline: false, keyboardType: keyboardType);
    }
    
    convenience init(field: [String: Any], delegate: ObservationEditListener? = nil, multiline: Bool, keyboardType: UIKeyboardType = .default) {
        self.init(field: field, delegate: delegate, value: nil, multiline: multiline);
    }
    
    init(field: [String: Any], delegate: ObservationEditListener? = nil, value: String?, multiline: Bool = false, keyboardType: UIKeyboardType = .default) {
        super.init(field: field, delegate: delegate, value: value);
        self.multiline = multiline;
        self.keyboardType = keyboardType;
        self.addFieldView();
        setupController();
    }
    
    func addFieldView() {
        if (multiline) {
            self.addSubview(multilineTextField);
            multilineTextField.autoPinEdgesToSuperviewEdges();
        } else {
            self.addSubview(textField);
            textField.autoPinEdgesToSuperviewEdges();
        }
    }
    
    func setValue(_ value: String?) {
        if (self.multiline) {
            multilineTextField.text = value;
        } else {
            textField.text = value;
        }
    }
    
    override func isEmpty() -> Bool {
        if (self.multiline) {
            return (multilineTextField.text ?? "").count == 0;
        } else {
            return (textField.text ?? "").count == 0;
        }
    }
    
    override func setValid(_ valid: Bool) {
        if (valid) {
            controller.setErrorText(nil, errorAccessibilityValue: nil);
        } else {
            controller.setErrorText(((field[FieldKey.title.key] as? String) ?? "Field ") + " is required", errorAccessibilityValue: nil);
        }
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
        setValue(self.value as? String ?? nil);
        self.resignFieldFirstResponder();
    }
}

extension EditTextFieldView: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if (value as? String != textField.text) {
            value = textField.text;
            self.delegate?.observationField(self.field, valueChangedTo: value, reloadCell: false);
        }
    }
}

extension EditTextFieldView: UITextViewDelegate {
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if (value as? String != textView.text) {
            value = textView.text;
            self.delegate?.observationField(self.field, valueChangedTo: value, reloadCell: false);
        }
    }
}
