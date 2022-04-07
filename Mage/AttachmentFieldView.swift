//
//  AttachmentFieldView.swift
//  MAGE
//
//  Created by Daniel Barela on 10/24/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCButton;
import UIKit

@objc protocol AttachmentCreationDelegate {
    @objc func addVoiceAttachment();
    @objc func addVideoAttachment();
    @objc func addCameraAttachment();
    @objc func addGalleryAttachment();
}

class AttachmentFieldView : BaseFieldView {
    private var attachments: [Attachment]?;
    private weak var attachmentSelectionDelegate: AttachmentSelectionDelegate?;
    private weak var attachmentCreationCoordinator: AttachmentCreationCoordinator?;
    private var heightConstraint: NSLayoutConstraint?;
    
    private var min: NSNumber?
    private var max: NSNumber?
    private var unsentAttachments: [[String: AnyHashable]] = []
    
    lazy var attachmentCollectionDataStore: AttachmentCollectionDataStore = {
        let ads: AttachmentCollectionDataStore = self.editMode ? AttachmentCollectionDataStore(buttonImage: "trash.fill", useErrorColor: true) : AttachmentCollectionDataStore();
        ads.attachments = attachments;
        ads.attachmentSelectionDelegate = self;
        return ads;
    }();
    
    lazy var attachmentCollectionView: UICollectionView = {
        let layout: SplitLayout = SplitLayout();
        layout.itemSpacing = 5;
        layout.rowSpacing = 5;
        
        var cv: UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout);
        cv.configureForAutoLayout();
        cv.register(AttachmentCell.self, forCellWithReuseIdentifier: "AttachmentCell");
        cv.delegate = attachmentCollectionDataStore;
        cv.dataSource = attachmentCollectionDataStore;
        cv.accessibilityLabel = "Attachment Collection";
        cv.accessibilityIdentifier = "Attachment Collection";
        attachmentCollectionDataStore.attachmentCollection = cv;
        return cv;
    }();
    
    lazy var attachmentHolderView: UIView = {
        let holder = UIView(forAutoLayout: ());
        holder.addSubview(attachmentCollectionEmptyView)
        holder.addSubview(attachmentCollectionView);
        return holder;
    }()
    
    lazy var errorLabelSpacerView: UIView = {
        let errorLabelSpacerView = UIView(forAutoLayout: ());
        errorLabelSpacerView.addSubview(errorLabel);
        errorLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 4, left: 16, bottom: 0, right: 16));
        return errorLabelSpacerView;
    }()
    
    lazy var errorLabel: UILabel = {
        let label = UILabel(forAutoLayout: ());
        label.text = getErrorMessage();
        return label;
    }()
    
    private let emptyDoc = UIImageView(image: UIImage(systemName: "doc.fill"))
    lazy var noAttachmentsLabel: UILabel = {
        let label = UILabel(forAutoLayout: ());
        label.text = "No Attachments"
        label.textAlignment = .center
        return label;
    }()
    
    private lazy var attachmentCollectionEmptyView: UIView = {
        let attachmentCollectionEmptyView = UIView.newAutoLayout()
        attachmentCollectionEmptyView.addSubview(emptyDoc)
        attachmentCollectionEmptyView.addSubview(noAttachmentsLabel)
        emptyDoc.contentMode = .scaleAspectFit
        emptyDoc.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 36, left: 8, bottom: 24, right: 8), excludingEdge: .bottom)
        noAttachmentsLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 8, bottom: 36, right: 8), excludingEdge: .top)
        noAttachmentsLabel.autoPinEdge(.top, to: .bottom, of: emptyDoc, withOffset: 16)
        return attachmentCollectionEmptyView
    }()
    
    private lazy var divider: UIView = {
        let divider = UIView(forAutoLayout: ());
        divider.autoSetDimension(.height, toSize: 1);
        return divider;
    }()
    
    private lazy var actionsHolderView: UIStackView = {
        let stackView = UIStackView(forAutoLayout: ());
        stackView.alignment = .center
        stackView.distribution = .fill;
        stackView.axis = .horizontal;
        stackView.spacing = 16;
        let fillerView = UIView();
        fillerView.setContentHuggingPriority(.defaultHigh, for: .horizontal);
        stackView.addArrangedSubview(fillerView);
        return stackView;
    }()
    
    private lazy var audioButton: MDCButton = {
        let button = MDCButton();
        button.accessibilityLabel = (field[FieldKey.name.key] as? String ?? "") + " Audio";
        button.setImage(UIImage(named: "voice")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
        button.addTarget(self, action: #selector(addAudioAttachment), for: .touchUpInside);
        button.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        button.inkMaxRippleRadius = 30;
        button.inkStyle = .unbounded;
        return button;
    }()
    
    private lazy var cameraButton: MDCButton = {
        let button = MDCButton();
        button.accessibilityLabel = (field[FieldKey.name.key] as? String ?? "") + " Camera";
        button.setImage(UIImage(named: "camera")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
        button.addTarget(self, action: #selector(addCameraAttachment), for: .touchUpInside);
        button.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        button.inkMaxRippleRadius = 30;
        button.inkStyle = .unbounded;
        return button;
    }()
    
    private lazy var galleryButton: MDCButton = {
        let button = MDCButton();
        button.accessibilityLabel = (field[FieldKey.name.key] as? String ?? "") + " Gallery";
        button.setImage(UIImage(named: "gallery")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
        button.addTarget(self, action: #selector(addGalleryAttachment), for: .touchUpInside);
        button.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        button.inkMaxRippleRadius = 30;
        button.inkStyle = .unbounded;
        return button;
    }()
    
    private lazy var videoButton: MDCButton = {
        let button = MDCButton();
        button.accessibilityLabel = (field[FieldKey.name.key] as? String ?? "") + " Video";
        button.setImage(UIImage(named: "video")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
        button.addTarget(self, action: #selector(addVideoAttachment), for: .touchUpInside);
        button.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        button.inkMaxRippleRadius = 30;
        button.inkStyle = .unbounded;
        return button;
    }()
    
    private lazy var fileButton: MDCButton = {
        let button = MDCButton();
        button.accessibilityLabel = (field[FieldKey.name.key] as? String ?? "") + " File";
        button.setImage(UIImage(named: "paperclip_thumbnail")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
        button.addTarget(self, action: #selector(addFileAttachment), for: .touchUpInside);
        button.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        button.inkMaxRippleRadius = 30;
        button.inkStyle = .unbounded;
        return button;
    }()
    
    override func applyTheme(withScheme scheme: MDCContainerScheming?) {
        guard let scheme = scheme else {
            return
        }

        super.applyTheme(withScheme: scheme);
        audioButton.applyTextTheme(withScheme: scheme);
        audioButton.setImageTintColor(scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6), for: .normal);
        videoButton.applyTextTheme(withScheme: scheme);
        videoButton.setImageTintColor(scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6), for: .normal);
        galleryButton.applyTextTheme(withScheme: scheme);
        galleryButton.setImageTintColor(scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6), for: .normal);
        cameraButton.applyTextTheme(withScheme: scheme);
        cameraButton.setImageTintColor(scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6), for: .normal);
        fileButton.applyTextTheme(withScheme: scheme);
        fileButton.setImageTintColor(scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6), for: .normal);
        errorLabel.font = scheme.typographyScheme.caption;
        errorLabel.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6)
        errorLabelSpacerView.backgroundColor = scheme.colorScheme.surfaceColor
        if (editMode) {
            self.backgroundColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.12);
            attachmentCollectionView.backgroundColor = .clear
            attachmentHolderView.backgroundColor = .clear
        }
        attachmentCollectionDataStore.applyTheme(withContainerScheme: scheme);
        emptyDoc.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6)
        attachmentCollectionEmptyView.backgroundColor = .clear
        divider.backgroundColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.12)
        noAttachmentsLabel.font = scheme.typographyScheme.headline5
        noAttachmentsLabel.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, value: [Attachment]? = nil, attachmentSelectionDelegate: AttachmentSelectionDelegate? = nil, attachmentCreationCoordinator: AttachmentCreationCoordinator? = nil) {
        super.init(field: field, delegate: delegate, value: value, editMode: editMode);
        
        self.min = field[FieldKey.min.key] as? NSNumber;
        self.max = field[FieldKey.max.key] as? NSNumber;
        
        self.attachmentSelectionDelegate = attachmentSelectionDelegate;
        self.attachmentCreationCoordinator = attachmentCreationCoordinator;
        self.attachmentCreationCoordinator?.delegate = self;
        buildView();
        
        setValue(value);
    }
    
    func buildView() {
        if (field[FieldKey.title.key] != nil) {
            if (editMode) {
                viewStack.addArrangedSubview(fieldNameSpacerView);
                viewStack.setCustomSpacing(0, after: fieldNameSpacerView);
            } else {
                viewStack.addArrangedSubview(fieldNameLabel);
            }
        }
        
        viewStack.addArrangedSubview(attachmentHolderView);
        viewStack.setCustomSpacing(0, after: attachmentHolderView);
        
        if (editMode) {
            viewStack.addArrangedSubview(divider)
            viewStack.setCustomSpacing(0, after: divider);
            viewStack.addArrangedSubview(actionsHolderView);
            viewStack.setCustomSpacing(0, after: actionsHolderView);
            viewStack.addArrangedSubview(errorLabelSpacerView);
            viewStack.setCustomSpacing(0, after: errorLabelSpacerView);
            if let allowedAttachmentTypes: [String] = field[FieldKey.allowedAttachmentTypes.key] as? [String], !allowedAttachmentTypes.isEmpty {
                if (allowedAttachmentTypes.contains("audio")) {
                    actionsHolderView.addArrangedSubview(audioButton);
                }
                if (allowedAttachmentTypes.contains("image")) {
                    actionsHolderView.addArrangedSubview(cameraButton);
                    actionsHolderView.addArrangedSubview(galleryButton);
                }
                if (allowedAttachmentTypes.contains("video")) {
                    actionsHolderView.addArrangedSubview(videoButton);
                }
            } else {
                actionsHolderView.addArrangedSubview(audioButton);
                actionsHolderView.addArrangedSubview(cameraButton);
                actionsHolderView.addArrangedSubview(galleryButton);
                actionsHolderView.addArrangedSubview(videoButton);
                actionsHolderView.addArrangedSubview(fileButton)
            }
            // give the last button room to breath
            let endSpace = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 40))
            endSpace.autoSetDimensions(to: CGSize(width: 0, height: 40))
            actionsHolderView.addArrangedSubview(endSpace)
        }
        
        layer.cornerRadius = 4
        clipsToBounds = true
    }
    
    func setAttachmentHolderHeight() {
        var attachmentHolderHeight: CGFloat = 200.0;
        var attachmentCount = attachments?.filter { attachment in
            return !attachment.markedForDeletion
        }.count ?? 0;
        attachmentCount = attachmentCount + unsentAttachments.count;
        if (attachmentCount != 0) {
            attachmentHolderHeight = ceil(CGFloat(Double(attachmentCount) / 2.0)) * attachmentHolderHeight
        }
        if (heightConstraint != nil) {
            heightConstraint?.constant = attachmentHolderHeight;
        } else {
            heightConstraint = attachmentHolderView.autoSetDimension(.height, toSize: attachmentHolderHeight);
        }
    }
    
    override func isEmpty() -> Bool {
        return self.attachmentCollectionView.numberOfItems(inSection: 0) == 0;
    }
    
    override func isValid(enforceRequired: Bool = false) -> Bool {
        return super.isValid(enforceRequired: enforceRequired) && isValidAttachmentCollection()
    }
    
    func isValidAttachmentCollection() -> Bool {
        let attachmentCount = self.attachmentCollectionView.numberOfItems(inSection: 0)
        if let min = min, let max = max {
            if attachmentCount > max.intValue || attachmentCount < min.intValue {
                return false
            }
        } else if let min = self.min {
            if attachmentCount < min.intValue {
                return false
            }
        } else if let max = max {
            if attachmentCount > max.intValue {
                return false
            }
        } else if (field[FieldKey.required.key] as? Bool) == true {
            if attachmentCount == 0 {
                return false
            }
        }
        return true
    }
    
    override func setValue(_ value: Any?) {
        setValue(value as? [Attachment]);
    }
    
    func setValue(_ value: [Attachment]? = nil) {
        self.attachments = value;
        setCollectionData(attachments: self.attachments);
    }
    
    func setValue(set: Set<Attachment>? = nil) {
        setValue(Array(set ?? Set()))
    }
    
    func addAttachment(_ attachment: Attachment) {
        var attachments = self.attachments ?? [];
        attachments.append(attachment);
        self.attachments = attachments
        setCollectionData(attachments: attachments);
    }
    
    func removeAttachment(_ attachment: Attachment) {
        if var attachments = self.attachments, let index = attachments.firstIndex(of: attachment) {
            attachments.remove(at: index)
            self.attachments = attachments
            setCollectionData(attachments: attachments);
        }
    }
    
    func setCollectionData(attachments: [Attachment]?) {
        attachmentCollectionDataStore.attachments = attachments;
        attachmentCollectionView.reloadData();
        setNeedsUpdateConstraints();
    }
    
    func setUnsentAttachments(attachments: [[String: AnyHashable]]) {
        unsentAttachments = attachments
        attachmentCollectionDataStore.unsentAttachments = unsentAttachments;
        attachmentCollectionView.reloadData();
        setNeedsUpdateConstraints();
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            attachmentCollectionView.autoPinEdgesToSuperviewEdges();
            attachmentCollectionEmptyView.autoPinEdgesToSuperviewEdges()

            if (editMode) {
                fieldNameSpacerView.autoSetDimension(.height, toSize: 32);
                actionsHolderView.autoSetDimension(.height, toSize: 40);
                audioButton.autoSetDimensions(to: CGSize(width: 40, height: 40));
                cameraButton.autoSetDimensions(to: CGSize(width: 40, height: 40));
                videoButton.autoSetDimensions(to: CGSize(width: 40, height: 40));
                galleryButton.autoSetDimensions(to: CGSize(width: 40, height: 40));
                fileButton.autoSetDimensions(to: CGSize(width: 40, height: 40))
            }
        }
        setAttachmentHolderHeight();

        super.updateConstraints();
    }
    
    override func getErrorMessage() -> String {
        var error: String = ""
        if let min = min, let max = max {
            error = "Must have between \(min) and \(max) attachments";
        } else if let min = self.min {
            error = "Must have at least \(min) attachments";
        } else if let max = max {
            error = "Must have less than \(max) attachments";
        } else if (field[FieldKey.required.key] as? Bool) == true {
            error = "At least one attachment must be added"
        }
        return error
    }

    override func setValid(_ valid: Bool) {
        errorLabel.text = getErrorMessage()
        if let scheme = scheme {
            if (valid) {
                applyTheme(withScheme: scheme);
            } else {
                fieldNameLabel.textColor = scheme.colorScheme.errorColor;
                errorLabel.textColor = scheme.colorScheme.errorColor
            }
        }
    }
    
    @objc func addCameraAttachment() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            attachmentCreationCoordinator?.addCameraAttachment();
        }
    }
    
    @objc func addGalleryAttachment() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            attachmentCreationCoordinator?.addGalleryAttachment();
        }
    }
    
    @objc func addVideoAttachment() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            attachmentCreationCoordinator?.addVideoAttachment();
        }
    }
    
    @objc func addAudioAttachment() {
        // let the button press be shown before moving
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            attachmentCreationCoordinator?.addVoiceAttachment();
        }
    }
    
    @objc func addFileAttachment() {
        // let the button press be shown before moving
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            attachmentCreationCoordinator?.addFileAttachment();
        }
    }
}

extension AttachmentFieldView : AttachmentCreationCoordinatorDelegate {
    func attachmentCreated(attachment: Attachment) {
        self.addAttachment(attachment);
        delegate?.fieldValueChanged(field, value: [attachment] as Set<Attachment>);
    }
    
    func attachmentCreated(fieldValue: [String : AnyHashable]) {
        unsentAttachments.append(fieldValue);
        attachmentCollectionDataStore.unsentAttachments = unsentAttachments;
        attachmentCollectionView.reloadData();
        setNeedsUpdateConstraints();
        delegate?.fieldValueChanged(field, value: unsentAttachments);
    }
    
    func attachmentCreationCancelled() {
        print("Cancelled")
    }
}

extension AttachmentFieldView : AttachmentSelectionDelegate {
    func selectedAttachment(_ attachment: Attachment!) {
        attachmentSelectionDelegate?.selectedAttachment(attachment);
    }
    
    func selectedUnsentAttachment(_ unsentAttachment: [AnyHashable : Any]!) {
        attachmentSelectionDelegate?.selectedUnsentAttachment(unsentAttachment);
    }
    
    func selectedNotCachedAttachment(_ attachment: Attachment!, completionHandler handler: ((Bool) -> Void)!) {
        attachmentSelectionDelegate?.selectedNotCachedAttachment(attachment, completionHandler: handler);
    }
    
    func attachmentFabTapped(_ attachment: Attachment!, completionHandler handler: ((Bool) -> Void)!) {
        attachmentSelectionDelegate?.attachmentFabTapped?(attachment, completionHandler: { [self] deleted in
            attachmentCollectionView.reloadData();
            setNeedsUpdateConstraints();
            handler(deleted);
        });
    }
    
    func attachmentFabTappedField(_ field: [AnyHashable : Any]!, completionHandler handler: ((Bool) -> Void)!) {
        var deletedField = field as! [String : AnyHashable];
        guard let index = unsentAttachments.firstIndex (where: { $0["name"] == deletedField["name"] }) else {
            return;
        }
        
        attachmentSelectionDelegate?.attachmentFabTappedField?(field, completionHandler: { [self] deleted in
            deletedField["markedForDeletion"] = deleted;
            unsentAttachments.replaceSubrange(index...index, with: [deletedField])
            attachmentCollectionDataStore.unsentAttachments = unsentAttachments;
            attachmentCollectionView.reloadData();
            setNeedsUpdateConstraints();
            delegate?.fieldValueChanged(self.field, value: unsentAttachments.filter {
                if let marked = $0["markedForDeletion"] {
                    return !(marked as! Bool);
                }
                return true;
            });
            handler(deleted);
        })
    }
}
