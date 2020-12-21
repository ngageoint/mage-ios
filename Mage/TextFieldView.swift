//
//  TextFieldView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/6/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCTextField;

class TextFieldView : BaseFieldView {
    private var multiline: Bool = false;
    private var keyboardType: UIKeyboardType = .default;
    
    lazy var multilineTextField: MDCMultilineTextField = {
        let multilineTextField = MDCMultilineTextField(forAutoLayout: ());
        multilineTextField.textView?.delegate = self;
        multilineTextField.textView?.inputAccessoryView = accessoryView;
        multilineTextField.textView?.keyboardType = keyboardType;
        multilineTextField.textView?.autocapitalizationType = .none;
        multilineTextField.textView?.accessibilityLabel = field[FieldKey.name.key] as? String ?? "";
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
        textField.autocapitalizationType = .none;
        textField.accessibilityLabel = field[FieldKey.name.key] as? String ?? "";
        controller.textInput = textField;
        if (value != nil) {
            textField.text = value as? String;
        }
        return textField;
    }()
    
    private lazy var accessoryView: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44));
        toolbar.autoSetDimension(.height, toSize: 44);
        
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed));
        doneBarButton.accessibilityLabel = "Done";
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed));
        cancelBarButton.accessibilityLabel = "Cancel";
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil);
        
        toolbar.items = [cancelBarButton, flexSpace, doneBarButton];
        return toolbar;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, keyboardType: UIKeyboardType = .default) {
        self.init(field: field, editMode: editMode, delegate: delegate, value: nil, multiline: false, keyboardType: keyboardType);
    }
    
    convenience init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, multiline: Bool, keyboardType: UIKeyboardType = .default) {
        self.init(field: field, editMode: editMode, delegate: delegate, value: nil, multiline: multiline);
    }
    
    init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, value: String?, multiline: Bool = false, keyboardType: UIKeyboardType = .default) {
        super.init(field: field, delegate: delegate, value: value, editMode: editMode);
        self.multiline = multiline;
        self.keyboardType = keyboardType;
        self.addFieldView();
    }
    
    func addFieldView() {
        if (editMode) {
            if (multiline) {
                self.addSubview(multilineTextField);
                multilineTextField.autoPinEdgesToSuperviewEdges();
            } else {
                self.addSubview(textField);
                textField.autoPinEdgesToSuperviewEdges();
            }
            setupController();
        } else {
            viewStack.addArrangedSubview(fieldNameLabel);
            viewStack.addArrangedSubview(fieldValue);
            fieldValue.text = getValue();
        }
    }
    
    override func setValue(_ value: Any) {
        self.setValue(value as? String);
    }
    
    func setValue(_ value: String?) {
        self.value = value;
        if (self.multiline) {
            self.editMode ? (multilineTextField.text = value) : (fieldValue.text = value);
        } else {
            self.editMode ? (textField.text = value) : (fieldValue.text = value);
        }
    }
    
    func getValue() -> String? {
        return value as? String;
    }
    
    override func isEmpty() -> Bool {
        if (self.multiline) {
            return (multilineTextField.text ?? "").count == 0;
        } else {
            return (textField.text ?? "").count == 0;
        }
    }
    
    override func getErrorMessage() -> String {
        return ((field[FieldKey.title.key] as? String) ?? "Field ") + " is required";
    }
}

extension TextFieldView {
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

extension TextFieldView: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if (value as? String != textField.text) {
            if (textField.text == "") {
                value = nil;
            } else {
                value = textField.text;
            }
            delegate?.fieldValueChanged(field, value: value);
        }
    }
}

extension TextFieldView: UITextViewDelegate {
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if (value as? String != textView.text) {
            if (textView.text == "") {
                value = nil;
            } else {
                value = textView.text;
            }
            delegate?.fieldValueChanged(field, value: value);
        }
    }
}
