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
    private var number: NSNumber?;
    private var min: NSNumber?;
    private var max: NSNumber?;

    private let fieldUndoManager = UndoManager()
    private var sessionStartValue: String?

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

    lazy var textField: MDCFilledTextField = {
        let textField = MDCFilledTextField(frame: CGRect(x: 0, y: 0, width: 200, height: 100));
        textField.delegate = self;
        textField.trailingView = UIImageView(image: UIImage(systemName: "number"));
        textField.trailingViewMode = .always;
        textField.accessibilityLabel = field[FieldKey.name.key] as? String ?? "";
        textField.leadingAssistiveLabel.text = helperText ?? " ";
        textField.inputAccessoryView = accessoryView;
        textField.keyboardType = .decimalPad;
        setPlaceholder(textField: textField);
        textField.sizeToFit();
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged);
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

    override func applyTheme(withScheme scheme: MDCContainerScheming?) {
        guard let scheme = scheme else {
            return
        }

        super.applyTheme(withScheme: scheme);
        textField.applyTheme(withScheme: scheme);
        textField.trailingView?.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        textField.tintColor = scheme.colorScheme.onSurfaceColor;
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

    private func setUndoableText(_ newText: String?, oldText: String?) {
        fieldUndoManager.registerUndo(withTarget: self) { target in
            target.setUndoableText(oldText, oldText: newText)
        }
        setValue(newText)
        let valid = isValid(enforceRequired: true, number: number)
        setValid(valid)
        delegate?.fieldValueChanged(field, value: number)
        refreshUndoRedoButtons()
    }

    private func refreshUndoRedoButtons() {
        let hasUncommittedChange = textField.text != sessionStartValue
        undoButton.isEnabled = fieldUndoManager.canUndo || hasUncommittedChange
        redoButton.isEnabled = fieldUndoManager.canRedo
    }

    private func closeCurrentSession() {
        let currentText = textField.text
        guard sessionStartValue != currentText else { return }
        let number = formatter.number(from: currentText ?? "")
        let valid = isValid(enforceRequired: true, number: number)
        setValid(valid)
        if valid {
            setUndoableText(currentText, oldText: sessionStartValue)
            sessionStartValue = currentText
        } else {
            self.number = number
        }
    }

    @objc func undoPressed() {
        closeCurrentSession()
        if fieldUndoManager.canUndo {
            fieldUndoManager.undo()
        }
        sessionStartValue = textField.text
        refreshUndoRedoButtons()
    }

    @objc func redoPressed() {
        if fieldUndoManager.canRedo {
            fieldUndoManager.redo()
        }
        sessionStartValue = textField.text
        refreshUndoRedoButtons()
    }

    override func isEmpty() -> Bool {
        if let checkText = textField.text {
            return checkText.count == 0;
        }
        return true;
    }

    override func getErrorMessage() -> String {
        if let helperText = helperText {
            return helperText
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
            if let scheme = scheme {
                textField.applyTheme(withScheme: scheme);
                textField.tintColor = scheme.colorScheme.onSurfaceColor;
            }
        } else {
            textField.applyErrorTheme(withScheme: globalErrorContainerScheme());
            textField.leadingAssistiveLabel.text = getErrorMessage();
        }
    }
}

extension NumberFieldView {
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
}

extension NumberFieldView: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        sessionStartValue = textField.text
        accessoryView.alpha = shouldShowAccessoryView() ? 1 : 0;
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true;
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        let newText = textField.text
        let number = formatter.number(from: newText ?? "")
        let valid = isValid(enforceRequired: true, number: number)
        setValid(valid)
        if valid, sessionStartValue != newText {
            setUndoableText(newText, oldText: sessionStartValue)
        } else {
            self.number = number
        }
        sessionStartValue = nil
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
