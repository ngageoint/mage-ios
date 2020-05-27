//
//  ObservationFormView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/5/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

import MaterialComponents.MaterialTextFields
import MaterialComponents.MaterialTextControls_OutlinedTextAreasTheming

class ObservationFormView: UIStackView {
    
    private var observation: Observation?;
    private var eventForm: NSDictionary?;
    private var form: NSDictionary?;
    private var formIndex: Int!;
    private let containerScheme = MDCContainerScheme()
    
    private let nameController = MDCTextInputControllerUnderline();

    private lazy var formFields: NSArray = {
        let predicate = NSPredicate(format: "archived = %@ AND hidden = %@ AND type IN %@", argumentArray: [nil, nil, ObservationFields.fields()]);
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true);
        return ((self.eventForm?.object(forKey: "fields") as! NSArray).filtered(using: predicate) as! NSArray).sortedArray(using: [sortDescriptor]) as! NSArray;
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.alignment = UIStackView.Alignment.fill;
        self.distribution = UIStackView.Distribution.equalSpacing;
        self.axis = NSLayoutConstraint.Axis.vertical;
        self.isLayoutMarginsRelativeArrangement = true
        self.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
    }
    
    convenience init(observation: Observation, form: NSDictionary, eventForm: NSDictionary, formIndex: Int) {
        self.init(frame: CGRect.zero)
        self.observation = observation;
        self.form = form;
        self.eventForm = eventForm;

        constructView();
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func constructView() {
        print("Add all the behavior here %@", self.formFields)
        
        for field in self.formFields {
            let fieldDictionary = (field as! NSDictionary);
            let value = self.form?.object(forKey: fieldDictionary.object(forKey: "name") as! String)
            
            var type = fieldDictionary.object(forKey: "type") as! String;
            if (type == "radio" || type == "multiselectdropdown") {
                type = "dropdown";
            }
            var fieldView: UIView;
            switch type {
            case "numberfield":
                fieldView = EditNumberFieldView(field: fieldDictionary, delegate: self, value: value as? String);
            case "textfield":
                fieldView = EditTextFieldView(field: fieldDictionary, value: value as? String);
            case "textarea":
                fieldView = EditTextFieldView(field: fieldDictionary, value: value as? String, multiline: true);
            case "date":
                fieldView = EditDateView(field: fieldDictionary, delegate: self, value: value as? String);
            case "geometry":
                fieldView = EditGeometryView(field: fieldDictionary, delegate: self);
                (fieldView as! EditGeometryView).setValue(value as? SFGeometry, accuracy: 100.487235, provider: "gps")
            default:
                let label = UILabel(forAutoLayout: ());
                label.text = type;
                fieldView = label;
            }
            
            self.addArrangedSubview(fieldView);
            
            /*
             [self.tableView registerNib:[UINib nibWithNibName:@"ObservationEditCell" bundle:nil] forCellReuseIdentifier:@"ObservationEditCell"];
             [self.tableView registerNib:[UINib nibWithNibName:@"ObservationDateEditCell" bundle:nil] forCellReuseIdentifier:@"date"];
             [self.tableView registerNib:[UINib nibWithNibName:@"ObservationGeometryEditCell" bundle:nil] forCellReuseIdentifier:@"geometry"];
             [self.tableView registerNib:[UINib nibWithNibName:@"ObservationCheckboxEditCell" bundle:nil] forCellReuseIdentifier:@"checkbox"];
             [self.tableView registerNib:[UINib nibWithNibName:@"ObservationEmailEditCell" bundle:nil] forCellReuseIdentifier:@"email"];
             [self.tableView registerNib:[UINib nibWithNibName:@"ObservationNumberEditCell" bundle:nil] forCellReuseIdentifier:@"numberfield"];
             [self.tableView registerNib:[UINib nibWithNibName:@"ObservationTextAreaEditCell" bundle:nil] forCellReuseIdentifier:@"textarea"];
             [self.tableView registerNib:[UINib nibWithNibName:@"ObservationAttachmentEditCell" bundle:nil] forCellReuseIdentifier:@"attachment"];
             [self.tableView registerNib:[UINib nibWithNibName:@"ObservationDropdownEditCell" bundle:nil] forCellReuseIdentifier:@"dropdown"];
             [self.tableView registerNib:[UINib nibWithNibName:@"ObservationPasswordEditCell" bundle:nil] forCellReuseIdentifier:@"password"];
             [self.tableView registerNib:[UINib nibWithNibName:@"ObservationTextfieldEditCell" bundle:nil] forCellReuseIdentifier:@"textfield"];
             [self.tableView registerNib:[UINib nibWithNibName:@"ObservationDeleteCell" bundle:nil] forCellReuseIdentifier:@"deleteObservationCell"];
             [self.tableView registerNib:[UINib nibWithNibName:@"TableSectionHeader" bundle:nil] forHeaderFooterViewReuseIdentifier:@"TableSectionHeader"];
             */
        }
    }
    
}

extension ObservationFormView: ObservationEditListener {
    func fieldSelected(_ field: Any!) {
        print("Field was selected", field);
    }
    
    func observationField(_ field: Any!, valueChangedTo value: Any!, reloadCell reload: Bool) {
        let fieldDictionary = field as! NSDictionary;
        let fieldKey = fieldDictionary.object(forKey: "name") as! String;
//        let number = fieldDictionary.object(forKey: "formIndex") as! NSNumber;
//        let formIndex = number.intValue;
        let newProperties = (self.observation?.properties as! NSDictionary).mutableCopy() as! NSMutableDictionary;
        let forms = (newProperties.object(forKey: "forms") as! NSDictionary).mutableCopy() as! NSMutableArray;
        let newFormProperties = ((forms[formIndex] as! NSDictionary).mutableCopy() as! NSMutableDictionary);
        if (value == nil) {
            newFormProperties.removeObject(forKey: fieldKey);
        } else {
            newFormProperties.setObject(value, forKey: fieldKey as NSCopying);
        }
        forms.replaceObject(at: formIndex, with: newFormProperties);
        newProperties.setObject([forms.copy()], forKey: "forms" as NSCopying);
        
        self.observation?.properties = newProperties.copy();
//        NSString *fieldKey = (NSString *)[field objectForKey:@"name"];
//        NSNumber *number = [field objectForKey:@"formIndex"];
//        NSUInteger formIndex = [number integerValue];
//        NSMutableDictionary *newProperties = [self.observation.properties mutableCopy];
//        NSMutableArray *forms = [[newProperties objectForKey:@"forms"] mutableCopy];
//        NSMutableDictionary *newFormProperties = [[forms objectAtIndex:formIndex] mutableCopy];
//        if (value == nil) {
//            [newFormProperties removeObjectForKey:fieldKey];
//        } else {
//            [newFormProperties setObject:value forKey:fieldKey];
//        }
//        [forms replaceObjectAtIndex:formIndex withObject:newFormProperties];
//        [newProperties setObject:[forms copy] forKey:@"forms"];
//
//        indexPath = [NSIndexPath indexPathForRow:[[field objectForKey:@"fieldRow"] integerValue] inSection:(formIndex+2)];
//
//        self.observation.properties = [newProperties copy];
//
//        if ([fieldKey isEqualToString:self.primaryField] && self.annotationChangedDelegate) {
//            [self.annotationChangedDelegate typeChanged:self.observation];
//        }
//        if (self.variantField && [fieldKey isEqualToString:self.variantField] && self.annotationChangedDelegate) {
//            [self.annotationChangedDelegate variantChanged:self.observation];
//        }
    }
}

extension ObservationFormView: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        guard let rawText = textField.text else {
            return true
        }
        
        let fullString = NSString(string: rawText).replacingCharacters(in: range, with: string)
        
//        if textField == state {
//            if let range = fullString.rangeOfCharacter(from: CharacterSet.letters.inverted),
//                String(fullString[range]).characterCount > 0 {
//                stateController.setErrorText("Error: State can only contain letters",
//                                             errorAccessibilityValue: nil)
//            } else {
//                stateController.setErrorText(nil, errorAccessibilityValue: nil)
//            }
//        } else if textField == zip {
//            if let range = fullString.rangeOfCharacter(from: CharacterSet.letters),
//                String(fullString[range]).characterCount > 0 {
//                zipController.setErrorText("Error: Zip can only contain numbers",
//                                           errorAccessibilityValue: nil)
//            } else if fullString.characterCount > 5 {
//                zipController.setErrorText("Error: Zip can only contain five digits",
//                                           errorAccessibilityValue: nil)
//            } else {
//                zipController.setErrorText(nil, errorAccessibilityValue: nil)
//            }
//        } else if textField == city {
//            if let range = fullString.rangeOfCharacter(from: CharacterSet.decimalDigits),
//                String(fullString[range]).characterCount > 0 {
//                cityController.setErrorText("Error: City can only contain letters",
//                                            errorAccessibilityValue: nil)
//            } else {
//                cityController.setErrorText(nil, errorAccessibilityValue: nil)
//            }
//        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let index = textField.tag
//        if index + 1 < allTextFieldControllers.count,
//            let nextField = allTextFieldControllers[index + 1].textInput {
//            nextField.becomeFirstResponder()
//        } else {
//            textField.resignFirstResponder()
//        }
        
        return false
    }
}

extension ObservationFormView: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        print(textView.text)
    }
}

extension ObservationFormView: MDCMultilineTextInputDelegate {
    private func multilineTextFieldShouldClear(_ textField: UIView!) -> Bool {
        return true
    }
}

// MARK: - Keyboard Handling
//extension ObservationFormView {
//    func registerKeyboardNotifications() {
//        let notificationCenter = NotificationCenter.default
//        notificationCenter.addObserver(
//            self,
//            selector: #selector(keyboardWillShow(notif:)),
//            name: UIResponder.keyboardWillShowNotification,
//            object: nil)
//        notificationCenter.addObserver(
//            self,
//            selector: #selector(keyboardWillHide(notif:)),
//            name: UIResponder.keyboardWillHideNotification,
//            object: nil)
//        notificationCenter.addObserver(
//            self,
//            selector: #selector(keyboardWillShow(notif:)),
//            name: UIResponder.keyboardWillChangeFrameNotification,
//            object: nil)
//    }
//
//    @objc func keyboardWillShow(notif: Notification) {
//        guard let frame = notif.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
//            return
//        }
//        self.contentInset = UIEdgeInsets(top: 0.0,
//                                               left: 0.0,
//                                               bottom: frame.height,
//                                               right: 0.0)
//    }
//
//    @objc func keyboardWillHide(notif: Notification) {
//        self.contentInset = UIEdgeInsets()
//    }
//}
