//
//  EventContentView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/10/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIKit

struct EventScheme {
    var event: Event?
    var scheme: AppContainerScheming?
}

// content view's view model, also generates the content view instance for the cell
struct EventContentConfiguration: UIContentConfiguration, Hashable {
    var eventName: String?
    var offlineCount: Int?
    var eventDescription: String?
    var eventNameColor: UIColor?
    var eventDescriptionColor: UIColor?
    var eventNameFont: UIFont?
    var eventDescriptionFont: UIFont?
    
    func makeContentView() -> UIView & UIContentView {
        return EventContentView(configuration: self)
    }
    
    func updated(for state: UIConfigurationState) -> EventContentConfiguration {
        return self
    }

}

// Defines the layout and appeareance of the custom cell and shows the data
// based on the configuration
class EventContentView: UIView, UIContentView {
    var currentConfiguration: EventContentConfiguration!
    
    let nameLabel = UILabel.newAutoLayout()
    let descriptionLabel = UILabel.newAutoLayout()
    let numberBadge = NumberBadge(number: 0, showsZero: false)
    
    var configuration: UIContentConfiguration {
        get {
            return currentConfiguration
        }
        set {
            guard let newConfiguration = newValue as? EventContentConfiguration else {
                return
            }
            
            apply(configuration: newConfiguration)
        }
    }
    
    init(configuration: EventContentConfiguration) {
        super.init(frame: .zero)
        
        // Create content views
        setupViews()
        
        // apply the configuration to the view
        apply(configuration: configuration)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        let paddingView = UIView.newAutoLayout()
        addSubview(paddingView)
        paddingView.addSubview(nameLabel)
        paddingView.addSubview(descriptionLabel)
        paddingView.addSubview(numberBadge)
        paddingView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16))
        nameLabel.autoPinEdge(toSuperviewEdge: .top)
        nameLabel.autoPinEdge(toSuperviewEdge: .left)
        descriptionLabel.autoPinEdge(.top, to: .bottom, of: nameLabel)
        descriptionLabel.autoPinEdge(toSuperviewEdge: .bottom)
        descriptionLabel.autoPinEdge(toSuperviewEdge: .left)
        numberBadge.autoPinEdge(toSuperviewEdge: .right)
        numberBadge.autoAlignAxis(toSuperviewAxis: .horizontal)
        numberBadge.autoPinEdge(.left, to: .right, of: nameLabel, withOffset: 16)
        descriptionLabel.autoMatch(.width, to: .width, of: nameLabel)
    }
    
    func apply(configuration: EventContentConfiguration) {
        guard currentConfiguration != configuration else {
            return
        }
        
        currentConfiguration = configuration
        
        nameLabel.text = configuration.eventName
        nameLabel.textColor = configuration.eventNameColor
        nameLabel.font = configuration.eventNameFont
        descriptionLabel.text = configuration.eventDescription
        descriptionLabel.textColor = configuration.eventDescriptionColor
        descriptionLabel.font = configuration.eventDescriptionFont
        numberBadge.number = configuration.offlineCount ?? 0
    }
}

// 1 job: generate a properly configured content configuration object based on the state (selected, highlighted, disabled, etc.) of the cell and then assign the configuration to itself.
class EventCell: UICollectionViewListCell {
    var event: Event?
    var scheme: AppContainerScheming?
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        var newConfiguration = EventContentConfiguration().updated(for: state)
        
        newConfiguration.eventName = event?.name
        newConfiguration.eventDescription = event?.eventDescription
        let offline = event?.unsyncedObservations
        newConfiguration.offlineCount = offline?.count
        
        newConfiguration.eventNameColor = scheme?.colorScheme.onSurfaceColor
        newConfiguration.eventDescriptionColor = scheme?.colorScheme.onSurfaceColor?.withAlphaComponent(0.6)
        newConfiguration.eventNameFont = scheme?.typographyScheme.subtitle1Font
        newConfiguration.eventDescriptionFont = scheme?.typographyScheme.subtitle2Font
        contentConfiguration = newConfiguration
    }
}
