//
//  DateView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/7/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCTextField;

class DateView : BaseFieldView {
    private var date: Date?;
    private var shouldResign: Bool = false;
    
    internal lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker();
        datePicker.accessibilityLabel = (field[FieldKey.name.key] as? String ?? "") + " Date Picker";
        datePicker.datePickerMode = .dateAndTime;
        datePicker.preferredDatePickerStyle = .wheels
        if (NSDate.isDisplayGMT()) {
            datePicker.timeZone = TimeZone(secondsFromGMT: 0);
        } else {
            datePicker.timeZone = TimeZone.current;
        }
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        return datePicker;
    }()
    
    private lazy var timeZoneLabel: UILabel = {
        let label = UILabel(forAutoLayout: ());
        label.text = datePicker.timeZone?.identifier;
        label.sizeToFit();
        return label;
    }()
    
    private lazy var formatter: DateFormatter = {
        let formatter = DateFormatter();
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
        formatter.locale = Locale(identifier: "en_US_POSIX");
        return formatter;
    }()
    
    private lazy var dateAccessoryView: UIToolbar = {
        // this frame is to prevent breaking constraints
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44));
        toolbar.autoSetDimension(.height, toSize: 44);
        
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed));
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed));
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil);
        
        toolbar.items = [cancelBarButton, flexSpace, UIBarButtonItem(customView: timeZoneLabel), flexSpace, doneBarButton];
        return toolbar;
    }()
    
    lazy var textField: MDCFilledTextField = {
        let textField = MDCFilledTextField(frame: CGRect(x: 0, y: 0, width: 200, height: 100));
        textField.delegate = self;
        textField.accessibilityLabel = field[FieldKey.name.key] as? String ?? "";
        textField.inputView = datePicker;
        textField.inputAccessoryView = dateAccessoryView;
        textField.leadingAssistiveLabel.text = " ";
        textField.trailingView = UIImageView(image: UIImage(named: "today"));
        textField.trailingViewMode = .always;
        textField.sizeToFit();
        return textField;
    }()
    
    override func applyTheme(withScheme scheme: MDCContainerScheming) {
        super.applyTheme(withScheme: scheme);
        textField.applyTheme(withScheme: scheme);
        textField.trailingView?.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil) {
        self.init(field: field, editMode: editMode, delegate: delegate, value: nil);
    }
    
    init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, value: String?) {
        super.init(field: field, delegate: delegate, value: value, editMode: editMode);
        date = nil;
        addFieldView();
        setValue(value);
    }
    
    func addFieldView() {
        if (editMode) {
            viewStack.addArrangedSubview(textField);
            setPlaceholder(textField: textField);
        } else {
            viewStack.addArrangedSubview(fieldNameLabel);
            viewStack.addArrangedSubview(fieldValue);
        }
    }
    
    func setTextFieldValue() {
        if (self.value != nil) {
            textField.text = (datePicker.date as NSDate).formattedDisplay();
            textField.clearButtonMode = .always;
            textField.trailingViewMode = .never;
        } else {
            textField.text = nil;
            textField.clearButtonMode = .never;
            textField.trailingViewMode = .always;
        }
    }
    
    @objc func dateChanged() {
        date = datePicker.date;
        textField.text = (datePicker.date as NSDate).formattedDisplay();
        textField.clearButtonMode = .always;
        textField.trailingViewMode = .never;
    }
    
    @objc func doneButtonPressed() {
        shouldResign = true;
        textField.resignFirstResponder();
    }
    
    @objc func cancelButtonPressed() {
        shouldResign = true;
        date = value as? Date;
        if let safeDate = date {
            datePicker.date = safeDate;
        }
        setTextFieldValue();
        textField.resignFirstResponder();
    }
    
    override func isEmpty() -> Bool{
        return (textField.text ?? "").count == 0
    }
    
    override func setValue(_ value: Any?) {
        self.setValue(value as? String)
    }
    
    func setValue(_ value: String?) {
        datePicker.date = Date();
        editMode ? (textField.text = nil) : (fieldValue.text = nil);
        
        if let safeValue = value {
            self.value = formatter.date(from: safeValue);
            if let safeDate = self.value as? Date {
                datePicker.date = safeDate;
                editMode ? (textField.text = (datePicker.date as NSDate).formattedDisplay()) : (fieldValue.text = (datePicker.date as NSDate).formattedDisplay());
                textField.clearButtonMode = .always;
                textField.trailingViewMode = .never;
            } else{
                textField.clearButtonMode = .never;
                textField.trailingViewMode = .always;
            }
        }
    }
    
    override func getErrorMessage() -> String {
        return ((field[FieldKey.title.key] as? String) ?? "Field ") + " is required";
    }
    
    override func setValid(_ valid: Bool) {
        super.setValid(valid);
        if (valid) {
            textField.leadingAssistiveLabel.text = " ";
            if let scheme = scheme {
                textField.applyTheme(withScheme: scheme);
            }
        } else {
            textField.applyErrorTheme(withScheme: globalErrorContainerScheme());
            textField.leadingAssistiveLabel.text = getErrorMessage();
        }
    }
}

extension DateView: UITextFieldDelegate {
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return shouldResign;
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.date = nil;
        self.value = nil;
        delegate?.fieldValueChanged(field, value: nil);
        return true;
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        date = datePicker.date;
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if (range.length == textField.text?.count && string == "") {
            self.date = nil;
            textField.text = "";
            self.value = nil;
            delegate?.fieldValueChanged(field, value: nil);
        }
        return false;
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let newDate = self.date {
            if (self.value as? Date != newDate) {
                self.value = newDate;
                self.dateChanged();
                delegate?.fieldValueChanged(field, value: formatter.string(from: newDate));
            }
            datePicker.date = newDate;
        } else {
            datePicker.date = Date()
        }
        shouldResign = false;
    }
}
