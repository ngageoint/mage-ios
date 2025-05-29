//
//  ObservationImportantView.swift
//  MAGE
//
//  Created by Daniel Barela on 12/16/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout
import SwiftUI
import MAGEStyle

struct ObservationImportantViewSwiftUI: View {
    var important: ObservationImportantModel
    
    var body: some View {
        if important.important {
            HStack(spacing: 8) {
                Image(systemName: "flag.fill")
                    .fontWeight(.semibold)
                    .padding(.leading, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .frame(width: 32, height: 32)
                    .foregroundStyle(Color.onSurfaceColor)
                VStack(alignment: .leading, spacing: 8) {
                    if let userName = important.userName {
                        Text(userName)
                            .overlineText()
                    }
                    if let reason = important.reason, !reason.isEmpty {
                        Text(reason)
                            .secondaryText()
                    }
                }
                .padding([.top, .bottom], 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.importantColor)
        }
    }
}

class ObservationImportantView: UIView {
    weak var observation: Observation?;
    var scheme: MDCContainerScheming?;
    var flaggedByLabel: UILabel = UILabel(forAutoLayout: ());
    
    private lazy var reasonLabel: UILabel = {
        var reasonLabel: UILabel = UILabel(forAutoLayout: ());
        reasonLabel.numberOfLines = 0;
        return reasonLabel;
    }()
    
    private lazy var flagImage: UIImageView = {
        let flag = UIImage(systemName: "flag.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold));
        let flagView = UIImageView(image: flag);
        return flagView;
    }()
    
    func applyTheme(withScheme scheme: MDCContainerScheming?) {
        reasonLabel.textColor = UIColor.black.withAlphaComponent(0.87);
        reasonLabel.font = scheme?.typographyScheme.body2;
        flaggedByLabel.textColor = UIColor.black.withAlphaComponent(0.6);
        flaggedByLabel.font = scheme?.typographyScheme.overline;
        flagImage.tintColor = UIColor.black.withAlphaComponent(0.87);
    }
    
    public convenience init(observation: Observation?, cornerRadius: CGFloat, scheme: MDCContainerScheming? = nil) {
        self.init(frame: CGRect.zero);
        layer.cornerRadius = cornerRadius;
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner];
        self.observation = observation;
        self.scheme = scheme;
        self.configureForAutoLayout();
        layoutView();
        self.backgroundColor = MDCPalette.orange.accent400;
        if let observation = observation {
            populate(observation: observation);
        }
        applyTheme(withScheme: scheme);
    }
    
    func layoutView() {
        self.addSubview(flagImage);
        self.addSubview(flaggedByLabel);
        self.addSubview(reasonLabel);
        reasonLabel.accessibilityLabel = "important reason";
        flagImage.autoPinEdge(toSuperviewEdge: .top, withInset: 8, relation: .greaterThanOrEqual);
        flagImage.autoPinEdge(toSuperviewEdge: .bottom, withInset: 8, relation: .greaterThanOrEqual);
        flagImage.autoPinEdge(toSuperviewEdge: .left, withInset: 16);
        flagImage.autoSetDimensions(to: CGSize(width: 32, height: 32));
        flagImage.autoAlignAxis(toSuperviewAxis: .horizontal);
        flaggedByLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 56, bottom: 0, right: 8), excludingEdge: .bottom);
        reasonLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 56, bottom: 8, right: 8), excludingEdge: .top);
        reasonLabel.autoPinEdge(.top, to: .bottom, of: flaggedByLabel, withOffset: 8);
    }
    
    public func populate(observation: Observation) {
        self.observation = observation;
        let important: ObservationImportant? = observation.observationImportant;
        if let userId = important?.userId {
            @Injected(\.nsManagedObjectContext)
            var context: NSManagedObjectContext?
            let user = try? context?.fetchFirst(User.self, predicate: NSPredicate(format: "remoteId == %@", userId))
            flaggedByLabel.text = "Flagged By \(user?.name ?? "")".uppercased()
        }
        if let reason = important?.reason {
            reasonLabel.text = reason;
        }
        
    }
}
