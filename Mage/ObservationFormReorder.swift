//
//  ObservationFormReorder.swift
//  MAGE
//
//  Created by Daniel Barela on 1/19/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCContainerScheme;

@objc protocol ObservationFormReorderDelegate {
    func formsReordered(observation: Observation);
    func cancelReorder();
}

class ObservationFormReorder: UITableViewController {
    
    let cellReuseIdentifier = "formCell";
    let observation: Observation;
    let delegate: ObservationFormReorderDelegate;
    var observationForms: [[String: Any]] = [];
    var observationProperties: [String: Any] = [ : ];
    var scheme: MDCContainerScheming?;
    
    private lazy var eventForms: [[String: Any]] = {
        let eventForms = Event.getById(self.observation.eventId as Any, in: (self.observation.managedObjectContext)!).forms as? [[String: Any]] ?? [];
        return eventForms;
    }()
    
    private lazy var descriptionHeaderView: UILabel = {
        let label = UILabel(forAutoLayout: ());
        label.text = "The first form in this list is the primary form, which determines how MAGE displays the observation on the map and in the feed. The forms will be displayed, as ordered, in all other views. Drag rows to reorder the forms.";
        label.numberOfLines = 0;
        label.lineBreakMode = .byWordWrapping;
        return label;
    }()
    
    private lazy var headerView: UIView = {
        let view = UIView();
        view.addSubview(descriptionHeaderView);
        descriptionHeaderView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
        return view;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init(observation: Observation, delegate: ObservationFormReorderDelegate, containerScheme: MDCContainerScheming?) {
        self.observation = observation
        self.delegate = delegate;
        self.scheme = containerScheme;
        super.init(style: .plain)
        self.title = "Reorder Forms";
        self.view.accessibilityLabel = "Reorder Forms";
        tableView.register(cellClass: ObservationFormTableViewCell.self)
        if let safeProperties = self.observation.properties as? [String: Any] {
            if (safeProperties.keys.contains(ObservationKey.forms.key)) {
                observationForms = safeProperties[ObservationKey.forms.key] as! [[String: Any]];
            }
            self.observationProperties = safeProperties;
        } else {
            self.observationProperties = [ObservationKey.forms.key:[]];
            observationForms = [];
        }
    }
    
    func applyTheme(withContainerScheme containerScheme: MDCContainerScheming!) {
        self.scheme = containerScheme;
        self.tableView.backgroundColor = containerScheme.colorScheme.backgroundColor;
        self.view.backgroundColor = containerScheme.colorScheme.backgroundColor;
        
        self.navigationController?.navigationBar.isTranslucent = false;
        self.navigationController?.navigationBar.barTintColor = containerScheme.colorScheme.primaryColorVariant;
        self.navigationController?.navigationBar.tintColor = containerScheme.colorScheme.onPrimaryColor;
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : containerScheme.colorScheme.onPrimaryColor];
        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: containerScheme.colorScheme.onPrimaryColor];
        let appearance = UINavigationBarAppearance();
        appearance.configureWithOpaqueBackground();
        appearance.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: containerScheme.colorScheme.onPrimaryColor
        ];
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor:  containerScheme.colorScheme.onPrimaryColor
        ];
        
        self.navigationController?.navigationBar.standardAppearance = appearance;
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance;
        self.navigationController?.navigationBar.standardAppearance.backgroundColor = containerScheme.colorScheme.primaryColorVariant;
        self.navigationController?.navigationBar.scrollEdgeAppearance?.backgroundColor = containerScheme.colorScheme.primaryColorVariant;
        
        self.descriptionHeaderView.font = containerScheme.typographyScheme.overline;
        self.descriptionHeaderView.textColor = containerScheme.colorScheme.onBackgroundColor.withAlphaComponent(0.6)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Apply", style: .done, target: self, action: #selector(self.saveFormOrder(sender:)));
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.cancel(sender:)));
        
        self.tableView.isEditing = true;
        self.tableView.rowHeight = UITableView.automaticDimension;
        self.tableView.estimatedRowHeight = 60;
        self.tableView.tableFooterView = UIView();
        self.view.addSubview(headerView);
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        if let safeScheme = self.scheme {
            applyTheme(withContainerScheme: safeScheme);
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let newSize = headerView.systemLayoutSizeFitting(CGSize(width: self.tableView.bounds.width, height: 0), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        headerView.autoSetDimensions(to: newSize);
        tableView.contentInset = UIEdgeInsets(top: headerView.frame.size.height, left: 0, bottom: 0, right: 0);
        headerView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: -1 * newSize.height, left: 0, bottom: 0, right: 0), excludingEdge: .bottom);

    }

    @objc func cancel(sender: UIBarButtonItem) {
        delegate.cancelReorder();
    }
    
    @objc func saveFormOrder(sender: UIBarButtonItem) {
        observationProperties[ObservationKey.forms.key] = observationForms;
        self.observation.properties = observationProperties;
        delegate.formsReordered(observation: self.observation);
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedObject = self.observationForms[sourceIndexPath.row]
        observationForms.remove(at: sourceIndexPath.row)
        observationForms.insert(movedObject, at: destinationIndexPath.row)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return observationForms.count;
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let formCell : ObservationFormTableViewCell = tableView.dequeue(cellClass: ObservationFormTableViewCell.self, forIndexPath: indexPath);
        let observationForm = observationForms[indexPath.row];
        if let eventForm: [String: Any] = self.eventForms.first(where: { (form) -> Bool in
            return form[FormKey.id.key] as? Int == observationForm[EventKey.formId.key] as? Int
        }) {
            formCell.configure(observationForm: observationForm, eventForm: eventForm, scheme: self.scheme);
        }
        
        return formCell
    }
}
