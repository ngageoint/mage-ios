//
//  ObservationFormReorder.swift
//  MAGE
//
//  Created by Daniel Barela on 1/19/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

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
    var scheme: AppContainerScheming?;
    
    private lazy var event: Event? = {
        guard let eventId = observation.eventId, let context = observation.managedObjectContext else {
            return nil
        }
        
        return Event.getEvent(eventId: eventId, context: context)
    }()
    
    private lazy var eventForms: [Form]? = {
        return event?.forms
    }()
    
    private lazy var descriptionHeaderView: UILabel = {
        let label = UILabel(forAutoLayout: ());
        label.text = "The first form in this list is the primary form, which determines how MAGE displays the observation on the map and in the feed. The forms will be displayed, as ordered, in all other views.";
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
    
    public init(observation: Observation, delegate: ObservationFormReorderDelegate, containerScheme: AppContainerScheming?) {
        self.observation = observation
        self.delegate = delegate;
        self.scheme = containerScheme;
        super.init(style: .grouped)
        self.title = "Reorder Forms";
        self.view.accessibilityLabel = "Reorder Forms";
        tableView.register(cellClass: ObservationFormTableViewCell.self)
        if let properties = self.observation.properties as? [String: Any] {
            if (properties.keys.contains(ObservationKey.forms.key)) {
                observationForms = properties[ObservationKey.forms.key] as! [[String: Any]];
            }
            self.observationProperties = properties;
        } else {
            self.observationProperties = [ObservationKey.forms.key:[]];
            observationForms = [];
        }
    }
    
    func applyTheme(withContainerScheme containerScheme: AppContainerScheming?) {
        guard let containerScheme = containerScheme else {
            return
        }

        self.scheme = containerScheme;
        self.tableView.backgroundColor = containerScheme.colorScheme.backgroundColor;
        self.view.backgroundColor = containerScheme.colorScheme.backgroundColor;
        
//        self.descriptionHeaderView.font = containerScheme.typographyScheme.overline;
        self.descriptionHeaderView.textColor = containerScheme.colorScheme.onBackgroundColor?.withAlphaComponent(0.6)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Apply", style: .done, target: self, action: #selector(self.saveFormOrder(sender:)));
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(self.cancel(sender:)));
        
        self.tableView.isEditing = true;
        self.tableView.rowHeight = UITableView.automaticDimension;
        self.tableView.estimatedRowHeight = 64;
        self.tableView.tableFooterView = UIView();
        self.view.addSubview(headerView);
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        applyTheme(withContainerScheme: scheme);
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
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Drag to reorder forms";
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
        if let eventForm: Form = self.eventForms?.first(where: { (form) -> Bool in
            return form.formId?.intValue == observationForm[EventKey.formId.key] as? Int
        }) {
            formCell.configure(observationForm: observationForm, eventForm: eventForm, scheme: self.scheme);
        }
        
        return formCell
    }
}
