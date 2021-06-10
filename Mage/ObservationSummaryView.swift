//
//  ObservationSummaryView.swift
//  MAGE
//
//  Created by Daniel Barela on 1/21/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class ObservationSummaryView: UIView {
    
    private weak var observation: Observation?;
    private var imageOverride: UIImage?;
    private var didSetUpConstraints = false;
    
    private lazy var stack: UIStackView = {
        let stack = UIStackView(forAutoLayout: ());
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0;
        stack.distribution = .fillProportionally
        stack.translatesAutoresizingMaskIntoConstraints = false;
        stack.isUserInteractionEnabled = false;
        return stack;
    }()
    
    private let exclamation = UIImageView(image: UIImage(named: "exclamation"));
    
    private lazy var errorShapeLayer: CAShapeLayer = {
        let path = CGMutablePath()
        let heightWidth = 25
        
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x:0, y: heightWidth))
        path.addLine(to: CGPoint(x:heightWidth, y:0))
        path.addLine(to: CGPoint(x:0, y:0))
        
        let shape = CAShapeLayer()
        shape.path = path
        
        return shape;
    }()
    
    private lazy var errorBadge: UIView = {
        let errorBadge = UIView(forAutoLayout: ());
        let heightWidth = 25
        
        errorBadge.layer.insertSublayer(errorShapeLayer, at: 0)
        errorBadge.addSubview(exclamation);
        
        return errorBadge;
    }()
    
    private lazy var syncShapeLayer: CAShapeLayer = {
        let path = CGMutablePath()
        let heightWidth = 25

        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x:0, y: heightWidth))
        path.addLine(to: CGPoint(x:heightWidth, y:0))
        path.addLine(to: CGPoint(x:0, y:0))
        
        let shape = CAShapeLayer()
        shape.path = path
        
        return shape;
    }()
    
    private let sync = UIImageView(image: UIImage(named: "sync"));
    
    private lazy var syncBadge: UIView = {
        let syncBadge = UIView(forAutoLayout: ());
        let heightWidth = 25

        syncBadge.layer.insertSublayer(syncShapeLayer, at: 0)
        syncBadge.addSubview(sync);
        
        return syncBadge;
    }()
    
    private lazy var timestamp: UILabel = {
        let timestamp = UILabel(forAutoLayout: ());
        timestamp.numberOfLines = 0;
        timestamp.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return timestamp;
    }()
    
    private lazy var itemImage: UIImageView = {
        let itemImage = UIImageView(forAutoLayout: ());
        itemImage.contentMode = .scaleAspectFit;
        return itemImage;
    }()
    
    private lazy var primaryField: UILabel = {
        let primaryField = UILabel(forAutoLayout: ());
        primaryField.setContentHuggingPriority(.defaultLow, for: .vertical)
        primaryField.numberOfLines = 0;
        return primaryField;
    }()
    
    private lazy var secondaryField: UILabel = {
        let secondaryField = UILabel(forAutoLayout: ());
        secondaryField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        secondaryField.numberOfLines = 0;
        return secondaryField;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    init(imageOverride: UIImage? = nil) {
        super.init(frame: CGRect.zero);
        self.configureForAutoLayout();
        self.imageOverride = imageOverride;
        stack.addArrangedSubview(timestamp);
        stack.setCustomSpacing(12, after: timestamp);
        stack.addArrangedSubview(primaryField);
        stack.addArrangedSubview(secondaryField);
        
        self.addSubview(stack);
        self.addSubview(itemImage);
        self.addSubview(errorBadge);
        self.addSubview(syncBadge);
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            stack.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 0), excludingEdge: .right);
            itemImage.autoSetDimensions(to: CGSize(width: 48, height: 48));
            itemImage.autoPinEdge(.left, to: .right, of: stack, withOffset: 8);
            itemImage.autoPinEdge(toSuperviewEdge: .right, withInset: 16);
            itemImage.autoPinEdge(toSuperviewEdge: .top, withInset: 24);
            itemImage.autoPinEdge(toSuperviewEdge: .bottom, withInset: 16, relation: .greaterThanOrEqual);
            
            errorBadge.autoSetDimensions(to: CGSize(width: 25, height: 25));
            errorBadge.autoPinEdge(toSuperviewEdge: .top);
            errorBadge.autoPinEdge(toSuperviewEdge: .left);
            
            exclamation.autoSetDimensions(to: CGSize(width: 14, height: 14));
            exclamation.autoPinEdge(toSuperviewEdge: .top, withInset: 1);
            exclamation.autoPinEdge(toSuperviewEdge: .left);
            
            syncBadge.autoSetDimensions(to: CGSize(width: 25, height: 25));
            syncBadge.autoPinEdge(toSuperviewEdge: .top);
            syncBadge.autoPinEdge(toSuperviewEdge: .left);
            
            sync.autoSetDimensions(to: CGSize(width: 14, height: 14));
            sync.autoPinEdge(toSuperviewEdge: .top, withInset: 1);
            sync.autoPinEdge(toSuperviewEdge: .left);
                        
            self.autoSetDimension(.height, toSize: 90, relation: .greaterThanOrEqual)
            didSetUpConstraints = true;
        }
        super.updateConstraints();
    }
    
    func populate(observation: Observation) {
        self.observation = observation;
        
        if (self.imageOverride != nil) {
            itemImage.image = self.imageOverride;
        } else {
            itemImage.image = ObservationImage.image(for: self.observation!);
        }

        primaryField.text = observation.primaryFeedFieldText();
        secondaryField.text = observation.secondaryFeedFieldText();
        // we do not want the date to word break so we replace all spaces with a non word breaking spaces
        var timeText = "";
        if let itemDate: NSDate = observation.timestamp as NSDate? {
            timeText = itemDate.formattedDisplayDate(withDateStyle: .medium, andTime: .short).uppercased().replacingOccurrences(of: " ", with: "\u{00a0}") ;
        }
        timestamp.text = "\(observation.user?.name?.uppercased() ?? "") \u{2022} \(timeText)";
        
        if (observation.error != nil) {
            self.syncBadge.isHidden = observation.hasValidationError();
            self.errorBadge.isHidden = !observation.hasValidationError();
        } else {
            self.syncBadge.isHidden = true;
            self.errorBadge.isHidden = true;
        }
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming) {
        timestamp.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        timestamp.font = scheme.typographyScheme.overline;
        timestamp.autoSetDimension(.height, toSize: timestamp.font.pointSize);
        primaryField.textColor = scheme.colorScheme.primaryColor;
        primaryField.font = scheme.typographyScheme.headline6;
        primaryField.autoSetDimension(.height, toSize: primaryField.font.pointSize);
        secondaryField.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        secondaryField.font = scheme.typographyScheme.subtitle2;
        secondaryField.autoSetDimension(.height, toSize: secondaryField.font.pointSize);
        errorShapeLayer.fillColor = scheme.colorScheme.errorColor.cgColor
        exclamation.tintColor = UIColor.white;
        syncShapeLayer.fillColor = scheme.colorScheme.secondaryColor.cgColor;
        sync.tintColor = UIColor.white;
    }
}
