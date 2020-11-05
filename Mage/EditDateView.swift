//
//  EditDateView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/7/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCTextField;

class EditDateView : BaseFieldView {
    private var date: Date?;
    
    internal lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker();
        datePicker.accessibilityLabel = (field[FieldKey.name.key] as? String ?? "") + " Date Picker";
        datePicker.datePickerMode = .dateAndTime;
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
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
    
    lazy var textField: MDCTextField = {
        let textField = MDCTextField(forAutoLayout: ());
        textField.delegate = self;
        textField.accessibilityLabel = field[FieldKey.name.key] as? String ?? "";
        textField.inputView = datePicker;
        textField.inputAccessoryView = dateAccessoryView;
        
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
        date = nil;
        setValue(value);
        setupController();
    }
    
    func setTextFieldValue() {
        if (self.value != nil) {
            textField.text = (datePicker.date as NSDate).formattedDisplay();
        } else {
            textField.text = nil;
        }
    }
    
    @objc func dateChanged() {
        date = datePicker.date;
        textField.text = (datePicker.date as NSDate).formattedDisplay();
    }
    
    @objc func doneButtonPressed() {
        textField.resignFirstResponder();
    }
    
    @objc func cancelButtonPressed() {
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
    
    func setValue(_ value: String?) {
        if (value != nil) {
            self.value = formatter.date(from: value!);
            datePicker.date = (self.value as? Date)!;
            textField.text = (datePicker.date as NSDate).formattedDisplay();
        } else {
            datePicker.date = Date();
            textField.text = nil;
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

extension EditDateView: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.date = nil;
        self.delegate?.observationField(self.field, valueChangedTo: nil, reloadCell: false);
        return true;
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        date = datePicker.date;
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if (range.length == textField.text?.count && string == "") {
            self.date = nil;
            textField.text = "";
            self.delegate?.observationField(self.field, valueChangedTo: nil, reloadCell: false);
        }
        return false;
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let newDate = self.date {
            if (self.value as? Date != newDate) {
                self.value = newDate;
                self.dateChanged();
                self.delegate?.observationField(self.field, valueChangedTo: formatter.string(from: newDate), reloadCell: false);
            }
            datePicker.date = newDate;
        } else {
            datePicker.date = Date()
        }
    }
}
