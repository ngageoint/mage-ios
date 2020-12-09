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

class ObservationEditCoordinator {
    
    var newObservation = false;
    var observation: Observation?;
    var rootViewController: UIViewController?;
    var navigationController: UINavigationController?;
    var delegate: ObservationEditDelegate?;
    var observationEditController: ObservationEditCardCollectionViewController?;
    var bottomSheet: MDCBottomSheetController?;
    var currentEditField: [String: Any]?;
    var currentEditValue: Any?;
    
    private lazy var managedObjectContext: NSManagedObjectContext = {
        var managedObjectContext: NSManagedObjectContext = .mr_newMainQueue();
        managedObjectContext.parent = .mr_rootSaving();
        managedObjectContext.stalenessInterval = 0.0;
        managedObjectContext.mr_setWorkingName(newObservation ? "Observation New Context" : "Observation Edit Context");
        return managedObjectContext;
    } ()
    
    private lazy var event: Event = {
        return Event.getCurrentEvent(in: self.managedObjectContext);
    } ()
    
    private lazy var user: User = {
        return User.fetchCurrentUser(in: self.managedObjectContext);
    }()
    
    private init() {
        
    }
    
    @objc public init(rootViewController: UIViewController!, delegate: ObservationEditDelegate, location: SFGeometry, accuracy: CLLocationAccuracy, provider: String, delta: Double) {
        observation = createObservation(location: location, accuracy: accuracy, provider: provider, delta: delta);
        setupCoordinator(rootViewController: rootViewController, delegate: delegate);
    }
    
    @objc public init(rootViewController: UIViewController!, delegate: ObservationEditDelegate, observation: Observation) {
        self.observation = setupObservation(observation: observation);
        setupCoordinator(rootViewController: rootViewController, delegate: delegate);
    }
    
    public func start() {
        if (!self.event.isUser(inEvent: user)) {
            let alert = UIAlertController(title: "You are not part of this event", message: "You cannot create observations for an event you are not part of.", preferredStyle: .alert);
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil));
            self.rootViewController?.present(alert, animated: true, completion: nil);
        } else {
            if let safeNav = navigationController {
                safeNav.modalPresentationStyle = .custom;
                safeNav.modalTransitionStyle = .crossDissolve;
                self.rootViewController?.present(safeNav, animated: true, completion: nil);
                observationEditController = ObservationEditCardCollectionViewController(delegate: self, observation: observation!, newObservation: newObservation);
                safeNav.pushViewController(observationEditController!, animated: true);
            }
        }
    }
    
    func setupCoordinator(rootViewController: UIViewController, delegate: ObservationEditDelegate) {
        self.rootViewController = rootViewController;
        self.delegate = delegate;
        self.navigationController = UINavigationController();
    }
    
    func createObservation(location: SFGeometry, accuracy: CLLocationAccuracy, provider: String, delta: Double) -> Observation {
        newObservation = true;
        let observation = Observation(geometry: location, andAccuracy: accuracy, andProvider: provider, andDelta: delta, in: managedObjectContext);
        observation.dirty = 1;
        return observation;
    }
    
    func setupObservation(observation: Observation) -> Observation? {
        let observationInContext = observation.mr_(in: self.managedObjectContext);
        observationInContext?.dirty = 1;
        return observationInContext;
    }
}

extension ObservationEditCoordinator: FormPickedDelegate {
    func formPicked(form: [String : Any]) {
        observationEditController?.formAdded(form: form);
        bottomSheet?.dismiss(animated: true, completion: nil);
    }
    
    func cancelSelection() {
        bottomSheet?.dismiss(animated: true, completion: nil);
    }
    
    
}

extension ObservationEditCoordinator: FieldSelectionDelegate {
    func launchFieldSelectionViewController(viewController: UIViewController) {
        self.navigationController?.pushViewController(viewController, animated: true);
    }
}

extension ObservationEditCoordinator: ObservationEditCardDelegate {
    
    
//    figure out what of this protocol we really want
    
    func addForm() {
        let forms: [[String: AnyHashable]] = event.forms as! [[String : AnyHashable]];
        let formPicker: FormPickerViewController = FormPickerViewController(delegate: self, forms: forms);
        
        bottomSheet = MDCBottomSheetController(contentViewController: formPicker);
        self.navigationController?.present(bottomSheet!, animated: true, completion: nil);
    }
    
    func saveObservation(observation: Observation) {
        self.observation!.user = user;
        self.managedObjectContext.mr_saveToPersistentStore { [self] (contextDidSave, error) in
            if (!contextDidSave) {
                print("Error saving observation to persistent store, context did not save");
            }
            
            if (error != nil) {
                print("Error saving observation to persistent store \(error)");
            }
            
            print("Saved the observation \(observation.remoteId)");
            delegate?.editComplete(observation, coordinator: self as? NSObject);
            rootViewController?.dismiss(animated: true, completion: nil);
        }
    }
    
    func cancelEdit() {
        print("Cancel the edit")
        let alert = UIAlertController(title: "Discard Changes", message: "Do you want to discard your changes?", preferredStyle: .alert);
        alert.addAction(UIAlertAction(title: "Yes, Discard", style: .destructive, handler: { [self] (action) in
            self.navigationController?.dismiss(animated: true, completion: nil);
            self.managedObjectContext.reset();
            delegate?.editCancel(self as? NSObject);
        }));
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil));
        self.navigationController?.present(alert, animated: true, completion: nil);
    }
}
