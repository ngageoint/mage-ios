//
//  ObservationSummaryView.swift
//  MAGE
//
//  Created by Daniel Barela on 1/21/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class ObservationSummaryView: CommonSummaryView<Observation, ObservationActionsDelegate> {
    
    private weak var observation: Observation?;
    private var didSetUpConstraints = false;
    
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
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override init(imageOverride: UIImage? = nil, hideImage: Bool = false) {
        super.init(imageOverride: imageOverride, hideImage: hideImage);
        self.addSubview(errorBadge);
        self.addSubview(syncBadge);
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
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
                        
            didSetUpConstraints = true;
        }
        super.updateConstraints();
    }
    
    func populate(observation: Observation, actionsDelegate: ObservationActionsDelegate? = nil) {
        self.observation = observation;
        
        if (self.imageOverride != nil) {
            itemImage.image = self.imageOverride;
        } else {
            itemImage.image = ObservationImage.image(observation: self.observation!);
        }

        primaryField.text = observation.primaryFeedFieldText;
        secondaryField.text = observation.secondaryFeedFieldText;
        // we do not want the date to word break so we replace all spaces with a non word breaking spaces
        var timeText = "";
        if let itemDate: NSDate = observation.timestamp as NSDate? {
            timeText = itemDate.formattedDisplay().uppercased().replacingOccurrences(of: " ", with: "\u{00a0}") ;
        }
        timestamp.text = "\(observation.user?.name?.uppercased() ?? "") \u{2022} \(timeText)";
        
        if (observation.error != nil) {
            self.syncBadge.isHidden = observation.hasValidationError;
            self.errorBadge.isHidden = !observation.hasValidationError;
        } else {
            self.syncBadge.isHidden = true;
            self.errorBadge.isHidden = true;
        }
    }
    
    override func applyTheme(withScheme scheme: MDCContainerScheming?) {
        super.applyTheme(withScheme: scheme);
        errorShapeLayer.fillColor = scheme?.colorScheme.errorColor.cgColor
        exclamation.tintColor = UIColor.white;
        syncShapeLayer.fillColor = scheme?.colorScheme.secondaryColor.cgColor;
        sync.tintColor = UIColor.white;
    }
}
