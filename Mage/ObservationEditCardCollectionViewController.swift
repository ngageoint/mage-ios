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
    var alreadyPromptedToAddForm: Bool = false;
    var scheme: MDCContainerScheming?;
    
    var cards: [ExpandableCard] = [];
    var formViews: [ObservationFormView] = [];
    var commonFieldView: CommonFieldsView?;
    private var keyboardHelper: KeyboardHelper?;
    private var bottomConstraint: NSLayoutConstraint?;
    
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
        scrollView.accessibilityIdentifier = "card scroll";
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
        bottomConstraint = stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -60)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            // Add room for the "Add Form" FAB
            bottomConstraint!,
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
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "close"), style: .plain, target: self, action: #selector(self.cancel(sender:)));
        self.navigationItem.leftBarButtonItem?.accessibilityLabel = "Cancel";
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
        
        keyboardHelper = KeyboardHelper { [weak self] animation, keyboardFrame, duration in
            guard let self = self else {
                return;
            }
            switch animation {
            case .keyboardWillShow:
                self.navigationItem.rightBarButtonItem?.isEnabled = false;
                self.navigationItem.leftBarButtonItem?.isEnabled = false;
                self.bottomConstraint?.constant = -keyboardFrame.height;
                self.view.layoutIfNeeded();

                if let firstResponder = self.stackView.firstResponder {
                    let firstResponderPoint = self.scrollView.convert(CGPoint(x: 0, y: firstResponder.frame.origin.y + 20), from: firstResponder.superview);
                    self.scrollView.setContentOffset(CGPoint(x:self.scrollView.contentOffset.x, y: firstResponderPoint.y - 60), animated: true);
                } else {
                    self.scrollView.contentOffset = CGPoint(x: self.scrollView.contentOffset.x, y: self.scrollView.contentOffset.y + keyboardFrame.height - 60)
                }

            case .keyboardWillHide:
                self.navigationItem.rightBarButtonItem?.isEnabled = true;
                self.navigationItem.leftBarButtonItem?.isEnabled = true;
                self.bottomConstraint?.constant = -60;
                self.view.layoutIfNeeded();
                self.enableDisabledFormFields(parent: self.stackView)
            
            case .keyboardDidShow:
                self.disableNonFirstResponderViews(parent: self.stackView)
            }
        }
    }
    
    func disableNonFirstResponderViews(parent: UIView) {
        for view: UIView in parent.subviews as [UIView] {
            if let view = view as? RadioFieldView {
                view.isUserInteractionEnabled = false
            } else if let view = view as? GeometryView {
                view.isUserInteractionEnabled = false
            } else if let view = view as? DropdownFieldView {
                view.isUserInteractionEnabled = false
            } else if let view = view as? MultiDropdownFieldView {
                view.isUserInteractionEnabled = false
            } else if let view = view as? AttachmentFieldView {
                view.isUserInteractionEnabled = false
            } else if let view = view as? CheckboxFieldView {
                view.isUserInteractionEnabled = false
            } else {
                disableNonFirstResponderViews(parent: view);
            }
        }
    }
    
    func enableDisabledFormFields(parent: UIView) {
        for view: UIView in parent.subviews as [UIView] {
            if let view = view as? RadioFieldView, !view.isUserInteractionEnabled {
                view.isUserInteractionEnabled = true
            } else if let view = view as? GeometryView, !view.isUserInteractionEnabled {
                view.isUserInteractionEnabled = true
            } else if let view = view as? DropdownFieldView, !view.isUserInteractionEnabled {
                view.isUserInteractionEnabled = true
            } else if let view = view as? MultiDropdownFieldView, !view.isUserInteractionEnabled {
                view.isUserInteractionEnabled = true
            } else if let view = view as? AttachmentFieldView, !view.isUserInteractionEnabled {
                view.isUserInteractionEnabled = true
            } else if let view = view as? CheckboxFieldView, !view.isUserInteractionEnabled {
                view.isUserInteractionEnabled = true
            } else {
                enableDisabledFormFields(parent: view);
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
        if (!alreadyPromptedToAddForm && newObservation && eventForms.count != 0 && observationForms.isEmpty) {
            alreadyPromptedToAddForm = true;
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
        addFormFAB.isHidden = false;
        if let safeScheme = self.scheme {
            addFormFAB.applySecondaryTheme(withScheme: safeScheme);
        }
        
        let realFormCount = self.observationForms.count - (self.observation?.getFormsToBeDeleted().count ?? 0);
        if ((MageServer.isServerVersion5() && realFormCount == 1) || eventForms.filter({ form in
            return !(form[FormKey.archived.key] as? Bool ?? false)
        }).count == 0) {
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
            commonFieldView = CommonFieldsView(observation: safeObservation, fieldSelectionDelegate: delegate, commonPropertiesListener: self);
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
        if (MageServer.isServerVersion5()) {
            if let safeObservation = observation {
                let attachmentCard: EditAttachmentCardView = EditAttachmentCardView(observation: safeObservation, attachmentSelectionDelegate: self, viewController: self);
                let attachmentHeader: AttachmentHeader = AttachmentHeader();
                if let safeScheme = self.scheme {
                    attachmentCard.applyTheme(withScheme: safeScheme);
                    attachmentHeader.applyTheme(withScheme: safeScheme);
                }
                stackView.addArrangedSubview(attachmentHeader);
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
            card.expanded = newObservation || index == 0;
        }
    }
    
    func addObservationFormView(observationForm: [String: Any], index: Int) -> ExpandableCard {
        let eventForm: [String: Any]? = self.eventForms.first { (form) -> Bool in
            return form[FormKey.id.key] as? Int == observationForm[EventKey.formId.key] as? Int
        }
        
        let fields: [[String: Any]] = eventForm?[FormKey.fields.key] as? [[String: Any]] ?? [];
        
        var formPrimaryValue: String? = nil;
        var formSecondaryValue: String? = nil;
        if let primaryFieldName = eventForm?[FormKey.primaryFeedField.key] as? String {
            if let primaryField = fields.first(where: { field in
                return (field[FieldKey.name.key] as? String) == primaryFieldName
            }) {
                if let obsfield = observationForm[primaryFieldName] {
                    formPrimaryValue = Observation.fieldValueText(obsfield, field: primaryField)
                }
            }
        }
        
        if let secondaryFieldName = eventForm?[FormKey.secondaryFeedField.key] as? String {
            if let secondaryField = fields.first(where: { field in
                return (field[FieldKey.name.key] as? String) == secondaryFieldName
            }) {
                if let obsfield = observationForm[secondaryFieldName] {
                    formSecondaryValue = Observation.fieldValueText(obsfield, field: secondaryField)
                }
            }
        }
        
        let formView = ObservationFormView(observation: self.observation!, form: observationForm, eventForm: eventForm, formIndex: index, viewController: self, observationFormListener: self, delegate: delegate, attachmentSelectionDelegate: self);
        if let scheme = scheme {
            formView.applyTheme(withScheme: scheme);
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
        if let color = eventForm?[FormKey.color.key] as? String {
            tintColor = UIColor(hex: color);
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
        if let observation = self.observation {
            self.commonFieldView?.setObservation(observation: observation);
        }
        
        setupFormDependentButtons();
        
        let message: MDCSnackbarMessage = MDCSnackbarMessage(text: "Form Removed");
        let messageAction = MDCSnackbarMessageAction();
        messageAction.title = "UNDO";
        let actionHandler = {() in
            self.cards[sender.tag].isHidden = false;
            self.observation?.removeForm(toBeDeleted: sender.tag);
            self.setupFormDependentButtons();
            if let observation = self.observation {
                self.commonFieldView?.setObservation(observation: observation);
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
        
        let fields: [[String: Any]] = eventForm?[FormKey.fields.key] as? [[String: Any]] ?? [];

        var formPrimaryValue: String? = nil;
        var formSecondaryValue: String? = nil;
        
        if let primaryFieldName = eventForm?[FormKey.primaryFeedField.key] as? String {
            if let primaryField = fields.first(where: { field in
                return (field[FieldKey.name.key] as? String) == primaryFieldName
            }) {
                if let obsfield = form[primaryFieldName] {
                    formPrimaryValue = Observation.fieldValueText(obsfield, field: primaryField)
                }
            }
        }
        
        if let secondaryFieldName = eventForm?[FormKey.secondaryFeedField.key] as? String {
            if let secondaryField = fields.first(where: { field in
                return (field[FieldKey.name.key] as? String) == secondaryFieldName
            }) {
                if let obsfield = form[secondaryFieldName] {
                    formSecondaryValue = Observation.fieldValueText(obsfield, field: secondaryField)
                }
            }
        }
        
        cards[index].header = formPrimaryValue;
        cards[index].subheader = formSecondaryValue;
    }
    
    @objc func reorderForms() {
        // allow MDCButton ink ripple
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            removeDeletedForms();
            guard let observation = self.observation else {
                return
            }
            self.delegate?.reorderForms(observation: observation);
        }
    }
    
    @objc func addForm(sender: UIButton) {
        let realFormCount = self.observationForms.count - (self.observation?.getFormsToBeDeleted().count ?? 0);

        if (realFormCount >= (event.maxObservationForms ?? NSNumber(value: NSIntegerMax)) as! Int) {
            // max amount of forms for this event have been added
            let message: MDCSnackbarMessage = MDCSnackbarMessage(text: "Total number of forms in an observation cannot be more than \(event.maxObservationForms ?? NSNumber(value: NSIntegerMax))");
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
        guard let observation = self.observation else { return }
        if (checkObservationValidity()) {
            self.delegate?.saveObservation(observation: observation);
        }
    }
    
    func checkObservationValidity() -> Bool {
        var valid: Bool = false;
        if let commonFieldView = commonFieldView {
            valid = commonFieldView.checkValidity(enforceRequired: true)
        } else {
            valid = true;
        }
        for formView in formViews {
            let formValid = formView.checkValidity(enforceRequired: true);
            valid = valid && formValid;
        }
        
        let realFormCount = self.observationForms.count - (self.observation?.getFormsToBeDeleted().count ?? 0);
        
        // if this is a legacy server and the event has forms, there needs to be 1
        if (MageServer.isServerVersion5()) {
            if (eventForms.count > 0 && realFormCount == 0) {
                let message: MDCSnackbarMessage = MDCSnackbarMessage(text: "One form must be added to this observation");
                let messageAction = MDCSnackbarMessageAction();
                messageAction.title = "OK";
                message.action = messageAction;
                MDCSnackbarManager.default.show(message);
                return false;
            }
            // this case should have already been prevented, but just in case
            if (realFormCount > 1) {
                let message: MDCSnackbarMessage = MDCSnackbarMessage(text: "Only one form can be added to this observation");
                let messageAction = MDCSnackbarMessageAction();
                messageAction.title = "OK";
                message.action = messageAction;
                MDCSnackbarManager.default.show(message);
                return false;
            }
        }
        // end legacy check
        
        if (realFormCount > (event.maxObservationForms ?? NSNumber(value: NSIntegerMax)) as! Int) {
            // too many forms
            let message: MDCSnackbarMessage = MDCSnackbarMessage(text: "Total number of forms in an observation cannot be more than \(event.maxObservationForms ?? NSNumber(value: NSIntegerMax))");
            let messageAction = MDCSnackbarMessageAction();
            messageAction.title = "OK";
            message.action = messageAction;
            MDCSnackbarManager.default.show(message);
            return false;
        }
        if (realFormCount < (event.minObservationForms ?? NSNumber(value: 0)) as! Int) {
            // not enough forms
            let message: MDCSnackbarMessage = MDCSnackbarMessage(text: "Total number of forms in an observation must be at least \(event.minObservationForms ?? 0)");
            let messageAction = MDCSnackbarMessageAction();
            messageAction.title = "OK";
            message.action = messageAction;
            MDCSnackbarManager.default.show(message);
            return false;
        }
        
        // check each form for min max
        var formIdCount: [Int : Int] = [ : ];
        if let observation = self.observation, let properties = observation.properties {
            if (properties.keys.contains(ObservationKey.forms.key)) {
                if let observationForms: [[String: Any]] = properties[ObservationKey.forms.key] as? [[String: Any]] {
                    let formsToBeDeleted = observation.getFormsToBeDeleted();
                    for (index, form) in observationForms.enumerated() {
                        if (!formsToBeDeleted.contains(index)) {
                            let formId = form[EventKey.formId.key] as! Int;
                            formIdCount[formId] = (formIdCount[formId] ?? 0) + 1;
                        }
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
        
        if (!valid) {
            let message: MDCSnackbarMessage = MDCSnackbarMessage(text: "The observation has validation errors.");
            let messageAction = MDCSnackbarMessageAction();
            messageAction.title = "OK";
            message.action = messageAction;
            MDCSnackbarManager.default.show(message);
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
        formViews = [];
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
        let previousStackViewHeight = stackView.bounds.size.height;
        let card:ExpandableCard = addObservationFormView(observationForm: newForm, index: observationForms.count - 1);
        if let scheme = scheme {
            card.applyTheme(withScheme: scheme);
        }
        card.expanded = true;
        // scroll the view down to the form they just added but not quite all the way down because then it looks like you
        // transitioned to a new view
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            let targetRect = CGRect(x: 0, y: previousStackViewHeight + min(UIScreen.main.bounds.size.height - 300, card.bounds.size.height + 75), width: 1, height: 1)
            scrollView.scrollRectToVisible(targetRect, animated: true)
        }
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

extension ObservationEditCardCollectionViewController: ObservationCommonPropertiesListener {
    func geometryUpdated(_ geometry: SFGeometry?, accuracy: String?, delta: Double?, provider: String?) {
        observationProperties[ObservationKey.accuracy.key] = accuracy;
        observationProperties[ObservationKey.delta.key] = delta;
        observationProperties[ObservationKey.provider.key] = provider;
        observation?.properties = observationProperties;
        observation?.setGeometry(geometry);
        if let observation = self.observation {
            commonFieldView?.setObservation(observation: observation);
        }
    }
    
    func timestampUpdated(_ date: Date?) {
        let formatter = ISO8601DateFormatter();
        formatter.formatOptions =  [.withInternetDateTime, .withFractionalSeconds]
        if let date = date {
            let formatter = ISO8601DateFormatter();
            formatter.formatOptions =  [.withInternetDateTime, .withFractionalSeconds]
            observationProperties[ObservationKey.timestamp.key] = formatter.string(from:date);
            observation?.timestamp = date;
        } else {
            observationProperties.removeValue(forKey: ObservationKey.timestamp.key)
            observation?.timestamp = nil;
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
    
    func attachmentFabTappedField(_ field: [AnyHashable : Any]!, completionHandler handler: ((Bool) -> Void)!) {
        handler(true);
        let message: MDCSnackbarMessage = MDCSnackbarMessage(text: "Attachment Deleted");
        let messageAction = MDCSnackbarMessageAction();
        messageAction.title = "UNDO";
        let actionHandler = {() in
            handler(false);
        }
        messageAction.handler = actionHandler;
        message.action = messageAction;
        MDCSnackbarManager.default.show(message);
    }
    
    func selectedAttachment(_ attachment: Attachment!) {
        if (attachment.url == nil) {
            return;
        }
        guard let nav = self.navigationController else {
            return;
        }
        attachmentViewCoordinator = AttachmentViewCoordinator(rootViewController: nav, attachment: attachment, delegate: self, scheme: scheme);
        attachmentViewCoordinator?.start();
    }
    
    func selectedUnsentAttachment(_ unsentAttachment: [AnyHashable : Any]!) {
        guard let nav = self.navigationController else {
            return;
        }
        attachmentViewCoordinator = AttachmentViewCoordinator(rootViewController: nav, url: URL(fileURLWithPath: unsentAttachment["localPath"] as! String), contentType: (unsentAttachment["contentType"] as! String), delegate: self, scheme: scheme);
        attachmentViewCoordinator?.start();
    }
    
    func selectedNotCachedAttachment(_ attachment: Attachment!, completionHandler handler: ((Bool) -> Void)!) {
        if (attachment.url == nil) {
            return;
        }
        guard let nav = self.navigationController else {
            return;
        }
        attachmentViewCoordinator = AttachmentViewCoordinator(rootViewController: nav, attachment: attachment, delegate: self, scheme: scheme);
        attachmentViewCoordinator?.start();
    }
}

extension ObservationEditCardCollectionViewController: AttachmentViewDelegate {
    func doneViewing(coordinator: NSObject) {
        attachmentViewCoordinator = nil;
    }
}
