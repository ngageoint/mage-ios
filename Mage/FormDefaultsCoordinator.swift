//
//  FormDefaultsCoordinator.m
//  MAGE
//
//  Created by William Newman on 1/30/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

@objc protocol FormDefaultsDelegate {
    @objc func formDefaultsComplete(coordinator: NSObject);
}

@objc class FormDefaultsCoordinator: NSObject {
    
    var childCoordinators: [Any] = [];
    var navController: UINavigationController;
    var viewController: UIViewController?;
    var delegate: FormDefaultsDelegate;
    var event: Event!;
    var form: [String: AnyHashable];
    var defaults: NSMutableDictionary?;
    var scheme: MDCContainerScheming;
    
    private lazy var serverDefaults: [String: AnyHashable] = {
        // Make a mutable copy of the original form
        var defaults = FormDefaults.mutableForm(form) as! [String : AnyHashable];
        
        // filter out archived and hidden fields and sort
        var fields: [[String: AnyHashable]] = defaults[FormKey.fields.key] as! [[String: AnyHashable]];
        var filteredFields: [[String: AnyHashable]] = fields.filter { (($0[FieldKey.archived.key] as? Bool) == nil || ($0[FieldKey.archived.key] as? Bool) == false) }
        filteredFields.sort { (firstField : [String: AnyHashable], secondField: [String: AnyHashable]) -> Bool in
            return (firstField[FieldKey.id.key] as! Int) < (secondField[FieldKey.id.key] as! Int);
        }
        var newForm: [String: AnyHashable] = [ : ]
        for (_, field) in filteredFields.enumerated() {
            // grab the server default from the form fields value property
            if let value: AnyHashable = field[FieldKey.value.key] {
                newForm[field[FieldKey.name.key] as! String] = value;
            }
        }
        return newForm;
    }();
    
    @objc public init(navController: UINavigationController, event: Event, form: [String: AnyHashable], scheme: MDCContainerScheming, delegate: FormDefaultsDelegate) {
        self.navController = navController;
        self.event = event;
        self.form = form;
        self.delegate = delegate;
        self.scheme = scheme;
    }
    
    @objc func start() {
        viewController = FormDefaultsViewController(event: event, eventForm: form, navigationController: navController, scheme: self.scheme, formDefaultsCoordinator: self);
        self.navController.pushViewController(viewController!, animated: true);
    }
    
    func save(defaults: [String: AnyHashable]) {
        let formDefaults = FormDefaults(eventId: self.event.remoteId as! Int, formId: form[FormKey.id.key] as! Int);
        // Compare server defaults with defaults.  If they are the same clear the defaults
        if (defaults == serverDefaults) {
            formDefaults.clear();
        } else {
            formDefaults.setDefaults(defaults);
        }
        self.navController.popViewController(animated: true);
        self.delegate.formDefaultsComplete(coordinator: self);
    }
    
    func cancel() {
        self.navController.popViewController(animated: true);
        self.delegate.formDefaultsComplete(coordinator: self);
    }
}

extension FormDefaultsCoordinator: FieldSelectionDelegate {
    func launchFieldSelectionViewController(viewController: UIViewController) {
        self.navController.pushViewController(viewController, animated: true);
    }
}
