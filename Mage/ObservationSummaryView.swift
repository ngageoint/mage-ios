//
//  ObservationSummaryView.swift
//  MAGE
//
//  Created by Daniel Barela on 1/21/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Persistence

class ObservationSummaryView: CommonSummaryView<Observation, ObservationActionsDelegate> {
    
    private weak var observation: Observation?;
    private var didSetUpConstraints = false;
    private var timeText: String = ""
    private var fetchedResultsController: NSFetchedResultsController<User>?
    
    private let exclamation = UIImageView(image: UIImage(systemName: "exclamationmark", withConfiguration: UIImage.SymbolConfiguration(weight:.semibold)));
    
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
    
    private let sync = UIImageView(image: UIImage(systemName: "arrow.triangle.2.circlepath"));
    
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
            
            exclamation.contentMode = .scaleAspectFit
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
        timeText = "";
        if let itemDate: NSDate = observation.timestamp as NSDate? {
            timeText = itemDate.formattedDisplay().uppercased().replacingOccurrences(of: " ", with: "\u{00a0}") ;
        }
        timestamp.text = "\(timeText)";
        if let name = observation.user?.name {
            timestamp.text = "\(name.uppercased()) \u{2022} \(timeText)";
            fetchedResultsController = nil
        } else if let remoteId = observation.user?.remoteId {
            let request = User.fetchRequest()
            request.predicate = NSPredicate(
                format: "remoteId == %@",
                remoteId
            )
            request.sortDescriptors = [NSSortDescriptor(key: "remoteId", ascending: true)]
            fetchedResultsController = NSFetchedResultsController(
                fetchRequest: request,
                managedObjectContext: PersistenceContainer.shared
                    .get().viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            fetchedResultsController?.delegate = self
            try? fetchedResultsController?.performFetch()
            if let user = fetchedResultsController?.fetchedObjects?.first {
                handleUser(userName: user.name)
            }
        }
        
        if (observation.error != nil) {
            self.syncBadge.isHidden = observation.hasValidationError;
            self.errorBadge.isHidden = !observation.hasValidationError;
        } else {
            self.syncBadge.isHidden = true;
            self.errorBadge.isHidden = true;
        }
    }
    
    func handleUser(userName: String?) {
        if let userName {
            timestamp.text = "\(userName.uppercased()) \u{2022} \(timeText)";
            fetchedResultsController?.delegate = nil
            fetchedResultsController = nil
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

extension ObservationSummaryView: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if let user = anObject as? User {
            handleUser(userName: user.name)
        }
    }
}

