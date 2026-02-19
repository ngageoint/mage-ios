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
    private let emailValidationMessage = "Enter a valid email address";
    private var multilineOriginalText: String?;

    private var isEmailField: Bool {
        return field[FieldKey.type.key] as? String == FieldType.email.key
    }

    private var isRequiredField: Bool {
        return (field[FieldKey.required.key] as? Bool) == true
    }

    private lazy var emailAccessoryView: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 54));
        toolbar.autoSetDimension(.height, toSize: 54);

        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed));
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed));
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil);

        toolbar.items = [cancelBarButton, flexSpace, doneBarButton];
        return toolbar;
    }()

    private lazy var multilineAccessoryView: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 54));
        toolbar.autoSetDimension(.height, toSize: 54);

        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelMultilineButtonPressed));
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneMultilineButtonPressed));
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil);

        toolbar.items = [cancelBarButton, flexSpace, doneBarButton];
        return toolbar;
    }()

    lazy var multilineTextField: MDCFilledTextArea  = {
        let multilineTextField = MDCFilledTextArea(frame: CGRect(x: 0, y: 0, width: 200, height: 100));
        multilineTextField.textView.delegate = self;
        multilineTextField.textView.keyboardType = keyboardType;
        multilineTextField.textView.inputAccessoryView = multilineAccessoryView;
        if (field[FieldKey.type.key] as? String == FieldType.textarea.key) {
            multilineTextField.trailingView = UIImageView(image: UIImage(named: "text_fields"));
            multilineTextField.trailingViewMode = .always;
        }
        multilineTextField.textView.autocapitalizationType = .none;
        multilineTextField.textView.accessibilityLabel = field[FieldKey.name.key] as? String ?? "";
        multilineTextField.placeholder = field[FieldKey.title.key] as? String
        multilineTextField.leadingAssistiveLabel.text = " ";
        setPlaceholder(textArea: multilineTextField);
        if (value != nil) {
            multilineTextField.textView.text = value as? String;
        }
        multilineTextField.sizeToFit();
        return multilineTextField;
    }()
    
    lazy var textField: MDCFilledTextField = {
        let textField = MDCFilledTextField(frame: CGRect(x: 0, y: 0, width: 200, height: 100));
        textField.delegate = self;
        textField.keyboardType = keyboardType;
        if (field[FieldKey.type.key] as? String == FieldType.email.key) {
            textField.trailingView = UIImageView(image: UIImage(systemName: "envelope"));
            textField.trailingViewMode = .always;
        } else if (field[FieldKey.type.key] as? String == FieldType.textfield.key) {
            textField.trailingView = UIImageView(image: UIImage(named: "outline_title"));
            textField.trailingViewMode = .always;
        } else if (field[FieldKey.type.key] as? String == FieldType.password.key) {
            textField.trailingView = UIImageView(image: UIImage(systemName: "lock"));
            textField.trailingViewMode = .always;
        }
        textField.autocapitalizationType = .none;
        textField.accessibilityLabel = field[FieldKey.name.key] as? String ?? "";
        textField.leadingAssistiveLabel.text = " ";
        setPlaceholder(textField: textField);
        if (value != nil) {
            textField.text = value as? String;
        }
        if (isEmailField) {
            textField.inputAccessoryView = emailAccessoryView;
            textField.addTarget(self, action: #selector(emailTextChanged), for: .editingChanged);
        }
        textField.sizeToFit();
        return textField;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }

    func focusField() -> Bool {
        if (multiline) {
            multilineTextField.textView.becomeFirstResponder()
        } else {
            textField.becomeFirstResponder()
        }
        return true
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
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            if (editMode) {
                if (multiline) {
                    multilineTextField.autoPinEdgesToSuperviewEdges();
                } else {
                    textField.autoPinEdgesToSuperviewEdges();
                }
            } else {
                
            }
        }
        super.updateConstraints();
    }
    
    override func applyTheme(withScheme scheme: MDCContainerScheming?) {
        guard let scheme = scheme else {
            return
        }

        super.applyTheme(withScheme: scheme);
        if (multiline) {
            multilineTextField.applyTheme(withScheme: scheme);
            multilineTextField.trailingView?.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
            multilineTextField.textView.tintColor = scheme.colorScheme.onSurfaceColor;
        } else {
            textField.applyTheme(withScheme: scheme);
            textField.trailingView?.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
            textField.tintColor = scheme.colorScheme.onSurfaceColor;
        }
    }
    
    func addFieldView() {
        if (editMode) {
            if (multiline) {
                self.addSubview(multilineTextField);
            } else {
                self.addSubview(textField);
            }
        } else {
            viewStack.addArrangedSubview(fieldNameLabel);
            viewStack.addArrangedSubview(fieldValue);
            if (field[FieldKey.type.key] as? String == FieldType.password.key) {
                fieldValue.text = "*********";
            } else {
                fieldValue.text = getValue();
            }
        }
    }
    
    override func setValue(_ value: Any?) {
        self.setValue(value as? String);
    }
    
    func setValue(_ value: String?) {
        self.value = value;
        if (self.multiline) {
            self.editMode ? (multilineTextField.textView.text = value) : (fieldValue.text = value);
        } else {
            self.editMode ? (textField.text = value) : (fieldValue.text = value);
        }
    }
    
    func getValue() -> String? {
        return value as? String;
    }
    
    override func isEmpty() -> Bool {
        if (self.multiline) {
            return (multilineTextField.textView.text ?? "").count == 0;
        } else {
            return (textField.text ?? "").count == 0;
        }
    }
    
    override func getErrorMessage() -> String {
        return ((field[FieldKey.title.key] as? String) ?? "Field ") + " is required";
    }
    
    override func setValid(_ valid: Bool) {
        super.setValid(valid);
        if (valid) {
            if (multiline) {
                multilineTextField.leadingAssistiveLabel.text = " ";
                if let scheme = scheme {
                    multilineTextField.applyTheme(withScheme: scheme);
                }
            } else {
                textField.leadingAssistiveLabel.text = " ";
                if let scheme = scheme {
                    textField.applyTheme(withScheme: scheme);
                }
            }
        } else {
            if (multiline) {
                multilineTextField.applyErrorTheme(withScheme: globalErrorContainerScheme());
                multilineTextField.leadingAssistiveLabel.text = getErrorMessage();
            } else {
                textField.applyErrorTheme(withScheme: globalErrorContainerScheme());
                textField.leadingAssistiveLabel.text = getErrorMessage();
            }
        }
    }

    override func isValid(enforceRequired: Bool = false) -> Bool {
        if !super.isValid(enforceRequired: enforceRequired) {
            return false
        }
        if isEmailField {
            return validateEmailText(textField.text)
        }
        return true
    }

    private func validateEmailText(_ text: String?) -> Bool {
        let trimmed = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines);
        if trimmed.isEmpty {
            return !isRequiredField
        }
        let pattern = "^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$";
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: trimmed);
    }

    private func updateEmailValidationState(for text: String?) {
        let isValid = validateEmailText(text);
        if isValid {
            setValid(true);
            return
        }
        textField.applyErrorTheme(withScheme: globalErrorContainerScheme());
        textField.leadingAssistiveLabel.text = emailValidationMessage;
    }

    @objc private func emailTextChanged() {
        updateEmailValidationState(for: textField.text);
    }
}

extension TextFieldView {
    func resignFieldFirstResponder() {
        if (self.multiline) {
            multilineTextField.textView.resignFirstResponder();
        } else {
            textField.resignFirstResponder();
        }
    }
    
    @objc func doneButtonPressed() {
        self.resignFieldFirstResponder();
    }
    
    @objc func cancelButtonPressed() {
        setValue(self.value as? String ?? nil);
        if isEmailField && !isRequiredField {
            setValid(true);
        }
        self.resignFieldFirstResponder();
    }

    @objc func cancelMultilineButtonPressed() {
        setValue(multilineOriginalText);
        self.resignFieldFirstResponder();
    }

    @objc func doneMultilineButtonPressed() {
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

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let formView = findObservationFormView(),
           formView.focusNextTextField(after: self) {
            return false
        }
        textField.resignFirstResponder()
        return true
    }
}

extension TextFieldView {
    private func findObservationFormView() -> ObservationFormView? {
        var currentView: UIView? = self
        while let view = currentView {
            if let formView = view as? ObservationFormView {
                return formView
            }
            currentView = view.superview
        }
        return nil
    }
}

extension TextFieldView: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        multilineOriginalText = textView.text
    }

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
