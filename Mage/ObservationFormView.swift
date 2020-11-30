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
    
    var observation: Observation!;
    private var eventForm: [String:Any]?;
    private var form: [String: Any]!;
    private var formIndex: Int!;
    private var fieldViews: [String: BaseFieldView] = [ : ];
    private var delegate: ObservationEditListener?;
    private var attachmentSelectionDelegate: AttachmentSelectionDelegate?;
    private var viewController: UIViewController!;

    private lazy var formFields: [[String: Any]] = {
        let fields: [[String: Any]] = self.eventForm?["fields"] as? [[String: Any]] ?? [];
        
        return fields.filter { (field) -> Bool in
            let archived: Bool = field[FieldKey.archived.key] as? Bool ?? false;
            let hidden : Bool = field[FieldKey.hidden.key] as? Bool ?? false;
            let type : String = field[FieldKey.type.key] as? String ?? "";
            return !archived && !hidden && (ObservationFields.fields() as? [String] ?? []).contains(type);
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
    
    convenience init(observation: Observation, form: [String: Any], eventForm: [String:Any]? = nil, formIndex: Int, viewController: UIViewController, delegate: ObservationEditListener? = nil, attachmentSelectionDelegate: AttachmentSelectionDelegate? = nil) {
        self.init(frame: .zero)
        self.observation = observation;
        self.form = form;
        self.eventForm = eventForm;
        self.delegate = delegate;
        self.viewController = viewController;
        self.attachmentSelectionDelegate = attachmentSelectionDelegate;
        self.formIndex = formIndex;
        constructView();
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func constructView() {
        for fieldDictionary in self.formFields {
            let value = self.form?[fieldDictionary[FieldKey.name.key] as! String]
            
            var type = fieldDictionary[FieldKey.type.key] as! String;
            if (type == "radio" || type == "multiselectdropdown") {
                type = "dropdown";
            }
            var fieldView: UIView;
            switch type {
            case "attachment":
                let coordinator: AttachmentCreationCoordinator = AttachmentCreationCoordinator(rootViewController: viewController, observation: observation);
                fieldView = EditAttachmentFieldView(field: fieldDictionary, delegate: self, attachmentSelectionDelegate: attachmentSelectionDelegate, attachmentCreationCoordinator: coordinator);
            case "numberfield":
                fieldView = EditNumberFieldView(field: fieldDictionary, delegate: self, value: value as? String);
            case "textfield":
                fieldView = EditTextFieldView(field: fieldDictionary, delegate: self, value: value as? String);
            case "textarea":
                fieldView = EditTextFieldView(field: fieldDictionary, delegate: self, value: value as? String, multiline: true);
            case "email":
                fieldView = EditTextFieldView(field: fieldDictionary, delegate: self, value: value as? String, keyboardType: .emailAddress);
            case "password":
                fieldView = EditTextFieldView(field: fieldDictionary, delegate: self, value: value as? String);
            case "date":
                fieldView = EditDateView(field: fieldDictionary, delegate: self, value: value as? String);
            case "checkbox":
                fieldView = EditCheckboxFieldView(field: fieldDictionary, delegate: self, value: value as? Bool ?? false);
            case "dropdown":
                if let stringValue = value as? String {
                    fieldView = EditDropdownFieldView(field: fieldDictionary, delegate: self, value: stringValue)
                }
                else {
                    fieldView = EditDropdownFieldView(field: fieldDictionary, delegate: self, value: value as? [String])
                }
            case "geometry":
                fieldView = EditGeometryView(field: fieldDictionary, delegate: self);
                (fieldView as! EditGeometryView).setValue(value as? SFGeometry, accuracy: 100.487235, provider: "gps")
            default:
                let label = UILabel(forAutoLayout: ());
                label.text = type;
                fieldView = label;
            }
            if let baseFieldView = fieldView as? BaseFieldView, let safeKey = fieldDictionary[FieldKey.name.key] as? String {
                fieldViews[safeKey] = baseFieldView;
            }
            self.addArrangedSubview(fieldView);
        }
    }
    
    func fieldViewForField(field: [String: Any]) -> BaseFieldView? {
        if let safeKey = field[FieldKey.name.key] as? String {
            return fieldViews[safeKey]
        }
        return nil;
    }
}

extension ObservationFormView: ObservationEditListener {
    func fieldSelected(_ field: Any!) {
        delegate?.fieldSelected?(field);
    }
    
    func observationField(_ field: Any!, valueChangedTo value: Any!, reloadCell reload: Bool) {
        let fieldDictionary = field as! [String: Any];
        
        var newProperties = self.observation.properties as? [String: [[String: Any]]];
        if (value == nil) {
            form.removeValue(forKey: fieldDictionary["name"] as? String ?? "");
        } else {
            form[fieldDictionary["name"] as? String ?? ""] = value;
        }
        
        newProperties?["forms"]?[0] = form;
        self.observation.properties = newProperties;
        
        self.delegate?.formUpdated?(form, eventForm: eventForm, form: formIndex);
        
        delegate?.observationField(field, valueChangedTo: value, reloadCell: reload);
    }
}
