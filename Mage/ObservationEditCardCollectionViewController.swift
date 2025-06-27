//
//  ObservationEditCardCollection.swift
//  MAGE
//
//  Created by Daniel Barela on 5/1/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIKit

@objc protocol ObservationEditCardDelegate {
    @objc func addForm()
    @objc func saveObservation(observation: Observation)
    @objc func cancelEdit()
    @objc func reorderForms(observation: Observation)
}

@objc protocol ObservationFormListener {
    func formUpdated(_ form: [String : Any], form index: Int)
}

@objc class ObservationEditCardCollectionViewController: UIViewController {
    @Injected(\.attachmentRepository)
    var attachmentRepository: AttachmentRepository
    
    var delegate: (ObservationEditCardDelegate & FieldSelectionDelegate)?
    var attachmentViewCoordinator: AttachmentViewCoordinator?
    var observation: Observation?
    var observationForms: [[String: Any]] = []
    var observationProperties: [String: Any] = [ : ]
    var newObservation: Bool = false
    var alreadyPromptedToAddForm: Bool = false
    var scheme: AppContainerScheming?
    
    var cards: [ExpandableCard] = []
    var formViews: [ObservationFormView] = []
    var commonFieldView: CommonFieldsView?
    private var keyboardHelper: KeyboardHelper?
    private var bottomConstraint: NSLayoutConstraint?
    
    private lazy var event: Event? = {
        guard let observation = observation, let eventId = observation.eventId, let context = observation.managedObjectContext else {
            return nil
        }

        return Event.getEvent(eventId: eventId, context: context)
    }()
        
    private lazy var eventForms: [Form]? = {
        return event?.forms
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.accessibilityIdentifier = "card scroll"
        scrollView.accessibilityLabel = "card scroll"
        return scrollView
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(forAutoLayout: ())
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 8
        stackView.distribution = .fill
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var formsHeader: FormsHeader = {
        let formsHeader = FormsHeader(forAutoLayout: ())
        return formsHeader
    }()
    
    // TODO: BRENT - FIX STYLING
    private lazy var addFormFAB: UIButton = {
        let faButton = FloatingButtonFactory.floatingButtonWithImageName("doc.text.fill", scheme: self.scheme, target: self, action: #selector(addForm(sender:)), tag: 99, accessibilityLabel: "Add Form")
        faButton.setTitle("Add Form", for: .normal)
        return faButton
    }
   
    
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
    
    func applyTheme(withContainerScheme containerScheme: AppContainerScheming?) {
        guard let containerScheme = containerScheme else {
            return
        }

        self.scheme = containerScheme
        addFormFAB.applySecondaryTheme(withScheme: scheme)
        
        self.view.backgroundColor = containerScheme.colorScheme.backgroundColor
        
        formsHeader.applyTheme(withScheme: containerScheme)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.accessibilityIdentifier = "ObservationEditCardCollection"
        self.view.accessibilityLabel = "ObservationEditCardCollection"
    
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(self.saveObservation(sender:)))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(self.cancel(sender:)))
        self.navigationItem.leftBarButtonItem?.accessibilityLabel = "Cancel"
        if (self.newObservation) {
            self.title = "Create Observation"
        } else {
            self.title = "Edit Observation"
        }
        
        self.view.addSubview(scrollView)
        addScrollViewConstraints()
        scrollView.addSubview(stackView)
        addStackViewConstraints()
        setupStackView(stackView: stackView)
        self.view.addSubview(addFormFAB)
        addFormFAB.autoPinEdge(toSuperviewMargin: .bottom)
        addFormFAB.autoPinEdge(toSuperviewMargin: .right)
        
        setupFormDependentButtons()
        
        keyboardHelper = KeyboardHelper { [weak self] animation, keyboardFrame, duration in
            guard let self = self else {
                return
            }
            switch animation {
            case .keyboardWillShow:
                self.navigationItem.rightBarButtonItem?.isEnabled = false
                self.navigationItem.leftBarButtonItem?.isEnabled = false
                self.bottomConstraint?.constant = -keyboardFrame.height
                self.view.layoutIfNeeded()

                if let firstResponder = self.stackView.firstResponder {
                    let firstResponderPoint = self.scrollView.convert(CGPoint(x: 0, y: firstResponder.frame.origin.y + 20), from: firstResponder.superview)
                    self.scrollView.setContentOffset(CGPoint(x:self.scrollView.contentOffset.x, y: firstResponderPoint.y - 60), animated: true)
                } else {
                    self.scrollView.contentOffset = CGPoint(x: self.scrollView.contentOffset.x, y: self.scrollView.contentOffset.y + keyboardFrame.height - 60)
                }

            case .keyboardWillHide:
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                self.navigationItem.leftBarButtonItem?.isEnabled = true
                self.bottomConstraint?.constant = -60
                self.view.layoutIfNeeded()
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
                disableNonFirstResponderViews(parent: view)
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
                enableDisabledFormFields(parent: view)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme(withContainerScheme: scheme)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // If there are forms and this is a new observation call addForm
        // It is expected that the delegate will add the form if only one exists
        // and prompt the user if more than one exists
        if (!alreadyPromptedToAddForm && newObservation && eventForms?.count != 0 && observationForms.isEmpty) {
            alreadyPromptedToAddForm = true
            self.delegate?.addForm()
        }
    }
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil)
    }
    
    @objc convenience public init(delegate: ObservationEditCardDelegate & FieldSelectionDelegate, observation: Observation, newObservation: Bool, containerScheme: AppContainerScheming?) {
        self.init(frame: CGRect.zero)
        self.scheme = containerScheme
        self.delegate = delegate
        setupObservation(observation: observation)
        self.newObservation = newObservation
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupFormDependentButtons() {
        addFormFAB.isEnabled = true
        addFormFAB.isHidden = false
        if let scheme = self.scheme {
            addFormFAB.applySecondaryTheme(withScheme: scheme)
        }
        
        let realFormCount = self.observationForms.count - (self.observation?.formsToBeDeleted.count ?? 0)
        if ((MageServer.isServerVersion5 && realFormCount == 1) || eventForms?.filter({ form in
            return !form.archived
        }).count == 0) {
            addFormFAB.isHidden = true
        }
        if (realFormCount >= (event?.maxObservationForms ?? NSNumber(value: NSIntegerMax)) as! Int) {
            addFormFAB.applySecondaryTheme(withScheme: globalDisabledScheme())
        }
        formsHeader.reorderButton.isHidden = realFormCount <= 1
    }
    
    func setupObservation(observation: Observation) {
        self.observation = observation
        if let properties = self.observation?.properties as? [String: Any] {
            if (properties.keys.contains(ObservationKey.forms.key)) {
                observationForms = properties[ObservationKey.forms.key] as! [[String: Any]]
            }
            self.observationProperties = properties
        } else {
            self.observationProperties = [ObservationKey.forms.key:[]]
            observationForms = []
        }
        commonFieldView?.setObservation(observation: observation)
    }
    
    func setupStackView(stackView: UIStackView) {
        addCommonFields(stackView: stackView)
        addLegacyAttachmentCard(stackView: stackView)
        addFormsHeader(stackView: stackView)
        addFormViews(stackView: stackView)
    }
    
    func addCommonFields(stackView: UIStackView) {
         if let observation = observation {
            commonFieldView = CommonFieldsView(observation: observation, fieldSelectionDelegate: delegate, commonPropertiesListener: self)
            commonFieldView!.applyTheme(withScheme: scheme)
            stackView.addArrangedSubview(commonFieldView!)
         }
    }
    
    func addFormsHeader(stackView: UIStackView) {
        stackView.addArrangedSubview(formsHeader)
        formsHeader.reorderButton.isHidden = self.observationForms.count <= 1
        formsHeader.reorderButton.addTarget(self, action: #selector(reorderForms), for: .touchUpInside)
    }
    
    // for legacy servers add the attachment field to common
    func addLegacyAttachmentCard(stackView: UIStackView) {
        if (MageServer.isServerVersion5) {
            if let observation = observation {
                let attachmentCard: EditAttachmentCardView = EditAttachmentCardView(observation: observation, attachmentSelectionDelegate: self, viewController: self)
                let attachmentHeader: CardHeader = CardHeader(headerText: "ATTACHMENTS")
                attachmentCard.applyTheme(withScheme: scheme)
                attachmentHeader.applyTheme(withScheme: scheme)
                stackView.addArrangedSubview(attachmentHeader)
                stackView.addArrangedSubview(attachmentCard)
            }
        }
    }
    
    func addFormViews(stackView: UIStackView) {
        for (index, form) in self.observationForms.enumerated() {
            let card:ExpandableCard = addObservationFormView(observationForm: form, index: index)
            card.applyTheme(withScheme: scheme)
            card.expanded = newObservation || index == 0
        }
    }
    
    func addObservationFormView(observationForm: [String: Any], index: Int) -> ExpandableCard {
        let eventForm = event?.form(id: observationForm[EventKey.formId.key] as? NSNumber)
        
        var formPrimaryValue: String? = nil
        var formSecondaryValue: String? = nil
        if let primaryField = eventForm?.primaryFeedField, let primaryFieldName = primaryField[FieldKey.name.key] as? String {
            if let obsfield = observationForm[primaryFieldName] {
                formPrimaryValue = Observation.fieldValueText(value: obsfield, field: primaryField)
            }
        }
        
        if let secondaryField = eventForm?.secondaryFeedField, let secondaryFieldName = secondaryField[FieldKey.name.key] as? String {
            if let obsfield = observationForm[secondaryFieldName] {
                formSecondaryValue = Observation.fieldValueText(value: obsfield, field: secondaryField)
            }
        }
        
        let formView = ObservationFormView(observation: self.observation!, form: observationForm, eventForm: eventForm, formIndex: index, viewController: self, observationFormListener: self, delegate: delegate, attachmentSelectionDelegate: self)
        if let scheme = scheme {
            formView.applyTheme(withScheme: scheme)
        }
        let formSpacerView = UIView(forAutoLayout: ())
        formSpacerView.addSubview(formView)
        formView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16), excludingEdge: .bottom)
        
        let button = UIButton(forAutoLayout: ())
        button.accessibilityLabel = "Delete Form"
        button.accessibilityIdentifier = "Delete Form"
        button.setTitle("Delete Form", for: .normal)
//        button.setInsets(forContentPadding: button.defaultContentEdgeInsets, imageTitlePadding: 5)
        button.addTarget(self, action: #selector(deleteForm(sender:)), for: .allTouchEvents)
        button.tag = index

        let divider = UIView(forAutoLayout: ())
        divider.backgroundColor = scheme?.colorScheme.onSurfaceColor?.withAlphaComponent(0.12) ?? UIColor.black.withAlphaComponent(0.12)
        divider.autoSetDimension(.height, toSize: 1)
        
        formSpacerView.addSubview(divider)
        divider.autoPinEdge(toSuperviewEdge: .left)
        divider.autoPinEdge(toSuperviewEdge: .right)
        divider.autoPinEdge(.top, to: .bottom, of: formView)
        
        formSpacerView.addSubview(button)
        button.autoPinEdge(toSuperviewEdge: .bottom, withInset: 16)
        button.autoPinEdge(toSuperviewEdge: .right, withInset: 16)
        button.autoPinEdge(.top, to: .bottom, of: divider, withOffset: 16)
//        button.applyTextTheme(withScheme: globalErrorContainerScheme())
        
        var tintColor: UIColor? = nil
        if let color = eventForm?.color {
            tintColor = UIColor(hex: color)
        } else {
            tintColor = scheme?.colorScheme.primaryColor
        }
        let card = ExpandableCard(header: formPrimaryValue, subheader: formSecondaryValue, systemImageName: "doc.text.fill", title: eventForm?.name, imageTint: tintColor, expandedView: formSpacerView)
        formView.containingCard = card
        stackView.addArrangedSubview(card)
        cards.append(card)
        formViews.append(formView)
        return card
    }
    
    @objc func deleteForm(sender: UIView) {
        // save the index of the deleted form and then next time we either save
        // or reorder remove the form so the user is not distracted with a refresh
        observation?.addFormToBeDeleted(formIndex: sender.tag)
        cards[sender.tag].isHidden = true
        if let observation = self.observation {
            self.commonFieldView?.setObservation(observation: observation)
        }
        
        setupFormDependentButtons()
        
        let alert = UIAlertController(title: nil, message: "Form Removed", preferredStyle: .alert)

        let undoAction = UIAlertAction(title: "UNDO", style: .default) { _ in
            self.cards[sender.tag].isHidden = false
            self.observation?.removeFormToBeDeleted(formIndex: sender.tag)
            self.setupFormDependentButtons()
            if let observation = self.observation {
                self.commonFieldView?.setObservation(observation: observation)
            }
        }

        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)

        alert.addAction(undoAction)
        alert.addAction(dismissAction)

        // Presenting the alert
        if let viewController = self.parentViewController {
            viewController.present(alert, animated: true)
        }
    }
    
    func setExpandableCardHeaderInformation(form: [String: Any], index: Int) {
        let eventForm = event?.form(id: form[EventKey.formId.key] as? NSNumber)
        
        var formPrimaryValue: String? = nil
        var formSecondaryValue: String? = nil
        if let primaryField = eventForm?.primaryFeedField, let primaryFieldName = primaryField[FieldKey.name.key] as? String {
            if let obsfield = form[primaryFieldName] {
                formPrimaryValue = Observation.fieldValueText(value: obsfield, field: primaryField)
            }
        }
        
        if let secondaryField = eventForm?.secondaryFeedField, let secondaryFieldName = secondaryField[FieldKey.name.key] as? String {
            if let obsfield = form[secondaryFieldName] {
                formSecondaryValue = Observation.fieldValueText(value: obsfield, field: secondaryField)
            }
        }
        
        cards[index].header = formPrimaryValue
        cards[index].subheader = formSecondaryValue
    }
    
    @objc func reorderForms() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            removeDeletedForms()
            guard let observation = self.observation else {
                return
            }
            self.delegate?.reorderForms(observation: observation)
        }
    }
    
    @objc func addForm(sender: UIButton) {
        let realFormCount = self.observationForms.count - (self.observation?.formsToBeDeleted.count ?? 0)

        if (realFormCount >= (event?.maxObservationForms ?? NSNumber(value: NSIntegerMax)) as! Int) {
            // max amount of forms for this event have been added
            AlertManager.shared.showAlertWithTitle(
                form.name ?? "",
                message: "Total number of forms in an observation cannot be more than \(event?.maxObservationForms ?? NSNumber(value: NSIntegerMax))",
                okTitle: "OK"
            )
        } else {
            self.delegate?.addForm()
        }
    }
    
    @objc func cancel(sender: UIBarButtonItem) {
        self.delegate?.cancelEdit()
    }
    
    @objc func saveObservation(sender: UIBarButtonItem) {
        removeDeletedForms()
        guard let observation = self.observation else { return }
        if (checkObservationValidity()) {
            self.delegate?.saveObservation(observation: observation)
        }
    }
    
    func checkObservationValidity() -> Bool {
        var scrolledToInvalidField = false
        var valid: Bool = false
        if let commonFieldView = commonFieldView {
            valid = commonFieldView.checkValidity(enforceRequired: true)
            if !valid {
                scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: 0), animated: true)
                scrolledToInvalidField = true
            }
        } else {
            valid = true
        }
        for formView in formViews {
            let formValid = formView.checkValidity(enforceRequired: true)
            valid = valid && formValid
            if !formValid && !scrolledToInvalidField {
                var yOffset:Double = 0.0
                var fieldViews = Array(formView.fieldViews.values)
                fieldViews.sort { ($0.field[FieldKey.id.key] as? Int ?? Int.max ) < ($1.field[FieldKey.id.key] as? Int ?? Int.max) }
                for subview in fieldViews {
                    if !subview.isValid(enforceRequired: true) && !scrolledToInvalidField {
                        yOffset += Double(subview.frame.origin.y)
                        yOffset += Double(-(bottomConstraint?.constant ?? 0.0))
                        scrollView.setContentOffset(CGPoint(x: Double(scrollView.contentOffset.x), y: yOffset), animated: true)
                        
                        scrolledToInvalidField = true
                    }
                }
            }
        }
        
        let realFormCount = self.observationForms.count - (self.observation?.formsToBeDeleted.count ?? 0)
        
        // if this is a legacy server and the event has forms, there needs to be 1
        if (MageServer.isServerVersion5) {
            if ((eventForms?.count ?? 0) > 0 && realFormCount == 0) {
                AlertManager.shared.showAlertWithTitle(
                    form.name ?? "",
                    message: "One form must be added to this observation",
                    okTitle: "OK"
                )
                return false
            }
            // this case should have already been prevented, but just in case
            if (realFormCount > 1) {
                AlertManager.shared.showAlertWithTitle(
                    form.name ?? "",
                    message: "Only one form can be added to this observation",
                    okTitle: "OK"
                )
                return false
            }
        }
        // end legacy check
        
        if (realFormCount > (event?.maxObservationForms ?? NSNumber(value: NSIntegerMax)) as! Int) {
            // too many forms
            if (realFormCount > 1) {
                AlertManager.shared.showAlertWithTitle(
                    form.name ?? "",
                    message: "Total number of forms in an observation cannot be more than \(event?.maxObservationForms ?? NSNumber(value: NSIntegerMax))",
                    okTitle: "OK"
                )
            return false
        }
        if (realFormCount < (event?.minObservationForms ?? NSNumber(value: 0)) as! Int) {
            // not enough forms
            AlertManager.shared.showAlertWithTitle(
                form.name ?? "",
                message: "Total number of forms in an observation must be at least \(event?.minObservationForms ?? 0)",
                okTitle: "OK"
            )
            return false
        }
        
        // check each form for min max
        var formIdCount: [Int : Int] = [ : ]
        if let observation = self.observation, let properties = observation.properties {
            if (properties.keys.contains(ObservationKey.forms.key)) {
                if let observationForms: [[String: Any]] = properties[ObservationKey.forms.key] as? [[String: Any]] {
                    let formsToBeDeleted = observation.formsToBeDeleted
                    for (index, form) in observationForms.enumerated() {
                        if (!formsToBeDeleted.contains(index)) {
                            let formId = form[EventKey.formId.key] as! Int
                            formIdCount[formId] = (formIdCount[formId] ?? 0) + 1
                        }
                    }
                }
            }
        }
        
        if let eventForms = eventForms {
            for eventForm in eventForms {
                let eventFormMin: Int = eventForm.min ?? 0
                let eventFormMax: Int = eventForm.max ?? Int.max
                let formCount = formIdCount[eventForm.formId?.intValue ?? Int.min] ?? 0
                // ignore archived forms when checkng min
                if (!eventForm.archived && formCount < eventFormMin) {
                    // not enough of this form
                    AlertManager.shared.showAlertWithTitle(
                        form.name ?? "",
                        message: "\(eventForm.name ?? "") form must be included in an observation at least \(eventFormMin) time\(eventFormMin == 1 ? "" : "s")",
                        okTitle: "OK"
                    )
                    return false
                }
                if (formCount > eventFormMax) {
                    // too many of this form
                    AlertManager.shared.showAlertWithTitle(
                        form.name ?? "",
                        message: "\(eventForm.name ?? "") form cannot be included in an observation more than \(eventFormMax) time\(eventFormMax == 1 ? "" : "s")",
                        okTitle: "OK"
                    )
                    return false
                }
            }
        }
        
        if (!valid) {
            AlertManager.shared.showAlertWithTitle(
                form.name ?? "",
                message: "The observation has validation errors.",
                okTitle: "OK"
            )
        }
            
        return valid
    }
    
    func removeDeletedForms() {
        if let formsToBeDeleted = observation?.formsToBeDeleted {
            observationForms.remove(atOffsets: formsToBeDeleted as IndexSet)
        }
        observationProperties[ObservationKey.forms.key] = observationForms
        self.observation?.properties = observationProperties
        for card in cards {
            card.removeFromSuperview()
        }
        cards = []
        setupObservation(observation: self.observation!)
        formViews = []
        addFormViews(stackView: stackView)
        
        observation?.clearFormsToBeDeleted()
    }
    
    public func formAdded(form: Form) {
        guard let formId = form.formId?.intValue else {
            return
        }
        var newForm: [String: AnyHashable] = [EventKey.formId.key: formId]
        let defaults: FormDefaults = FormDefaults(eventId: self.observation?.eventId as! Int, formId: formId)
        let formDefaults: [String: AnyHashable] = defaults.getDefaults() as! [String: AnyHashable]

        let fields: [[String : AnyHashable]] = (form.fields ?? []).filter { (($0[FieldKey.archived.key] as? Bool) == nil || ($0[FieldKey.archived.key] as? Bool) == false) }
        if (formDefaults.count > 0) { // user defaults
            for (_, field) in fields.enumerated() {
                var value: AnyHashable? = nil
                if let defaultField: AnyHashable = formDefaults[field[FieldKey.name.key] as! String] {
                    value = defaultField
                }
                
                if (value != nil) {
                    newForm[field[FieldKey.name.key] as! String] = value
                }
            }
        } else { // server defaults
            for (_, field) in fields.enumerated() {
                // grab the server default from the form fields value property
                if let value: AnyHashable = field[FieldKey.value.key] {
                    newForm[field[FieldKey.name.key] as! String] = value
                }
            }
        }
        
        observationForms.append(newForm)
        observationProperties[ObservationKey.forms.key] = observationForms
        self.observation?.properties = observationProperties
        let previousStackViewHeight = stackView.bounds.size.height
        let card:ExpandableCard = addObservationFormView(observationForm: newForm, index: observationForms.count - 1)
        if let scheme = scheme {
            card.applyTheme(withScheme: scheme)
        }
        card.expanded = true
        // scroll the view down to the form they just added but not quite all the way down because then it looks like you
        // transitioned to a new view
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            let targetRect = CGRect(x: 0, y: previousStackViewHeight + min(UIScreen.main.bounds.size.height - 300, card.bounds.size.height + 75), width: 1, height: 1)
            scrollView.scrollRectToVisible(targetRect, animated: true)
        }
        setupFormDependentButtons()
    }
    
    func formsReordered(observation: Observation) {
        for card in cards {
            card.removeFromSuperview()
        }
        cards = []
        setupObservation(observation: observation)
        addFormViews(stackView: stackView)
    }
}

extension ObservationEditCardCollectionViewController: ObservationFormListener {
    func formUpdated(_ form: [String : Any], form index: Int) {
        observationForms[index] = form
        observationProperties[ObservationKey.forms.key] = observationForms
        observation?.properties = observationProperties
        setExpandableCardHeaderInformation(form: form, index: index)
        if let observation = self.observation {
            commonFieldView?.setObservation(observation: observation)
        }
    }
}

extension ObservationEditCardCollectionViewController: ObservationCommonPropertiesListener {
    func geometryUpdated(_ geometry: SFGeometry?, accuracy: String?, delta: Double?, provider: String?) {
        observationProperties[ObservationKey.accuracy.key] = accuracy
        observationProperties[ObservationKey.delta.key] = delta
        observationProperties[ObservationKey.provider.key] = provider
        observation?.properties = observationProperties
        observation?.geometry = geometry
        if let observation = self.observation {
            commonFieldView?.setObservation(observation: observation)
        }
    }
    
    func timestampUpdated(_ date: Date?) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions =  [.withInternetDateTime, .withFractionalSeconds]
        if let date = date {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions =  [.withInternetDateTime, .withFractionalSeconds]
            observationProperties[ObservationKey.timestamp.key] = formatter.string(from:date)
            observation?.timestamp = date
        } else {
            observationProperties.removeValue(forKey: ObservationKey.timestamp.key)
            observation?.timestamp = nil
        }
    }
}

extension ObservationEditCardCollectionViewController: AttachmentSelectionDelegate {
    
    func attachmentFabTapped(_ attachmentUri: URL!, completionHandler handler: ((Bool) -> Void)!) {
        // delete the attachment
        attachmentRepository.markForDeletion(attachmentUri: attachmentUri)
        handler(true)
        
        let actionHandler = {() in
            self.attachmentRepository.undelete(attachmentUri: attachmentUri)
            handler(false)
        }
        
        AlertManager.shared.showUndoAlert(message: "Attachment Deleted", undoHandler: actionHandler)
    }
    
    func attachmentFabTappedField(_ field: [AnyHashable : Any]!, completionHandler handler: ((Bool) -> Void)!) {
        handler(true)

        let actionHandler = {() in
            handler(false)
        }

        AlertManager.shared.showUndoAlert(message: "Attachment Deleted", undoHandler: actionHandler)
    }
    
    func selectedAttachment(_ attachmentUri: URL!) {
        guard let nav = self.navigationController else {
            return
        }
        Task {
            if let attachment = await attachmentRepository.getAttachment(attachmentUri: attachmentUri) {
                attachmentViewCoordinator = AttachmentViewCoordinator(rootViewController: nav, attachment: attachment, delegate: self, scheme: scheme)
                attachmentViewCoordinator?.start()
            }
        }
    }
    
    func selectedUnsentAttachment(_ unsentAttachment: [AnyHashable : Any]!) {
        guard let nav = self.navigationController else {
            return
        }
        attachmentViewCoordinator = AttachmentViewCoordinator(rootViewController: nav, url: URL(fileURLWithPath: unsentAttachment["localPath"] as! String), contentType: (unsentAttachment["contentType"] as! String), delegate: self, scheme: scheme)
        attachmentViewCoordinator?.start()
    }
    
    func selectedNotCachedAttachment(_ attachmentUri: URL!, completionHandler handler: ((Bool) -> Void)!) {
        guard let nav = self.navigationController else {
            return
        }
        Task {
            if let attachment = await attachmentRepository.getAttachment(attachmentUri: attachmentUri) {
                attachmentViewCoordinator = AttachmentViewCoordinator(rootViewController: nav, attachment: attachment, delegate: self, scheme: scheme)
                attachmentViewCoordinator?.start()
            }
        }
    }
}

extension ObservationEditCardCollectionViewController: AttachmentViewDelegate {
    func doneViewing(coordinator: NSObject) {
        attachmentViewCoordinator = nil
    }
}
