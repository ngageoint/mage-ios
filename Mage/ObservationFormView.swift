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

@objc protocol ObservationFormFieldListener {
    @objc func fieldValueChanged(_ field: [String : Any], value: Any?);
}

class ObservationFormView: UIStackView {
    
    var observation: Observation!;
    public var containingCard: ExpandableCard?;
    private var eventForm: [String:Any]?;
    private var form: [String: Any]!;
    private var formIndex: Int!;
    private var fieldViews: [String: BaseFieldView] = [ : ];
    private var attachmentSelectionDelegate: AttachmentSelectionDelegate?;
    private var viewController: UIViewController!;
    private var fieldSelectionDelegate: FieldSelectionDelegate?;
    private var observationFormListener: ObservationFormListener?;
    private var observationActionsDelegate: ObservationActionsDelegate?;
    private var editMode: Bool = true;
    private var formFieldAdded: Bool = false;
    private var scheme: MDCContainerScheming?;

    private lazy var formFields: [[String: Any]] = {
        let fields: [[String: Any]] = self.eventForm?[FormKey.fields.key] as? [[String: Any]] ?? [];
        
        return fields.filter { (field) -> Bool in
            let archived: Bool = field[FieldKey.archived.key] as? Bool ?? false;
            let hidden : Bool = field[FieldKey.hidden.key] as? Bool ?? false;
            let type : String = field[FieldKey.type.key] as? String ?? "";
            return !archived;
        }.sorted { (field0, field1) -> Bool in
            return (field0[FieldKey.id.key] as? Int ?? Int.max ) < (field1[FieldKey.id.key] as? Int ?? Int.max)
        }
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.alignment = .fill;
        self.distribution = .equalSpacing;
        self.axis = .vertical;
        self.spacing = 12;
    }
    
    convenience init(observation: Observation, form: [String: Any], eventForm: [String:Any]? = nil, formIndex: Int, editMode: Bool = true, viewController: UIViewController, observationFormListener: ObservationFormListener? = nil, delegate: FieldSelectionDelegate? = nil, attachmentSelectionDelegate: AttachmentSelectionDelegate? = nil, observationActionsDelegate: ObservationActionsDelegate? = nil) {
        self.init(frame: .zero)
        self.observation = observation;
        self.form = form;
        self.eventForm = eventForm;
        self.editMode = editMode;
        self.viewController = viewController;
        self.attachmentSelectionDelegate = attachmentSelectionDelegate;
        self.formIndex = formIndex;
        self.fieldSelectionDelegate = delegate;
        self.observationFormListener = observationFormListener;
        self.observationActionsDelegate = observationActionsDelegate;
        constructView();
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming) {
        self.scheme = scheme;
        for (_, fieldView) in self.fieldViews {
            fieldView.applyTheme(withScheme: scheme);
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func constructView() {
        formFieldAdded = false;
        for fieldDictionary in self.formFields {
            let value = self.form?[fieldDictionary[FieldKey.name.key] as! String]
            
            if (!editMode && value == nil) {
                continue;
            }
            
            var type = fieldDictionary[FieldKey.type.key] as! String;
            if (type == FieldType.radio.key || type == FieldType.multiselectdropdown.key) {
                type = FieldType.dropdown.key;
            }
            var fieldView: UIView?;
            switch type {
            case FieldType.attachment.key:
                let coordinator: AttachmentCreationCoordinator = AttachmentCreationCoordinator(rootViewController: viewController, observation: observation);
                fieldView = AttachmentFieldView(field: fieldDictionary, editMode: editMode, delegate: self, attachmentSelectionDelegate: attachmentSelectionDelegate, attachmentCreationCoordinator: coordinator);
            case FieldType.numberfield.key:
                fieldView = NumberFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: (value as? NSNumber)?.stringValue );
            case FieldType.textfield.key:
                fieldView = TextFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: value as? String);
            case FieldType.textarea.key:
                fieldView = TextFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: value as? String, multiline: true);
            case FieldType.email.key:
                fieldView = TextFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: value as? String, keyboardType: .emailAddress);
            case FieldType.password.key:
                fieldView = TextFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: value as? String);
            case FieldType.date.key:
                fieldView = DateView(field: fieldDictionary, editMode: editMode, delegate: self, value: value as? String);
            case FieldType.checkbox.key:
                fieldView = CheckboxFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: value as? Bool ?? false);
            case FieldType.dropdown.key:
                if let stringValue = value as? String {
                    fieldView = DropdownFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: stringValue)
                }
                else {
                    fieldView = DropdownFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: value as? [String])
                }
            case FieldType.geometry.key:
                fieldView = GeometryView(field: fieldDictionary, editMode: editMode, delegate: self, observationActionsDelegate: observationActionsDelegate);
                (fieldView as! GeometryView).setValue(value as? SFGeometry)
            default:
                print("No view is configured for type \(type)")
            }
            if let baseFieldView = fieldView as? BaseFieldView, let safeKey = fieldDictionary[FieldKey.name.key] as? String {
                if let safeScheme = scheme {
                    baseFieldView.applyTheme(withScheme: safeScheme)
                }
                fieldViews[safeKey] = baseFieldView;
                formFieldAdded = true;
                self.addArrangedSubview(baseFieldView);
            }
        }
    }
    
    func fieldViewForField(field: [String: Any]) -> BaseFieldView? {
        if let safeKey = field[FieldKey.name.key] as? String {
            return fieldViews[safeKey]
        }
        return nil;
    }
    
    public func isEmpty() -> Bool {
        return !formFieldAdded;
    }
    
    public func checkValidity(enforceRequired: Bool = false) -> Bool {
        var valid = true;
        for (_, fieldView) in self.fieldViews {
            let formValid = fieldView.isValid(enforceRequired: enforceRequired);
            fieldView.setValid(formValid);
            valid = valid && formValid;
        }
        containingCard?.markValid(valid);
        return valid;
    }
}

extension ObservationFormView: FieldSelectionDelegate {
    func launchFieldSelectionViewController(viewController: UIViewController) {
        fieldSelectionDelegate?.launchFieldSelectionViewController(viewController: viewController);
    }
}

extension ObservationFormView: ObservationFormFieldListener {
    func fieldValueChanged(_ field: [String : Any], value: Any?) {
        var newProperties = self.observation.properties as? [String: Any];
        if (value == nil) {
            form.removeValue(forKey: field[FieldKey.name.key] as? String ?? "");
        } else {
            form[field[FieldKey.name.key] as? String ?? ""] = value;
        }
        var forms: [[String: Any]] = newProperties?[ObservationKey.forms.key] as! [[String: Any]];
        forms[0] = form;
        newProperties![ObservationKey.forms.key] = forms;
        self.observation.properties = newProperties;
        self.observationFormListener?.formUpdated(form, eventForm: eventForm!, form: formIndex);
    }
}
