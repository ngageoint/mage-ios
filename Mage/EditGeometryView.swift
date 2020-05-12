//
//  EditGeometryView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/8/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCTextField;

class EditGeometryView : UIView, UITextFieldDelegate {
    private var controller: MDCTextInputControllerUnderline?;
    private var field: NSDictionary?;
    private var textField: MDCTextField?;
    private var date: Date?;
    private var value: Date?;
    private var delegate: ObservationEditListener?;
    
    private lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker();
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
        let toolbar = UIToolbar(forAutoLayout: ());
        toolbar.autoSetDimension(.height, toSize: 44);
        
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed));
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed));
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil);
        
        toolbar.items = [cancelBarButton, flexSpace, UIBarButtonItem(customView: timeZoneLabel), flexSpace, doneBarButton];
        return toolbar;
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.translatesAutoresizingMaskIntoConstraints = false;
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(field: NSDictionary, value: Any?, delegate: ObservationEditListener) {
        self.init(frame: CGRect.zero)
        self.field = field;
        controller = MDCTextInputControllerUnderline()
        textField = createTextField(value);
        textField?.sizeToFit();
        textField?.autoPinEdgesToSuperviewEdges();
        controller?.placeholderText = field.object(forKey: "title") as? String
        //        controller?.setErrorText("error text", errorAccessibilityValue: nil);
        //        controller?.helperText = "Helper text";
    }
    
    func createTextField(_ value: Any?) -> MDCTextField {
        date = nil;
        let textField = MDCTextField(forAutoLayout: ());
        
        controller?.textInput = textField;
        self.addSubview(textField);
        if (value != nil) {
            
            self.value = formatter.date(from: (value as? String)!);
            datePicker.date = self.value!;
            textField.text = (datePicker.date as NSDate).formattedDisplay();
        } else {
            self.value = nil;
            datePicker.date = Date();
        }
        setupInputView(textField: textField);
        textField.delegate = self;
        return textField;
    }
    
    func setTextFieldValue() {
        if (self.value != nil) {
            textField?.text = (datePicker.date as NSDate).formattedDisplay();
        } else {
            textField?.text = nil;
        }
    }
    
    func setupInputView(textField: MDCTextField) {
        textField.inputView = datePicker;
        textField.inputAccessoryView = dateAccessoryView;
    }
    
    @objc func dateChanged() {
        date = datePicker.date;
        textField?.text = (datePicker.date as NSDate).formattedDisplay();
    }
    
    @objc func doneButtonPressed() {
        textField?.resignFirstResponder();
    }
    
    @objc func cancelButtonPressed() {
        date = value;
        setTextFieldValue();
        textField?.resignFirstResponder();
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.date = nil;
        return true;
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        date = datePicker.date;
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let newDate = self.date {
            if (self.value != newDate) {
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
