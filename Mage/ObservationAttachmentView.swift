//
//  ObservationAttachmentView.swift
//  MAGE
//
//  Created by Daniel Barela on 12/17/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCTextField;

class ObservationAttachmentView : UIView {
    internal var field: [String: Any]!;
    private var attachments: Set<Attachment>?;
    private var attachmentSelectionDelegate: AttachmentSelectionDelegate?;
    
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

    private lazy var wrapperStack: UIStackView = {
        let stackView = UIStackView(forAutoLayout: ());
        stackView.alignment = .fill;
        stackView.distribution = .fill;
        stackView.axis = .vertical;
        return stackView;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    init(field: [String: Any], value: Set<Attachment>? = nil, attachmentSelectionDelegate: AttachmentSelectionDelegate? = nil) {
        super.init(frame: .zero);
        self.configureForAutoLayout();
        self.field = field;
        self.attachmentSelectionDelegate = attachmentSelectionDelegate;
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
        
        wrapperStack.addArrangedSubview(fieldNameSpacerView);
        wrapperStack.addArrangedSubview(attachmentHolderView);
        
        fieldNameLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16));
        
        if (field[FieldKey.title.key] == nil) {
            fieldNameSpacerView.isHidden = true;
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
    
    func isEmpty() -> Bool {
        return self.attachments == nil || self.attachments?.count == 0;
    }
    
    func setValue(_ value: Any) {
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
}
