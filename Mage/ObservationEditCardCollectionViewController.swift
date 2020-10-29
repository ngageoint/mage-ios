//
//  ObservationEditCardCollection.swift
//  MAGE
//
//  Created by Daniel Barela on 5/1/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIKit
import MaterialComponents.MaterialCollections
import MaterialComponents.MDCCard

@objc protocol ObservationEditCardDelegate {
    @objc func addVoiceAttachment();
    @objc func addVideoAttachment();
    @objc func addCameraAttachment();
    @objc func addGalleryAttachment();
    @objc func deleteObservation();
    @objc func fieldSelected(field: [String: Any]);
    @objc func attachmentSelected(attachment: Attachment);
    @objc func addForm();
}

@objc class ObservationEditCardCollectionViewController: UIViewController { //}: MDCCollectionViewController {
    
    override func themeDidChange(_ theme: MageTheme) {
        self.navigationController?.navigationBar.isTranslucent = false;
        self.navigationController?.navigationBar.barTintColor = .primary();
        self.navigationController?.navigationBar.tintColor = .white;
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        self.view.backgroundColor = .tableBackground();
    }
    
    var delegate: ObservationEditCardDelegate?;
    var observation: Observation?;
    var newObservation: Bool = false;
    
    private lazy var eventForms: NSArray = {
        let eventForms = Event.getById(self.observation?.eventId as Any, in: (self.observation?.managedObjectContext)!).forms as? NSArray ?? [];
        return eventForms;
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        return scrollView;
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(forAutoLayout: ());
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 8
        stackView.distribution = .fill
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        stackView.isLayoutMarginsRelativeArrangement = true;
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        return stackView;
    }()
    
    private lazy var addFormFAB: MDCFloatingButton = {
        let fab = MDCFloatingButton(shape: .default);
        fab.accessibilityLabel = "Add Form";
        fab.mode = .expanded;
        fab.setImage(UIImage(named: "form")?.withRenderingMode(.alwaysTemplate), for: .normal);
        fab.setTitle("Add Form", for: .normal);
        fab.applySecondaryTheme(withScheme: globalContainerScheme());
        fab.addTarget(self, action: #selector(self.addForm(sender:)), for: .touchUpInside);
        return fab;
    }()
    
    private func addStackViewConstraints() {
        NSLayoutConstraint.activate([
            // Attaching the content's edges to the scroll view's edges
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            
            // Satisfying size constraints
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func addScrollViewConstraints() {
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(scrollView)
        addScrollViewConstraints();
        scrollView.addSubview(stackView)
        addStackViewConstraints();
        
        addCommonFields(stackView: stackView);
        addFormViews(stackView: stackView);
        
        if (eventForms.count != 0) {
            self.view.addSubview(addFormFAB);
            addFormFAB.autoPinEdge(toSuperviewMargin: .bottom);
            addFormFAB.autoPinEdge(toSuperviewMargin: .right);
        }
        
        // If there are forms and this is a new observation call addForm
        // It is expected that the delegate will add the form if only one exists
        // and prompt the user if more than one exists
        if (newObservation && eventForms.count != 0) {
            self.delegate?.addForm();
        }
        
        self.registerForThemeChanges();
    }
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil);
    }
    
    @objc convenience public init(delegate: ObservationEditCardDelegate, observation: Observation, newObservation: Bool) {
        self.init(frame: CGRect.zero);
        self.delegate = delegate;
        self.observation = observation;
        self.newObservation = newObservation;
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func addCommonFields(stackView: UIStackView) {
         if let safeObservation = observation {
             let commonFieldView: CommonFieldsView = CommonFieldsView(observation: safeObservation);
             commonFieldView.applyTheme(withScheme: globalContainerScheme());
             stackView.addArrangedSubview(commonFieldView);
         }
    }
    
    func addFormViews(stackView: UIStackView) {
        for (index, form) in getObservationForms().enumerated() {
            let card:ExpandableCard = addObservationFormView(observationForm: form, index: index);
            card.setExpanded(expanded: newObservation);
        }
    }
    
    func addObservationFormView(observationForm: [String: Any], index: Int) -> ExpandableCard {
        let predicate: NSPredicate = NSPredicate(format: "SELF.id = %@", argumentArray: [observationForm["formId"]!]);
        let eventForm: [String: Any] = self.eventForms.filtered(using: predicate).first as! [String : Any];
        var formPrimaryValue: String? = nil;
        var formSecondaryValue: String? = nil;
        if let primaryField = eventForm["primaryField"] as! String? {
            if let obsfield = observationForm[primaryField] as! String? {
                formPrimaryValue = obsfield;
            }
        }
        if let secondaryField = eventForm["variantField"] as! String? {
            if let obsfield = observationForm[secondaryField] as! String? {
                formSecondaryValue = obsfield;
            }
        }
        let formView = ObservationFormView(observation: self.observation!, form: observationForm, eventForm: eventForm, formIndex: index);
        let card = ExpandableCard(header: formPrimaryValue, subheader: formSecondaryValue, imageName: "form", title: eventForm["name"] as? String, expandedView: formView)
        stackView.addArrangedSubview(card);
        return card;
    }
    
    @objc func addForm(sender: UIButton) {
        self.delegate?.addForm();
    }
    
    public func formAdded(form: [String: Any]) {
        var newProperties: [String: Any] = self.observation?.properties as? [String: Any] ?? [:];
        var observationForms: [Any] = newProperties["forms"] as? [Any] ?? [];
        
        var newForm: [String: Any] = ["formId": form["id"]!];
        let defaults: FormDefaults = FormDefaults(eventId: self.observation?.eventId as! Int, formId: form["id"] as! Int);
        let formDefaults: [String: [String: Any]] = defaults.getDefaults() as! [String : [String: Any]];
        
        let fields: [[String : Any?]] = form["fields"] as! [[String : Any]];
        if (formDefaults.count > 0) { // user defaults
            for (_, field) in fields.enumerated() {
                var value: Any? = nil;
                if let defaultField: [String:Any] = formDefaults[field["id"] as! String] {
                    value = defaultField
                }
                
                if (value != nil) {
                    newForm[field["name"] as! String] = value;
                }
            }
        } else { // server defaults
            for (_, field) in fields.enumerated() {
                // grab the server default from the form fields value property
                if let value: Any = field["value"] {
                    newForm[field["name"] as! String] = value;
                }
            }
        }
        
        observationForms.append(newForm);
        newProperties["forms"] = observationForms;
        self.observation?.properties = newProperties;
        addObservationFormView(observationForm: newForm, index: observationForms.count - 1);
    }
    
    private func getObservationForms() -> [[String : Any]] {
        
        if var properties = self.observation?.properties as? [String : Any] {
            print("Properties is a thing");
            if let observationForms = properties["forms"] as? [[String : Any]] {
                print("forms is a thing")
            } else {
                properties["forms"] = [];
            }
            return properties["forms"] as! [[String : Any]];
        } else {
            self.observation?.properties = ["forms": []];
            return (self.observation?.properties as! [String : Any])["forms"] as! [[String : Any]];
        }
    }
}
