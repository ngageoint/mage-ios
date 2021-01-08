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
    private var eventForm: [String:Any]?;
    private var form: [String: Any]!;
    private var formIndex: Int!;
    private var fieldViews: [String: BaseFieldView] = [ : ];
    private var attachmentSelectionDelegate: AttachmentSelectionDelegate?;
    private var viewController: UIViewController!;
    private var fieldSelectionDelegate: FieldSelectionDelegate?;
    private var observationFormListener: ObservationFormListener?;
    private var editMode: Bool = true;
    private var formFieldAdded: Bool = false;
    private var scheme: MDCContainerScheming?;

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
    
    convenience init(observation: Observation, form: [String: Any], eventForm: [String:Any]? = nil, formIndex: Int, editMode: Bool = true, viewController: UIViewController, observationFormListener: ObservationFormListener? = nil, delegate: FieldSelectionDelegate? = nil, attachmentSelectionDelegate: AttachmentSelectionDelegate? = nil) {
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
        constructView();
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming) {
        self.scheme = scheme;
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
            if (type == "radio" || type == "multiselectdropdown") {
                type = "dropdown";
            }
            var fieldView: UIView;
            switch type {
            case "attachment":
                let coordinator: AttachmentCreationCoordinator = AttachmentCreationCoordinator(rootViewController: viewController, observation: observation);
                fieldView = AttachmentFieldView(field: fieldDictionary, editMode: editMode, delegate: self, attachmentSelectionDelegate: attachmentSelectionDelegate, attachmentCreationCoordinator: coordinator);
            case "numberfield":
                fieldView = NumberFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: (value as? NSNumber)?.stringValue );
            case "textfield":
                fieldView = TextFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: value as? String);
            case "textarea":
                fieldView = TextFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: value as? String, multiline: true);
            case "email":
                fieldView = TextFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: value as? String, keyboardType: .emailAddress);
            case "password":
                fieldView = TextFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: value as? String);
            case "date":
                fieldView = DateView(field: fieldDictionary, editMode: editMode, delegate: self, value: value as? String);
            case "checkbox":
                fieldView = CheckboxFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: value as? Bool ?? false);
            case "dropdown":
                if let stringValue = value as? String {
                    fieldView = DropdownFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: stringValue)
                }
                else {
                    fieldView = DropdownFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: value as? [String])
                }
            case "geometry":
                fieldView = GeometryView(field: fieldDictionary, editMode: editMode, delegate: self);
                (fieldView as! GeometryView).setValue(value as? SFGeometry, accuracy: 100.487235, provider: "gps")
            default:
                let label = UILabel(forAutoLayout: ());
                label.text = type;
                fieldView = label;
            }
            if let baseFieldView = fieldView as? BaseFieldView, let safeKey = fieldDictionary[FieldKey.name.key] as? String {
                baseFieldView.applyTheme(withScheme: scheme ?? globalContainerScheme())
                fieldViews[safeKey] = baseFieldView;
            }
            formFieldAdded = true;
            self.addArrangedSubview(fieldView);
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
            form.removeValue(forKey: field["name"] as? String ?? "");
        } else {
            form[field["name"] as? String ?? ""] = value;
        }
        var forms: [[String: Any]] = newProperties?["forms"] as! [[String: Any]];
        forms[0] = form;
        newProperties!["forms"] = forms;
        self.observation.properties = newProperties;
        self.observationFormListener?.formUpdated(form, eventForm: eventForm!, form: formIndex);
    }
}
