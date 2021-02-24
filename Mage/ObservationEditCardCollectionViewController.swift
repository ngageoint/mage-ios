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
    @objc func addForm();
    @objc func saveObservation(observation: Observation);
    @objc func cancelEdit();
    @objc func reorderForms(observation: Observation);
}

@objc protocol ObservationFormListener {
    func formUpdated(_ form: [String : Any], eventForm: [String : Any], form index: Int);
}

@objc class ObservationEditCardCollectionViewController: UIViewController {
    
    var delegate: (ObservationEditCardDelegate & FieldSelectionDelegate)?;
    var attachmentViewCoordinator: AttachmentViewCoordinator?;
    var observation: Observation?;
    var observationForms: [[String: Any]] = [];
    var observationProperties: [String: Any] = [ : ];
    var newObservation: Bool = false;
    var scheme: MDCContainerScheming?;
    
    var cards: [ExpandableCard] = [];
    var formViews: [ObservationFormView] = [];
    var commonFieldView: CommonFieldsView?;
    private var keyboardHelper: KeyboardHelper?;
    
    private lazy var event: Event = {
        return Event.getById(self.observation?.eventId as Any, in: (self.observation?.managedObjectContext)!);
    }()
        
    private lazy var eventForms: [[String: Any]] = {
        let eventForms = event.forms as? [[String: Any]] ?? [];
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
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8)
        stackView.isLayoutMarginsRelativeArrangement = true;
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        return stackView;
    }()
    
    private lazy var formsHeader: FormsHeader = {
        let formsHeader = FormsHeader(forAutoLayout: ());
        return formsHeader;
    }()
    
    private lazy var addFormFAB: MDCFloatingButton = {
        let fab = MDCFloatingButton(shape: .default);
        fab.accessibilityLabel = "Add Form";
        fab.mode = .expanded;
        fab.setImage(UIImage(named: "form")?.withRenderingMode(.alwaysTemplate), for: .normal);
        fab.setTitle("Add Form", for: .normal);
        fab.addTarget(self, action: #selector(self.addForm(sender:)), for: .touchUpInside);
        return fab;
    }()
    
    private func addStackViewConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            // Add room for the "Add Form" FAB
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -60),
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
    
    func applyTheme(withContainerScheme containerScheme: MDCContainerScheming!) {
        self.scheme = containerScheme;
        addFormFAB.applySecondaryTheme(withScheme: containerScheme);
        
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
        
        formsHeader.applyTheme(withScheme: containerScheme);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.accessibilityIdentifier = "ObservationEditCardCollection"
        self.view.accessibilityLabel = "ObservationEditCardCollection"
    
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(self.saveObservation(sender:)));
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.cancel(sender:)));
        if (self.newObservation) {
            self.title = "Create Observation";
        } else {
            self.title = "Edit Observation";
        }
        
        self.view.addSubview(scrollView)
        addScrollViewConstraints();
        scrollView.addSubview(stackView)
        addStackViewConstraints();
        setupStackView(stackView: stackView);
        self.view.addSubview(addFormFAB);
        addFormFAB.autoPinEdge(toSuperviewMargin: .bottom);
        addFormFAB.autoPinEdge(toSuperviewMargin: .right);
        
        setupFormDependentButtons();
        
        keyboardHelper = KeyboardHelper { animation, keyboardFrame, duration in
            switch animation {
            case .keyboardWillShow:
                self.navigationItem.rightBarButtonItem?.isEnabled = false;
            case .keyboardWillHide:
                self.navigationItem.rightBarButtonItem?.isEnabled = true;
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        if let safeScheme = self.scheme {
            applyTheme(withContainerScheme: safeScheme);
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        // If there are forms and this is a new observation call addForm
        // It is expected that the delegate will add the form if only one exists
        // and prompt the user if more than one exists
        if (newObservation && eventForms.count != 0 && observationForms.isEmpty) {
            self.delegate?.addForm();
        }
    }
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil);
    }
    
    @objc convenience public init(delegate: ObservationEditCardDelegate & FieldSelectionDelegate, observation: Observation, newObservation: Bool, containerScheme: MDCContainerScheming?) {
        self.init(frame: CGRect.zero);
        self.scheme = containerScheme;
        self.delegate = delegate;
        setupObservation(observation: observation);
        self.newObservation = newObservation;
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupFormDependentButtons() {
        addFormFAB.isEnabled = true;
        if let safeScheme = self.scheme {
            addFormFAB.applySecondaryTheme(withScheme: safeScheme);
        }
        
        let realFormCount = self.observationForms.count - (self.observation?.getFormsToBeDeleted().count ?? 0);
        if ((MageServer.isServerVersion5() && realFormCount == 1) || eventForms.count == 0) {
            addFormFAB.isHidden = true;
        }
        if (realFormCount >= (event.maxObservationForms ?? NSNumber(value: NSIntegerMax)) as! Int) {
            addFormFAB.applySecondaryTheme(withScheme: globalDisabledScheme())
        }
        formsHeader.reorderButton.isHidden = realFormCount <= 1;
    }
    
    func setupObservation(observation: Observation) {
        self.observation = observation;
        if let safeProperties = self.observation?.properties as? [String: Any] {
            if (safeProperties.keys.contains(ObservationKey.forms.key)) {
                observationForms = safeProperties[ObservationKey.forms.key] as! [[String: Any]];
            }
            self.observationProperties = safeProperties;
        } else {
            self.observationProperties = [ObservationKey.forms.key:[]];
            observationForms = [];
        }
        commonFieldView?.setObservation(observation: observation);
    }
    
    func setupStackView(stackView: UIStackView) {
        addCommonFields(stackView: stackView);
        addLegacyAttachmentCard(stackView: stackView);
        addFormsHeader(stackView: stackView);
        addFormViews(stackView: stackView);
    }
    
    func addCommonFields(stackView: UIStackView) {
         if let safeObservation = observation {
            commonFieldView = CommonFieldsView(observation: safeObservation, fieldSelectionDelegate: delegate);
            if let safeScheme = scheme {
                commonFieldView!.applyTheme(withScheme: safeScheme);
            }
            stackView.addArrangedSubview(commonFieldView!);
         }
    }
    
    func addFormsHeader(stackView: UIStackView) {
        stackView.addArrangedSubview(formsHeader);
        formsHeader.reorderButton.isHidden = self.observationForms.count <= 1;
        formsHeader.reorderButton.addTarget(self, action: #selector(reorderForms), for: .touchUpInside);
    }
    
    // for legacy servers add the attachment field to common
    func addLegacyAttachmentCard(stackView: UIStackView) {
        if (UserDefaults.standard.serverMajorVersion == 5) {
            if let safeObservation = observation {
                let attachmentCard: EditAttachmentCardView = EditAttachmentCardView(observation: safeObservation, attachmentSelectionDelegate: self, viewController: self);
                if let safeScheme = self.scheme {
                    attachmentCard.applyTheme(withScheme: safeScheme);
                }
                stackView.addArrangedSubview(attachmentCard);
            }
        }
    }
    
    func addFormViews(stackView: UIStackView) {
        for (index, form) in self.observationForms.enumerated() {
            let card:ExpandableCard = addObservationFormView(observationForm: form, index: index);
            if let safeScheme = scheme {
                card.applyTheme(withScheme: safeScheme);
            }
            card.expanded = newObservation || self.observationForms.count == 1;
        }
    }
    
    func addObservationFormView(observationForm: [String: Any], index: Int) -> ExpandableCard {
        let eventForm: [String: Any]? = self.eventForms.first { (form) -> Bool in
            return form[FormKey.id.key] as? Int == observationForm[EventKey.formId.key] as? Int
        }
        
        var formPrimaryValue: String? = nil;
        var formSecondaryValue: String? = nil;
        if let primaryField = eventForm?[FormKey.primaryField.key] as! String? {
            if let obsfield = observationForm[primaryField] as! String? {
                formPrimaryValue = obsfield;
            }
        }
        if let secondaryField = eventForm?[FormKey.secondaryField.key] as! String? {
            if let obsfield = observationForm[secondaryField] as! String? {
                formSecondaryValue = obsfield;
            }
        }
        let formView = ObservationFormView(observation: self.observation!, form: observationForm, eventForm: eventForm, formIndex: index, viewController: self, observationFormListener: self, delegate: delegate);
        if let safeScheme = scheme {
            formView.applyTheme(withScheme: safeScheme);
        }
        let formSpacerView = UIView(forAutoLayout: ());
        formSpacerView.addSubview(formView);
        formView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16), excludingEdge: .bottom);
        let button = MDCButton(forAutoLayout: ());
        button.accessibilityLabel = "delete form";
        button.setTitle("Delete Form", for: .normal);
        button.setInsets(forContentPadding: button.defaultContentEdgeInsets, imageTitlePadding: 5);
        button.addTarget(self, action: #selector(deleteForm(sender:)), for: .touchUpInside);
        button.tag = index;

        let divider = UIView(forAutoLayout: ());
        divider.backgroundColor = UIColor.black.withAlphaComponent(0.12);
        divider.autoSetDimension(.height, toSize: 1);
        formSpacerView.addSubview(divider);
        divider.autoPinEdge(toSuperviewEdge: .left);
        divider.autoPinEdge(toSuperviewEdge: .right);
        divider.autoPinEdge(.top, to: .bottom, of: formView);
        formSpacerView.addSubview(button);
        button.autoPinEdge(toSuperviewEdge: .bottom, withInset: 16);
        button.autoPinEdge(toSuperviewEdge: .right, withInset: 16);
        button.autoPinEdge(.top, to: .bottom, of: divider, withOffset: 16);
        button.applyTextTheme(withScheme: globalErrorContainerScheme())
        
        var tintColor: UIColor? = nil;
        if let safeColor = eventForm?[FormKey.color.key] as? String {
            tintColor = UIColor(hex: safeColor);
        } else {
            tintColor = scheme?.colorScheme.primaryColor
        }
        let card = ExpandableCard(header: formPrimaryValue, subheader: formSecondaryValue, imageName: "description", title: eventForm?[EventKey.name.key] as? String, imageTint: tintColor, expandedView: formSpacerView)
        formView.containingCard = card;
        stackView.addArrangedSubview(card);
        cards.append(card);
        formViews.append(formView);
        return card;
    }
    
    @objc func deleteForm(sender: UIView) {
        // save the index of the deleted form and then next time we either save
        // or reorder remove the form so the user is not distracted with a refresh
        observation?.addForm(toBeDeleted: sender.tag);
        cards[sender.tag].isHidden = true;
        if let safeObservation = self.observation {
            self.commonFieldView?.setObservation(observation: safeObservation);
        }
        
        setupFormDependentButtons();
        
        let message: MDCSnackbarMessage = MDCSnackbarMessage(text: "Form Removed");
        let messageAction = MDCSnackbarMessageAction();
        messageAction.title = "UNDO";
        let actionHandler = {() in
            self.cards[sender.tag].isHidden = false;
            self.observation?.removeForm(toBeDeleted: sender.tag);
            self.setupFormDependentButtons();
            if let safeObservation = self.observation {
                self.commonFieldView?.setObservation(observation: safeObservation);
            }
        }
        messageAction.handler = actionHandler;
        message.action = messageAction;
        MDCSnackbarManager.default.show(message);
    }
    
    func setExpandableCardHeaderInformation(form: [String: Any], index: Int) {
        let eventForm: [String: Any]? = self.eventForms.first { (eventForm) -> Bool in
            return eventForm[FormKey.id.key] as? Int == form[EventKey.formId.key] as? Int
        }
        var formPrimaryValue: String? = nil;
        var formSecondaryValue: String? = nil;
        if let primaryField = eventForm?[FormKey.primaryField.key] as! String? {
            if let obsfield = form[primaryField] as? String {
                formPrimaryValue = obsfield;
            }
        }
        if let secondaryField = eventForm?[FormKey.secondaryField.key] as! String? {
            // TODO: handle non strings
            if let obsfield = form[secondaryField] as! String? {
                formSecondaryValue = obsfield;
            }
        }
        cards[index].header = formPrimaryValue;
        cards[index].subheader = formSecondaryValue;
    }
    
    @objc func reorderForms() {
        removeDeletedForms();
        guard let safeObservation = self.observation else { return }
        self.delegate?.reorderForms(observation: safeObservation);
    }
    
    @objc func addForm(sender: UIButton) {
        let realFormCount = self.observationForms.count - (self.observation?.getFormsToBeDeleted().count ?? 0);

        if (realFormCount >= (event.maxObservationForms ?? NSNumber(value: NSIntegerMax)) as! Int) {
            // max amount of forms for this event have been added
            let message: MDCSnackbarMessage = MDCSnackbarMessage(text: "Total number of forms in observation cannot be more than \(event.maxObservationForms ?? NSNumber(value: NSIntegerMax))");
            let messageAction = MDCSnackbarMessageAction();
            messageAction.title = "OK";
            message.action = messageAction;
            MDCSnackbarManager.default.show(message);
        } else {
            self.delegate?.addForm();
        }
    }
    
    @objc func cancel(sender: UIBarButtonItem) {
        self.delegate?.cancelEdit();
    }
    
    @objc func saveObservation(sender: UIBarButtonItem) {
        removeDeletedForms();
        guard let safeObservation = self.observation else { return }
        if (checkObservationValidity()) {
            self.delegate?.saveObservation(observation: safeObservation);
        }
    }
    
    func checkObservationValidity() -> Bool {
        var valid: Bool = commonFieldView?.checkValidity(enforceRequired: true) ?? true;
        for formView in formViews {
            let formValid = formView.checkValidity(enforceRequired: true);
            valid = valid && formValid;
        }
        
        let realFormCount = self.observationForms.count - (self.observation?.getFormsToBeDeleted().count ?? 0);
        
        if (realFormCount > (event.maxObservationForms ?? NSNumber(value: NSIntegerMax)) as! Int) {
            // too many forms
            let message: MDCSnackbarMessage = MDCSnackbarMessage(text: "Total number of forms in observation cannot be more than \(event.maxObservationForms ?? NSNumber(value: NSIntegerMax))");
            let messageAction = MDCSnackbarMessageAction();
            messageAction.title = "OK";
            message.action = messageAction;
            MDCSnackbarManager.default.show(message);
            return false;
        }
        if (realFormCount < (event.minObservationForms ?? NSNumber(value: 0)) as! Int) {
            // not enough forms
            let message: MDCSnackbarMessage = MDCSnackbarMessage(text: "Total number of forms in an observation must be at least  \(event.minObservationForms ?? 0)");
            let messageAction = MDCSnackbarMessageAction();
            messageAction.title = "OK";
            message.action = messageAction;
            MDCSnackbarManager.default.show(message);
            return false;
        }
        
        // check each form for min max
        var formIdCount: [Int : Int] = [ : ];
        if let safeObservation = self.observation, let safeProperties = safeObservation.properties {
            if (safeProperties.keys.contains(ObservationKey.forms.key)) {
                let observationForms: [[String: Any]] = safeProperties[ObservationKey.forms.key] as! [[String: Any]];
                let formsToBeDeleted = observation?.getFormsToBeDeleted() ?? IndexSet();
                for (index, form) in observationForms.enumerated() {
                    if (!formsToBeDeleted.contains(index)) {
                        let formId = form[EventKey.formId.key] as! Int;
                        formIdCount[formId] = (formIdCount[formId] ?? 0) + 1;
                    }
                }
            }
        }
        
        for eventForm in eventForms {
            let eventFormMin: Int = (eventForm[FieldKey.min.key] as? Int) ?? 0;
            let eventFormMax: Int = (eventForm[FieldKey.max.key] as? Int) ?? Int.max;
            let formCount = formIdCount[eventForm[FieldKey.id.key] as! Int] ?? 0;
            if (formCount < eventFormMin) {
                // not enough of this form
                let message: MDCSnackbarMessage = MDCSnackbarMessage(text: "\(eventForm[FieldKey.name.key] ?? "") form must be included in an observation at least \(eventFormMin) time\(eventFormMin == 1 ? "" : "s")");
                let messageAction = MDCSnackbarMessageAction();
                messageAction.title = "OK";
                message.action = messageAction;
                MDCSnackbarManager.default.show(message);
                return false;
            }
            if (formCount > eventFormMax) {
                // too many of this form
                let message: MDCSnackbarMessage = MDCSnackbarMessage(text: "\(eventForm[FieldKey.name.key] ?? "") form cannot be included in an observation more than \(eventFormMax) time\(eventFormMax == 1 ? "" : "s")");
                let messageAction = MDCSnackbarMessageAction();
                messageAction.title = "OK";
                message.action = messageAction;
                MDCSnackbarManager.default.show(message);
                return false;
            }
        }
        
        return valid;
    }
    
    func removeDeletedForms() {
        if let formsToBeDeleted = observation?.getFormsToBeDeleted() {
            observationForms.remove(atOffsets: formsToBeDeleted);
        }
        observationProperties[ObservationKey.forms.key] = observationForms;
        self.observation?.properties = observationProperties;
        for card in cards {
            card.removeFromSuperview();
        }
        cards = [];
        setupObservation(observation: self.observation!);
        addFormViews(stackView: stackView);
        
        observation?.clearFormsToBeDeleted();
    }
    
    public func formAdded(form: [String: Any]) {
        var newForm: [String: AnyHashable] = [EventKey.formId.key: form[FieldKey.id.key] as! Int];
        let defaults: FormDefaults = FormDefaults(eventId: self.observation?.eventId as! Int, formId: form[FieldKey.id.key] as! Int);
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
        
        observationForms.append(newForm);
        observationProperties[ObservationKey.forms.key] = observationForms;
        self.observation?.properties = observationProperties;
        let card:ExpandableCard = addObservationFormView(observationForm: newForm, index: observationForms.count - 1);
        if let safeScheme = scheme {
            card.applyTheme(withScheme: safeScheme);
        }
        card.expanded = true;
        // scroll the view down to the form they just added but not quite all the way down because then it looks like you
        // transitioned to a new view
        scrollView.setContentOffset(CGPoint(x: 0, y: stackView.bounds.size.height - 75), animated: true);
        setupFormDependentButtons();
    }
    
    func formsReordered(observation: Observation) {
        for card in cards {
            card.removeFromSuperview();
        }
        cards = [];
        setupObservation(observation: observation);
        addFormViews(stackView: stackView);
    }
}

extension ObservationEditCardCollectionViewController: ObservationFormListener {
    func formUpdated(_ form: [String : Any], eventForm: [String : Any], form index: Int) {
        observationForms[index] = form
        observationProperties[ObservationKey.forms.key] = observationForms;
        observation?.properties = observationProperties;
        setExpandableCardHeaderInformation(form: form, index: index);
        if let safeObservation = self.observation {
            commonFieldView?.setObservation(observation: safeObservation);
        }
    }
}

extension ObservationEditCardCollectionViewController: AttachmentSelectionDelegate {
    
    func attachmentFabTapped(_ attachment: Attachment!, completionHandler handler: ((Bool) -> Void)!) {
        // delete the attachment
        attachment.markedForDeletion = true;
        attachment.dirty = true;
        handler(true);
        let message: MDCSnackbarMessage = MDCSnackbarMessage(text: "Attachment Deleted");
        let messageAction = MDCSnackbarMessageAction();
        messageAction.title = "UNDO";
        let actionHandler = {() in
            attachment.markedForDeletion = false;
            attachment.dirty = false;
            handler(false);
        }
        messageAction.handler = actionHandler;
        message.action = messageAction;
        MDCSnackbarManager.default.show(message);
    }
    
    func selectedAttachment(_ attachment: Attachment!) {
        attachmentViewCoordinator = AttachmentViewCoordinator(rootViewController: self.navigationController!, attachment: attachment, delegate: self);
        attachmentViewCoordinator?.start();
    }
}

extension ObservationEditCardCollectionViewController: AttachmentViewDelegate {
    func doneViewing(coordinator: NSObject) {
        attachmentViewCoordinator = nil;
    }
}
