//
//  EditAttachmentFieldView.swift
//  MAGE
//
//  Created by Daniel Barela on 10/24/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCTextField;
import MaterialComponents.MDCButton;

@objc protocol AttachmentCreationDelegate {
    @objc func addVoiceAttachment();
    @objc func addVideoAttachment();
    @objc func addCameraAttachment();
    @objc func addGalleryAttachment();
}

class EditAttachmentFieldView : BaseFieldView {
    private var attachments: Set<Attachment>?;
    private var attachmentSelectionDelegate: AttachmentSelectionDelegate?;
    private var attachmentCreationDelegate: AttachmentCreationDelegate?;
    
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
        cv.backgroundColor = .none;
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
        holder.backgroundColor = .systemFill;
        holder.addSubview(attachmentCollectionView);
        attachmentCollectionView.autoPinEdgesToSuperviewEdges();
        return holder;
    }()
    
    private lazy var fieldNameLabel: UILabel = {
        let containerScheme = globalContainerScheme();
        let label = UILabel(forAutoLayout: ());
        label.textColor = .systemGray;
        var font = containerScheme.typographyScheme.body1;
        font = font.withSize(font.pointSize * MDCTextInputControllerBase.floatingPlaceholderScaleDefault);
        label.font = font;
        label.autoSetDimension(.height, toSize: 16);
        
        return label;
    }()
    
    lazy var errorLabel: UILabel = {
        let label = UILabel(forAutoLayout: ());
        label.textColor = globalErrorContainerScheme().colorScheme.primaryColor;
        label.font = globalContainerScheme().typographyScheme.caption;
        label.text = "At least one attachment must be added";
        label.isHidden = true;
        return label;
    }()
    
    private lazy var wrapperStack: UIStackView = {
        let stackView = UIStackView(forAutoLayout: ());
        stackView.alignment = .fill;
        stackView.distribution = .fill;
        stackView.axis = .vertical;
        return stackView;
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
    
    private lazy var cameraButton: UIButton = {
        let button = UIButton(forAutoLayout: ());
        button.accessibilityLabel = (field[FieldKey.name.key] as? String ?? "") + " Camera";
        button.setImage(UIImage(named: "camera")?.withRenderingMode(.alwaysTemplate), for: .normal);
        button.autoSetDimensions(to: CGSize(width: 24, height: 24));
        button.tintColor = .systemGray;
        button.addTarget(self, action: #selector(addCameraAttachment), for: .touchUpInside);
        return button;
    }()
    
    private lazy var galleryButton: UIButton = {
        let button = UIButton(forAutoLayout: ());
        button.accessibilityLabel = (field[FieldKey.name.key] as? String ?? "") + " Gallery";
        button.setImage(UIImage(named: "gallery")?.withRenderingMode(.alwaysTemplate), for: .normal);
        button.autoSetDimensions(to: CGSize(width: 24, height: 24));
        button.tintColor = .systemGray;
        button.addTarget(self, action: #selector(addGalleryAttachment), for: .touchUpInside);
        return button;
    }()
    
    private lazy var videoButton: UIButton = {
        let button = UIButton(forAutoLayout: ());
        button.accessibilityLabel = (field[FieldKey.name.key] as? String ?? "") + " Video";
        button.setImage(UIImage(named: "video")?.withRenderingMode(.alwaysTemplate), for: .normal);
        button.autoSetDimensions(to: CGSize(width: 24, height: 24));
        button.tintColor = .systemGray;
        button.addTarget(self, action: #selector(addVideoAttachment), for: .touchUpInside);
        return button;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    init(field: [String: Any], delegate: ObservationEditListener? = nil, value: Set<Attachment>? = nil, attachmentSelectionDelegate: AttachmentSelectionDelegate? = nil, attachmentCreationDelegate: AttachmentCreationDelegate? = nil) {
        super.init(field: field, delegate: delegate, value: value);
        self.attachmentSelectionDelegate = attachmentSelectionDelegate;
        self.attachmentCreationDelegate = attachmentCreationDelegate;
        buildView();
        
        setValue(value);
        fieldNameLabel.text = (field[FieldKey.title.key] as? String ?? "");
        if ((field[FieldKey.required.key] as? Bool) == true) {
            fieldNameLabel.text = (fieldNameLabel.text ?? "") + " *"
        }
    }
    
    func buildView() {
        self.addSubview(wrapperStack);
        wrapperStack.autoPinEdgesToSuperviewEdges();
        
        let fieldNameSpacerView = UIView(forAutoLayout: ());
        fieldNameSpacerView.addSubview(fieldNameLabel);
        
        let actionSpacerView = UIView(forAutoLayout: ());
        actionSpacerView.addSubview(actionsHolderView);
        
        wrapperStack.addArrangedSubview(fieldNameSpacerView);
        wrapperStack.addArrangedSubview(attachmentHolderView);
        wrapperStack.addArrangedSubview(errorLabel);
        wrapperStack.addArrangedSubview(actionSpacerView);
        
        fieldNameLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16));
        actionsHolderView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16));

        actionsHolderView.addArrangedSubview(cameraButton);
        actionsHolderView.addArrangedSubview(galleryButton);
        actionsHolderView.addArrangedSubview(videoButton);
    }
    
    func setAttachmentHolderHeight() {
        var attachmentHolderHeight: CGFloat = 100.0;
        if let attachmentCount = attachments?.count {
            attachmentHolderHeight = ceil(CGFloat(Double(attachmentCount) / 2.0)) * 100.0
        }
        attachmentHolderView.autoSetDimension(.height, toSize: attachmentHolderHeight);
    }
    
    override func isEmpty() -> Bool {
        return self.attachments == nil || self.attachments?.count == 0;
    }
    
    func setValue(_ value: Set<Attachment>? = nil) {
        self.attachments = value;
        attachmentCollectionDataStore.attachments = self.attachments;
        setNeedsUpdateConstraints();
    }
    
    func addAttachment(_ attachment: Attachment) {
        var safeAttachments = self.attachments ?? Set(minimumCapacity: 0);
        safeAttachments.insert(attachment);
        self.attachments = safeAttachments
        attachmentCollectionDataStore.attachments = safeAttachments;
        
        setNeedsUpdateConstraints();
    }
    
    func removeAttachment(_ attachment: Attachment) {
        if var safeAttachments = self.attachments {
            safeAttachments.remove(attachment);
            self.attachments = safeAttachments
            attachmentCollectionDataStore.attachments = safeAttachments;
            
            setNeedsUpdateConstraints();
        }
    }
    
    override func updateConstraints() {
        setAttachmentHolderHeight();
        super.updateConstraints();
    }

    override func setValid(_ valid: Bool) {
        errorLabel.isHidden = valid;
        if (valid) {
            fieldNameLabel.textColor = .systemGray;
        } else {
            fieldNameLabel.textColor = .systemRed;
        }
        setNeedsUpdateConstraints();
    }
    
    @objc func addCameraAttachment() {
        attachmentCreationDelegate?.addCameraAttachment();
    }
    
    @objc func addGalleryAttachment() {
        attachmentCreationDelegate?.addGalleryAttachment();
    }
    
    @objc func addVideoAttachment() {
        attachmentCreationDelegate?.addVideoAttachment();
    }
}
