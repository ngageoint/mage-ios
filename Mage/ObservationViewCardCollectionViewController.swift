//
//  ObservationViewCardCollectionViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 12/16/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIKit
import MaterialComponents.MaterialCollections
import MaterialComponents.MDCCard
import MaterialComponents.MDCContainerScheme;

class ObservationViewCardCollectionViewController: UIViewController {
    
    var didSetupConstraints = false;
    
    weak var observation: Observation?;
    var observationForms: [[String: Any]] = [];
    var cards: [ExpandableCard] = [];
    var attachmentViewCoordinator: AttachmentViewCoordinator?;
    var headerCard: ObservationHeaderView?;
    var observationEditCoordinator: ObservationEditCoordinator?;
    var bottomSheet: MDCBottomSheetController?;
    var scheme: MDCContainerScheming?;
    var attachmentCard: ObservationAttachmentCard?;
    let attachmentHeader: CardHeader = CardHeader(headerText: "ATTACHMENTS");
    let formsHeader = FormsHeader(forAutoLayout: ());
    
    private lazy var event: Event? = {
        guard let observation = observation, let eventId = observation.eventId, let context = observation.managedObjectContext else {
            return nil
        }
        
        return Event.getEvent(eventId: eventId, context: context)
    }()
    
    private lazy var eventForms: [Form] = {
        return event?.forms ?? []
    }()
    
    private lazy var editFab : MDCFloatingButton = {
        let fab = MDCFloatingButton(shape: .default);
        fab.setImage(UIImage(named: "edit"), for: .normal);
        fab.addTarget(self, action: #selector(startObservationEditCoordinator), for: .touchUpInside);
        return fab;
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView.newAutoLayout();
        scrollView.accessibilityIdentifier = "card scroll";
        scrollView.contentInset.bottom = 100;
        return scrollView;
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView.newAutoLayout();
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 8
        stackView.distribution = .fill
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        stackView.isLayoutMarginsRelativeArrangement = true;
        return stackView;
    }()
    
    private lazy var syncStatusView: ObservationSyncStatus = {
        let syncStatusView = ObservationSyncStatus(observation: observation);
        stackView.addArrangedSubview(syncStatusView);
        return syncStatusView;
    }()
    
    func applyTheme(withContainerScheme containerScheme: MDCContainerScheming?) {
        self.scheme = containerScheme;
        guard let containerScheme = containerScheme else {
            return;
        }
        self.view.backgroundColor = containerScheme.colorScheme.backgroundColor;
        self.syncStatusView.applyTheme(withScheme: containerScheme);
        headerCard?.applyTheme(withScheme: containerScheme);
        attachmentCard?.applyTheme(withScheme: containerScheme);
        formsHeader.applyTheme(withScheme: containerScheme);
        attachmentHeader.applyTheme(withScheme: containerScheme);
        editFab.applySecondaryTheme(withScheme: containerScheme);
    }
    
    override func loadView() {
        view = UIView();
        
        view.addSubview(scrollView);
        scrollView.addSubview(stackView);
        view.addSubview(editFab);
        
        let user = User.fetchCurrentUser(context: NSManagedObjectContext.mr_default())
        editFab.isHidden = !(user?.hasEditPermission ?? false)
        
        view.setNeedsUpdateConstraints();
    }
    
    override func updateViewConstraints() {
        if (!didSetupConstraints) {
            scrollView.autoPinEdgesToSuperviewEdges(with: .zero);
            stackView.autoPinEdgesToSuperviewEdges();
            stackView.autoMatch(.width, to: .width, of: view);
            editFab.autoPinEdge(toSuperviewMargin: .right);
            editFab.autoPinEdge(toSuperviewMargin: .bottom, withInset: 25);
            didSetupConstraints = true;
        }
        
        super.updateViewConstraints();
    }
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil);
    }
    
    convenience public init(observation: Observation, scheme: MDCContainerScheming?) {
        self.init(frame: CGRect.zero);
        self.observation = observation;
        self.scheme = scheme;
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.accessibilityIdentifier = "ObservationViewCardCollection"
        self.view.accessibilityLabel = "ObservationViewCardCollection"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        ObservationPushService.singleton.addDelegate(delegate: self);
        setupObservation();
        if let scheme = self.scheme {
            applyTheme(withContainerScheme: scheme);
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        
        let removedSubviews = cards.reduce([]) { (allSubviews, subview) -> [UIView] in
            stackView.removeArrangedSubview(subview)
            return allSubviews + [subview]
        }
        
        for v in removedSubviews {
            if v.superview != nil {
                v.removeFromSuperview()
            }
        }
        cards = [];
        ObservationPushService.singleton.removeDelegate(delegate: self);
    }
    
    func setupObservation() {
        self.title = "Observation";

        if let properties = self.observation?.properties as? [String: Any] {
            if (properties.keys.contains("forms")) {
                observationForms = properties["forms"] as! [[String: Any]];
            }
        } else {
            observationForms = [];
        }
        
        syncStatusView.updateObservationStatus(observation: observation);
        addHeaderCard(stackView: stackView);
        addLegacyAttachmentCard(stackView: stackView);
        var headerViews = 2;
        if (MageServer.isServerVersion5) {
            headerViews = 4;
        }
        if (stackView.arrangedSubviews.count > headerViews) {
            for v in stackView.arrangedSubviews.suffix(from: headerViews) {
                v.removeFromSuperview();
            }
        }
        
        addFormViews(stackView: stackView);
    }
    
    func addHeaderCard(stackView: UIStackView) {
        if let observation = observation {
            if let headerCard = headerCard {
                headerCard.populate(observation: observation);
            } else {
                headerCard = ObservationHeaderView(observation: observation, observationActionsDelegate: self);
                if let scheme = self.scheme {
                    headerCard!.applyTheme(withScheme: scheme);
                }
                stackView.addArrangedSubview(headerCard!);
            }
        }
    }
    
    // for legacy servers add the attachment field to common
    // TODO: this can be removed once all servers are upgraded
    func addLegacyAttachmentCard(stackView: UIStackView) {
        if (MageServer.isServerVersion5) {
            if let observation = observation {
                if let attachmentCard = attachmentCard {
                    attachmentCard.populate(observation: observation);
                } else {
                    attachmentCard = ObservationAttachmentCard(observation: observation, attachmentSelectionDelegate: self);
                    if let scheme = self.scheme {
                        attachmentCard!.applyTheme(withScheme: scheme);
                        attachmentHeader.applyTheme(withScheme: scheme);
                    }
                    stackView.addArrangedSubview(attachmentHeader);
                    stackView.addArrangedSubview(attachmentCard!);
                }
                
                let attachmentCount = (observation.attachments)?.filter() { attachment in
                    return !attachment.markedForDeletion
                }.count
                
                if (attachmentCount != 0) {
                    attachmentHeader.isHidden = false;
                    attachmentCard?.isHidden = false;
                } else {
                    attachmentHeader.isHidden = true;
                    attachmentCard?.isHidden = true;
                }
            }
        }
    }
    
    func addFormViews(stackView: UIStackView) {
        formsHeader.reorderButton.isHidden = true;
        stackView.addArrangedSubview(formsHeader);
        for (index, form) in self.observationForms.enumerated() {
            let card: ExpandableCard = addObservationFormView(observationForm: form, index: index);
            card.expanded = index == 0;
        }
    }
    
    func addObservationFormView(observationForm: [String: Any], index: Int) -> ExpandableCard {
        let eventForm = event?.form(id: observationForm[EventKey.formId.key] as? NSNumber)
        
        var formPrimaryValue: String? = nil;
        var formSecondaryValue: String? = nil;
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
        
        let formView = ObservationFormView(observation: self.observation!, form: observationForm, eventForm: eventForm, formIndex: index, editMode: false, viewController: self, attachmentSelectionDelegate: self, observationActionsDelegate: self);
        if let scheme = self.scheme {
            formView.applyTheme(withScheme: scheme);
        }
        var formSpacerView: UIView?;
        if (!formView.isEmpty()) {
            formSpacerView = UIView(forAutoLayout: ());
            let divider = UIView(forAutoLayout: ());
            divider.backgroundColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.12) ?? UIColor.black.withAlphaComponent(0.12);
            divider.autoSetDimension(.height, toSize: 1);
            formSpacerView?.addSubview(divider);
            formSpacerView?.addSubview(formView);
            divider.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
            formView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16));
        }
        var tintColor: UIColor? = nil;
        if let color = eventForm?.color {
            tintColor = UIColor(hex: color);
        } else {
            tintColor = scheme?.colorScheme.primaryColor
        }
        let card = ExpandableCard(header: formPrimaryValue, subheader: formSecondaryValue, imageName: "description", title: eventForm?.name, imageTint: tintColor, expandedView: formSpacerView);
        if let scheme = self.scheme {
            card.applyTheme(withScheme: scheme);
        }
        stackView.addArrangedSubview(card);
        cards.append(card);
        return card;
    }
    
    @objc func startObservationEditCoordinator() {
        guard let observation = self.observation else {
            return;
        }
        observationEditCoordinator = ObservationEditCoordinator(rootViewController: self.navigationController, delegate: self, observation: observation);
        observationEditCoordinator?.applyTheme(withContainerScheme: self.scheme);
        observationEditCoordinator?.start();
    }
}

extension ObservationViewCardCollectionViewController: AttachmentSelectionDelegate {
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
        attachmentViewCoordinator = AttachmentViewCoordinator(rootViewController: nav, url: URL(fileURLWithPath: unsentAttachment["localPath"] as! String), contentType: unsentAttachment["contentType"] as! String, delegate: self, scheme: scheme);
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

extension ObservationViewCardCollectionViewController: AttachmentViewDelegate {
    func doneViewing(coordinator: NSObject) {
        attachmentViewCoordinator = nil;
    }
}

extension ObservationViewCardCollectionViewController: ObservationPushDelegate {
    func didPush(observation: Observation, success: Bool, error: Error?) {
        if (observation.objectID != self.observation?.objectID) {
            return;
        }
        headerCard?.populate(observation: observation, ignoreGeometry: true);
        syncStatusView.updateObservationStatus();
        if let scheme = self.scheme {
            syncStatusView.applyTheme(withScheme: scheme);
        }
        view.setNeedsUpdateConstraints();
    }
}

extension ObservationViewCardCollectionViewController: ObservationActionsDelegate {
    
    func moreActionsTapped(_ observation: Observation) {
        let actionsSheet: ObservationActionsSheetController = ObservationActionsSheetController(observation: observation, delegate: self);
        actionsSheet.applyTheme(withContainerScheme: scheme);
        bottomSheet = MDCBottomSheetController(contentViewController: actionsSheet);
        self.navigationController?.present(bottomSheet!, animated: true, completion: nil);
    }
    
    func showFavorites(_ observation: Observation) {
        var userIds: [String] = [];
        if let favorites = observation.favorites {
            for favorite in favorites {
                if let userId = favorite.userId {
                    userIds.append(userId)
                }
            }
        }
        if (userIds.count != 0) {
            let locationViewController = LocationsTableViewController(userIds: userIds, actionsDelegate: nil, scheme: scheme);
            locationViewController.title = "Favorited By";
            self.navigationController?.pushViewController(locationViewController, animated: true);
        }
    }
    
    func favoriteObservation(_ observation: Observation, completion: ((Observation?) -> Void)?) {
        observation.toggleFavorite() { success, error in
            observation.managedObjectContext?.refresh(observation, mergeChanges: false);
            self.headerCard?.populate(observation: observation);
        }
    }
    
    func copyLocation(_ locationString: String) {
        UIPasteboard.general.string = locationString;
        MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Location copied to clipboard"))
    }
    
    
    func getDirectionsToObservation(_ observation: Observation, sourceView: UIView? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let notification = DirectionsToItemNotification(observation: observation, user: nil, feedItem: nil, sourceView: sourceView)
            NotificationCenter.default.post(name: .DirectionsToItem, object: notification)
        }
    }
    
    func makeImportant(_ observation: Observation, reason: String) {
        observation.flagImportant(description: reason) { success, error in
            // update the view
            observation.managedObjectContext?.refresh(observation, mergeChanges: true);
            self.headerCard?.populate(observation: observation);
        }
    }
    
    func removeImportant(_ observation: Observation) {
        observation.removeImportant() { success, error in
            // update the view
            observation.managedObjectContext?.refresh(observation, mergeChanges: false);
            self.headerCard?.populate(observation: observation);
        }
    }
    
    func editObservation(_ observation: Observation) {
        bottomSheet?.dismiss(animated: true, completion: nil);
        startObservationEditCoordinator()
    }
    
    func reorderForms(_ observation: Observation) {
        bottomSheet?.dismiss(animated: true, completion: nil);
        observationEditCoordinator = ObservationEditCoordinator(rootViewController: self.navigationController, delegate: self, observation: self.observation!);
        observationEditCoordinator?.applyTheme(withContainerScheme: self.scheme);
        observationEditCoordinator?.startFormReorder();
    }
    
    func deleteObservation(_ observation: Observation) {
        bottomSheet?.dismiss(animated: true, completion: nil);
        ObservationActionHandler.deleteObservation(observation: observation, viewController: self) { (success, error) in
            self.navigationController?.popViewController(animated: true);
        }
    }
    
    func cancelAction() {
        bottomSheet?.dismiss(animated: true, completion: nil);
    }
    
    func viewUser(_ user: User) {
        bottomSheet?.dismiss(animated: true, completion: nil);
        let uvc = UserViewController(user: user, scheme: self.scheme!);
        self.navigationController?.pushViewController(uvc, animated: true);
    }
}

extension ObservationViewCardCollectionViewController: ObservationEditDelegate {
    func editCancel(_ coordinator: NSObject) {
        observationEditCoordinator = nil;
    }
    
    func editComplete(_ observation: Observation, coordinator: NSObject) {
        observationEditCoordinator = nil;
        guard let observation = self.observation else {
            return;
        }
        self.observation!.managedObjectContext?.refresh(observation, mergeChanges: false);
        // reload the observation
        setupObservation();
    }
}
