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

    private let fieldUndoManager = UndoManager()
    private var sessionStartValue: String?

    lazy var multilineTextField: MDCFilledTextArea  = {
        let multilineTextField = MDCFilledTextArea(frame: CGRect(x: 0, y: 0, width: 200, height: 100));
        multilineTextField.textView.delegate = self;
        multilineTextField.textView.inputAccessoryView = accessoryView;
        multilineTextField.textView.keyboardType = keyboardType;
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
        textField.inputAccessoryView = accessoryView;
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
        textField.sizeToFit();
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged);
        return textField;
    }()

    // Undo/Redo components
    private lazy var undoButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "arrow.uturn.backward"),
            style: .plain,
            target: self,
            action: #selector(undoPressed)
        );
        button.accessibilityLabel = "Undo";
        button.isEnabled = false;
        return button;
    }()

    private lazy var redoButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "arrow.uturn.forward"),
            style: .plain,
            target: self,
            action: #selector(redoPressed)
        );
        button.accessibilityLabel = "Redo";
        button.isEnabled = false;
        return button;
    }()

    private lazy var accessoryView: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44));
        toolbar.autoSetDimension(.height, toSize: 60);
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil);
        toolbar.items = [undoButton, redoButton, flexSpace];
        toolbar.alpha = 0;
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

    override func updateConstraints() {
        if (!didSetupConstraints) {
            if (editMode) {
                if (multiline) {
                    multilineTextField.autoPinEdgesToSuperviewEdges();
                } else {
                    textField.autoPinEdgesToSuperviewEdges();
                }
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

    private func setUndoableValue(_ newValue: String?, oldValue: String?) {
        fieldUndoManager.registerUndo(withTarget: self) {
            target in target.setUndoableValue(oldValue, oldValue: newValue)
        }
        setValue(newValue)
        delegate?.fieldValueChanged(field, value: newValue)
        refreshUndoRedoButtons()
    }

    private func refreshUndoRedoButtons() {
        let currentText = multiline ? multilineTextField.textView.text : textField.text
        let hasUncommittedChange = (currentText == "" ? nil : currentText) != sessionStartValue
        undoButton.isEnabled = fieldUndoManager.canUndo || hasUncommittedChange
        redoButton.isEnabled = fieldUndoManager.canRedo
    }

    private func closeCurrentSession() {
        let currentText = multiline ? multilineTextField.textView.text : textField.text
        let newValue = currentText == "" ? nil : currentText
        if sessionStartValue != newValue {
            setUndoableValue(newValue, oldValue: sessionStartValue)
            sessionStartValue = newValue
        }
    }

    func setValue(_ value: String?) {
        self.value = value;
        if (self.multiline) {
            self.editMode ? (multilineTextField.textView.text = value) : (fieldValue.text = value);
            if (self.editMode) {
                multilineTextField.setNeedsLayout()
                multilineTextField.layoutIfNeeded()
            }
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
}

extension TextFieldView {
    func resignFieldFirstResponder() {
        if (self.multiline) {
            multilineTextField.textView.resignFirstResponder();
        } else {
            textField.resignFirstResponder();
        }
    }

    @objc func textFieldDidChange() {
        showAccessoryView();
        refreshUndoRedoButtons()
    }

    func showAccessoryView() {
        guard accessoryView.alpha == 0 else { return }
        UIView.animate(withDuration: 0.2) {
            self.accessoryView.alpha = 1;
        }
    }

    func shouldShowAccessoryView() -> Bool {
        return !isEmpty() || fieldUndoManager.canUndo || fieldUndoManager.canRedo
    }

    @objc func undoPressed() {
        closeCurrentSession()
        if fieldUndoManager.canUndo {
            fieldUndoManager.undo()
        }
        sessionStartValue = value as? String
        refreshUndoRedoButtons()
    }

    @objc func redoPressed() {
        if fieldUndoManager.canRedo {
            fieldUndoManager.redo()
        }
        sessionStartValue = value as? String
        refreshUndoRedoButtons()
    }
}

extension TextFieldView: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        sessionStartValue = value as? String
        accessoryView.alpha = shouldShowAccessoryView() ? 1 : 0;
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true;
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        let newValue = textField.text == "" ? nil : textField.text
        if sessionStartValue != newValue {
            setUndoableValue(newValue, oldValue: sessionStartValue)
        }
        sessionStartValue = nil
    }
}

extension TextFieldView: UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
        sessionStartValue = value as? String
        accessoryView.alpha = shouldShowAccessoryView() ? 1 : 0;
    }

    func textViewDidChange(_ textView: UITextView) {
        showAccessoryView();
        refreshUndoRedoButtons()
    }

    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return true;
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        let newValue = textView.text == "" ? nil : textView.text
        if sessionStartValue != newValue {
            setUndoableValue(newValue, oldValue: sessionStartValue)
        }
        sessionStartValue = nil
    }
}
