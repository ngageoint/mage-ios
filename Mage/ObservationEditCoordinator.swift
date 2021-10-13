//
//  ObservationEditCoordinator.swift
//  MAGE
//
//  Created by Daniel Barela on 12/1/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MaterialBottomSheet

@objc protocol ObservationEditListener {
    @objc func fieldValueChanged(_ field: [String: Any], value: Any?);
//    @objc optional func fieldSelected(_ field: [String: Any], currentValue: Any?);
    @objc optional func formUpdated(_ form: [String: Any], eventForm: [String: Any], form index: Int);
}

@objc protocol ObservationEditDelegate {
    @objc func editCancel(_ coordinator: NSObject);
    @objc func editComplete(_ observation: Observation, coordinator: NSObject);
}

protocol ObservationCommonPropertiesListener: AnyObject {
    func geometryUpdated(_ geometry: SFGeometry?, accuracy: String?, delta: Double?, provider: String?);
    func timestampUpdated(_ date: Date?);
}

@objc class ObservationEditCoordinator: NSObject {
    
    var newObservation = false;
    var observation: Observation?;
    weak var rootViewController: UIViewController?;
    var navigationController: UINavigationController?;
    weak var delegate: ObservationEditDelegate?;
    var observationEditController: ObservationEditCardCollectionViewController?;
    var observationFormReorder: ObservationFormReorder?;
    var bottomSheet: MDCBottomSheetController?;
    var currentEditField: [String: Any]?;
    var currentEditValue: Any?;
    var scheme: MDCContainerScheming?;
    
    private lazy var managedObjectContext: NSManagedObjectContext = {
        var managedObjectContext: NSManagedObjectContext = .mr_newMainQueue();
        managedObjectContext.parent = .mr_rootSaving();
        managedObjectContext.stalenessInterval = 0.0;
        managedObjectContext.mr_setWorkingName(newObservation ? "Observation New Context" : "Observation Edit Context");
        return managedObjectContext;
    } ()
    
    private lazy var event: Event? = {
        return Event.getCurrentEvent(context: self.managedObjectContext);
    } ()
    
    private lazy var eventForms: [[String: AnyHashable]] = {
        let eventForms = event?.forms as? [[String: AnyHashable]] ?? [];
        return eventForms;
    }()
    
    private lazy var user: User = {
        return User.fetchCurrentUser(in: self.managedObjectContext);
    }()
    
    @objc public func applyTheme(withContainerScheme containerScheme: MDCContainerScheming?) {
        self.scheme = containerScheme;
    }
    
    @objc public init(rootViewController: UIViewController!, delegate: ObservationEditDelegate, location: SFGeometry?, accuracy: CLLocationAccuracy, provider: String, delta: Double) {
        super.init();
        observation = createObservation(location: location, accuracy: accuracy, provider: provider, delta: delta);
        setupCoordinator(rootViewController: rootViewController, delegate: delegate);
    }
    
    @objc public init(rootViewController: UIViewController!, delegate: ObservationEditDelegate, observation: Observation) {
        super.init();
        self.observation = setupObservation(observation: observation);
        setupCoordinator(rootViewController: rootViewController, delegate: delegate);
    }
    
    @objc public func start() {
        guard let event = event else {
            return
        }

        if (!event.isUserInEvent(user: user)) {
            let alert = UIAlertController(title: "You are not part of this event", message: "You cannot create or edit observations for an event you are not part of.", preferredStyle: .alert);
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil));
            self.rootViewController?.present(alert, animated: true, completion: nil);
        } else {
            if let navigationController = navigationController {
                navigationController.modalPresentationStyle = .custom;
                navigationController.modalTransitionStyle = .crossDissolve;
                self.rootViewController?.present(navigationController, animated: true, completion: nil);
                observationEditController = ObservationEditCardCollectionViewController(delegate: self, observation: observation!, newObservation: newObservation, containerScheme: self.scheme);
                navigationController.pushViewController(observationEditController!, animated: true);
                if let scheme = self.scheme {
                    observationEditController?.applyTheme(withContainerScheme: scheme);
                }
            }
        }
    }
    
    @objc public func startFormReorder() {
        guard let event = event else {
            return
        }

        if (!event.isUserInEvent(user: user)) {
            let alert = UIAlertController(title: "You are not part of this event", message: "You cannot edit this observation.", preferredStyle: .alert);
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil));
            self.rootViewController?.present(alert, animated: true, completion: nil);
        } else {
            if let navigationController = navigationController {
                navigationController.modalPresentationStyle = .custom;
                navigationController.modalTransitionStyle = .crossDissolve;
                self.rootViewController?.present(navigationController, animated: true, completion: nil);
                observationFormReorder = ObservationFormReorder(observation: observation!, delegate: self, containerScheme: self.scheme);
                navigationController.pushViewController(self.observationFormReorder!, animated: true);
                self.observationFormReorder!.applyTheme(withContainerScheme: scheme);
            }
        }
    }
    
    func setupCoordinator(rootViewController: UIViewController, delegate: ObservationEditDelegate) {
        self.rootViewController = rootViewController;
        self.delegate = delegate;
        self.navigationController = UINavigationController();
    }
    
    func createObservation(location: SFGeometry?, accuracy: CLLocationAccuracy, provider: String, delta: Double) -> Observation {
        newObservation = true;
        let observation = Observation(geometry: location, andAccuracy: accuracy, andProvider: provider, andDelta: delta, in: managedObjectContext);
        observation.dirty = 1;
        addRequiredForms(observation: observation);
        return observation;
    }
    
    func setupObservation(observation: Observation) -> Observation? {
        let observationInContext = observation.mr_(in: self.managedObjectContext);
        observationInContext?.dirty = 1;
        return observationInContext;
    }
    
    func setupFormWithDefaults(observation: Observation, form: [String: Any]) -> [String: AnyHashable] {
        var newForm: [String: AnyHashable] = [EventKey.formId.key: form[FieldKey.id.key] as! Int];
        let defaults: FormDefaults = FormDefaults(eventId: observation.eventId as! Int, formId: form[FieldKey.id.key] as! Int);
        let formDefaults: [String: AnyHashable] = defaults.getDefaults() as! [String: AnyHashable];
        
        let fields: [[String : AnyHashable]] = (form[FormKey.fields.key] as! [[String : AnyHashable]]).filter { (($0[FieldKey.archived.key] as? Bool) == nil || ($0[FieldKey.archived.key] as? Bool) == false) };
        if (formDefaults.count > 0) { // user defaults
            for (_, field) in fields.enumerated() {
                var value: AnyHashable? = nil;
                if let defaultField: AnyHashable = formDefaults[field[FieldKey.name.key] as! String] {
                    value = defaultField
                }
                
                if (value != nil) {
                    newForm[field[FieldKey.name.key] as! String] = value;
                }
            }
        } else { // server defaults
            for (_, field) in fields.enumerated() {
                // grab the server default from the form fields value property
                if let value: AnyHashable = field[FieldKey.value.key] {
                    newForm[field[FieldKey.name.key] as! String] = value;
                }
            }
        }
        return newForm;
    }
    
    func addFormToObservation(observation: Observation, form: [String: AnyHashable]) {
        var observationProperties: [String: Any] = [ObservationKey.forms.key:[]];
        var observationForms: [[String: Any]] = [];
        if let properties = observation.properties as? [String: Any] {
            if (properties.keys.contains(ObservationKey.forms.key)) {
                observationForms = properties[ObservationKey.forms.key] as! [[String: Any]];
            }
            observationProperties = properties;
        }
        observationForms.append(setupFormWithDefaults(observation: observation, form: form));
        observationProperties[ObservationKey.forms.key] = observationForms;
        observation.properties = observationProperties;
    }
    
    func addRequiredForms(observation: Observation) {
        for eventForm in eventForms {
            let eventFormMin: Int = (eventForm[FieldKey.min.key] as? Int) ?? 0;
            if (eventFormMin > 0) {
                for _ in 1...eventFormMin {
                    addFormToObservation(observation: observation, form: eventForm);
                }
            }
        }
    }
}

extension ObservationEditCoordinator: FormPickedDelegate {
    func formPicked(form: [String : Any]) {
        observationEditController?.formAdded(form: form);
        bottomSheet?.dismiss(animated: true, completion: nil);
        bottomSheet = nil;
    }
    
    func cancelSelection() {
        bottomSheet?.dismiss(animated: true, completion: nil);
        bottomSheet = nil;
    }
}

extension ObservationEditCoordinator: FieldSelectionDelegate {
    func launchFieldSelectionViewController(viewController: UIViewController) {
        self.navigationController?.pushViewController(viewController, animated: true);
    }
}

extension ObservationEditCoordinator: ObservationFormReorderDelegate {
    func formsReordered(observation: Observation) {
        self.observation = observation;
        self.observation!.userId = user.remoteId;

        if let observationEditController = self.observationEditController {
            observationEditController.formsReordered(observation: self.observation!);
            self.navigationController?.popViewController(animated: true);

        } else {
            self.managedObjectContext.mr_saveToPersistentStore { [self] (contextDidSave, error) in
                if (!contextDidSave) {
                    print("Error saving observation to persistent store, context did not save");
                }
                
                if let safeError = error {
                    print("Error saving observation to persistent store \(safeError)");
                }
                
                delegate?.editComplete(self.observation!, coordinator: self as NSObject);

                self.navigationController?.dismiss(animated: true, completion: nil);
            }
        }
    }
    
    func cancelReorder() {
        if (self.observationEditController != nil) {
            self.navigationController?.popViewController(animated: true);
        } else {
            self.managedObjectContext.reset();
            self.navigationController?.dismiss(animated: true, completion: nil);
        }
    }
}

extension ObservationEditCoordinator: ObservationEditCardDelegate {    
    func reorderForms(observation: Observation) {
        self.observationFormReorder = ObservationFormReorder(observation: observation, delegate: self, containerScheme: self.scheme);
        self.navigationController?.pushViewController(self.observationFormReorder!, animated: true);
    }
    
    func addForm() {
        let forms: [[String: AnyHashable]] = (event?.forms as! [[String : AnyHashable]]).filter { form in
            return !(form[FormKey.archived.rawValue] as? Bool ?? false)
        };
        let formPicker: FormPickerViewController = FormPickerViewController(delegate: self, forms: forms, observation: observation, scheme: self.scheme);
        formPicker.applyTheme(withScheme: scheme);
        bottomSheet = MDCBottomSheetController(contentViewController: formPicker);
        bottomSheet?.trackingScrollView = formPicker.tableView
        self.navigationController?.present(bottomSheet!, animated: true, completion: nil);
    }
    
    func saveObservation(observation: Observation) {
        print("Save observation");
        self.observation!.userId = user.remoteId;
        self.managedObjectContext.mr_saveToPersistentStore { [self] (contextDidSave, error) in
            if (!contextDidSave) {
                print("Error saving observation to persistent store, context did not save");
            }
            
            if let safeError = error {
                print("Error saving observation to persistent store \(safeError)");
            }
            
            print("Saved the observation \(observation.remoteId ?? "")");
            delegate?.editComplete(observation, coordinator: self as NSObject);
            rootViewController?.dismiss(animated: true, completion: nil);
            observationEditController = nil;
            navigationController = nil;
        }
    }
    
    func cancelEdit() {
        print("Cancel the edit")
        let alert = UIAlertController(title: "Discard Changes", message: "Do you want to discard your changes?", preferredStyle: .alert);
        alert.addAction(UIAlertAction(title: "Yes, Discard", style: .destructive, handler: { [self] (action) in
            self.navigationController?.dismiss(animated: true, completion: nil);
            self.managedObjectContext.reset();
            delegate?.editCancel(self as NSObject);
            observationEditController = nil;
            navigationController = nil;
        }));
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil));
        self.navigationController?.present(alert, animated: true, completion: nil);
    }
}
