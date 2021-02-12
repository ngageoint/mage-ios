//
//  AttachmentFieldView.swift
//  MAGE
//
//  Created by Daniel Barela on 10/24/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCButton;

@objc protocol AttachmentCreationDelegate {
    @objc func addVoiceAttachment();
    @objc func addVideoAttachment();
    @objc func addCameraAttachment();
    @objc func addGalleryAttachment();
}

class AttachmentFieldView : BaseFieldView {
    private var attachments: Set<Attachment>?;
    private var attachmentSelectionDelegate: AttachmentSelectionDelegate?;
    private var attachmentCreationCoordinator: AttachmentCreationCoordinator?;
    
    lazy var attachmentCollectionDataStore: AttachmentCollectionDataStore = {
        let ads: AttachmentCollectionDataStore = AttachmentCollectionDataStore();
        ads.attachments = attachments;
        ads.attachmentSelectionDelegate = self.attachmentSelectionDelegate;
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
        attachmentCollectionDataStore.attachmentCollection = cv;
        return cv;
    }();
    
    lazy var attachmentHolderView: UIView = {
        let holder = UIView(forAutoLayout: ());
        holder.autoSetDimension(.height, toSize: 100, relation: .greaterThanOrEqual);
        holder.addSubview(attachmentCollectionView);
        attachmentCollectionView.autoPinEdgesToSuperviewEdges();
        return holder;
    }()
    
    lazy var errorLabel: UILabel = {
        let label = UILabel(forAutoLayout: ());
        label.text = "At least one attachment must be added";
        label.isHidden = true;
        return label;
    }()
    
    private lazy var actionsHolderView: UIStackView = {
        let stackView = UIStackView(forAutoLayout: ());
        stackView.alignment = .center
        stackView.distribution = .fill;
        stackView.axis = .horizontal;
        stackView.spacing = 16;
        stackView.autoSetDimension(.height, toSize: 40);
        let fillerView = UIView();
        fillerView.setContentHuggingPriority(.defaultHigh, for: .horizontal);
        stackView.addArrangedSubview(fillerView);
        return stackView;
    }()
    
    private lazy var audioButton: UIButton = {
        let button = UIButton(forAutoLayout: ());
        button.accessibilityLabel = (field[FieldKey.name.key] as? String ?? "") + " Audio";
        button.setImage(UIImage(named: "voice")?.withRenderingMode(.alwaysTemplate), for: .normal);
        button.autoSetDimensions(to: CGSize(width: 24, height: 24));
        button.addTarget(self, action: #selector(addAudioAttachment), for: .touchUpInside);
        return button;
    }()
    
    private lazy var cameraButton: UIButton = {
        let button = UIButton(forAutoLayout: ());
        button.accessibilityLabel = (field[FieldKey.name.key] as? String ?? "") + " Camera";
        button.setImage(UIImage(named: "camera")?.withRenderingMode(.alwaysTemplate), for: .normal);
        button.autoSetDimensions(to: CGSize(width: 24, height: 24));
        button.addTarget(self, action: #selector(addCameraAttachment), for: .touchUpInside);
        return button;
    }()
    
    private lazy var galleryButton: UIButton = {
        let button = UIButton(forAutoLayout: ());
        button.accessibilityLabel = (field[FieldKey.name.key] as? String ?? "") + " Gallery";
        button.setImage(UIImage(named: "gallery")?.withRenderingMode(.alwaysTemplate), for: .normal);
        button.autoSetDimensions(to: CGSize(width: 24, height: 24));
        button.addTarget(self, action: #selector(addGalleryAttachment), for: .touchUpInside);
        return button;
    }()
    
    private lazy var videoButton: UIButton = {
        let button = UIButton(forAutoLayout: ());
        button.accessibilityLabel = (field[FieldKey.name.key] as? String ?? "") + " Video";
        button.setImage(UIImage(named: "video")?.withRenderingMode(.alwaysTemplate), for: .normal);
        button.autoSetDimensions(to: CGSize(width: 24, height: 24));
        button.addTarget(self, action: #selector(addVideoAttachment), for: .touchUpInside);
        return button;
    }()
    
    override func applyTheme(withScheme scheme: MDCContainerScheming) {
        super.applyTheme(withScheme: scheme);
        audioButton.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        videoButton.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        galleryButton.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        cameraButton.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        errorLabel.font = scheme.typographyScheme.caption;
        errorLabel.textColor = scheme.colorScheme.errorColor;
        attachmentHolderView.backgroundColor = scheme.colorScheme.backgroundColor;
        attachmentCollectionView.backgroundColor = scheme.colorScheme.backgroundColor;
        attachmentCollectionDataStore.applyTheme(withContainerScheme: scheme);
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, value: Set<Attachment>? = nil, attachmentSelectionDelegate: AttachmentSelectionDelegate? = nil, attachmentCreationCoordinator: AttachmentCreationCoordinator? = nil) {
        super.init(field: field, delegate: delegate, value: value, editMode: editMode);
        self.attachmentSelectionDelegate = attachmentSelectionDelegate;
        self.attachmentCreationCoordinator = attachmentCreationCoordinator;
        self.attachmentCreationCoordinator?.delegate = self;
        buildView();
        
        setValue(value);
    }
    
    func buildView() {
        if (field[FieldKey.title.key] != nil) {
            viewStack.addArrangedSubview(fieldNameSpacerView);
            viewStack.setCustomSpacing(0, after: fieldNameSpacerView);
        }
        
        viewStack.addArrangedSubview(attachmentHolderView);
        viewStack.setCustomSpacing(0, after: attachmentHolderView);
        
        if (editMode) {
            viewStack.addArrangedSubview(errorLabel);
            viewStack.setCustomSpacing(0, after: errorLabel);
            
            let actionSpacerView = UIView(forAutoLayout: ());
            actionSpacerView.addSubview(actionsHolderView);
            viewStack.addArrangedSubview(actionSpacerView);
            actionsHolderView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16));
            
            actionsHolderView.addArrangedSubview(audioButton);
            actionsHolderView.addArrangedSubview(cameraButton);
            actionsHolderView.addArrangedSubview(galleryButton);
            actionsHolderView.addArrangedSubview(videoButton);
        }
    }
    
    func setAttachmentHolderHeight() {
        var attachmentHolderHeight: CGFloat = 100.0;
        if let attachmentCount = attachments?.count {
            if (attachmentCount != 0) {
                attachmentHolderHeight = ceil(CGFloat(Double(attachmentCount) / 2.0)) * 100.0
            }
        }
        attachmentHolderView.autoSetDimension(.height, toSize: attachmentHolderHeight);
    }
    
    override func isEmpty() -> Bool {
        return self.attachments == nil || self.attachments?.count == 0;
    }
    
    override func setValue(_ value: Any) {
        setValue(value as? Set<Attachment>);
    }
    
    func setValue(_ value: Set<Attachment>? = nil) {
        self.attachments = value;
        setCollectionData(attachments: self.attachments);
    }
    
    func addAttachment(_ attachment: Attachment) {
        var safeAttachments = self.attachments ?? Set(minimumCapacity: 0);
        safeAttachments.insert(attachment);
        self.attachments = safeAttachments
        setCollectionData(attachments: safeAttachments);
    }
    
    func removeAttachment(_ attachment: Attachment) {
        if var safeAttachments = self.attachments {
            safeAttachments.remove(attachment);
            self.attachments = safeAttachments
            setCollectionData(attachments: safeAttachments);
        }
    }
    
    func setCollectionData(attachments: Set<Attachment>?) {
        attachmentCollectionDataStore.attachments = attachments;
        attachmentCollectionView.reloadData();
        setNeedsUpdateConstraints();
    }
    
    override func updateConstraints() {
        setAttachmentHolderHeight();
        super.updateConstraints();
    }

    override func setValid(_ valid: Bool) {
        errorLabel.isHidden = valid;
        if let safeScheme = scheme {
            if (valid) {
                applyTheme(withScheme: safeScheme);
            } else {
                fieldNameLabel.textColor = safeScheme.colorScheme.errorColor;
            }
        }
    }
    
    @objc func addCameraAttachment() {
        attachmentCreationCoordinator?.addCameraAttachment();
    }
    
    @objc func addGalleryAttachment() {
        attachmentCreationCoordinator?.addGalleryAttachment();
    }
    
    @objc func addVideoAttachment() {
        attachmentCreationCoordinator?.addVideoAttachment();
    }
    
    @objc func addAudioAttachment() {
        attachmentCreationCoordinator?.addVoiceAttachment();
    }
}

extension AttachmentFieldView : AttachmentCreationCoordinatorDelegate {
    func attachmentCreated(attachment: Attachment) {
        print("attachment was created \(attachment)")
        self.addAttachment(attachment);
        delegate?.fieldValueChanged(field, value: [attachment] as Set<Attachment>);
    }
    
    func attachmentCreationCancelled() {
        print("Cancelled")
    }
}
