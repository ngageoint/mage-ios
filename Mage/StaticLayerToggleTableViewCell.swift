//
//  StaticLayerToggleTableViewCell.swift
//  MAGE
//
//  Created by Paul Solt on 3/5/26.
//  Copyright © 2026 National Geospatial Intelligence Agency. All rights reserved.
//


import Foundation
import UIKit

class StaticLayerToggleTableViewCell: UITableViewCell {
    static let cellIdentifier = "staticLayerToggleCell"

    private let layerSwitch = UISwitch(frame: .zero)
    private var remoteId: NSNumber?
    private var onToggle: ((NSNumber, Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        layerSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        remoteId = nil
        onToggle = nil
        accessoryView = nil
    }

    func configureToggle(
        remoteId: NSNumber?,
        isOn: Bool,
        onTintColor: UIColor,
        onToggle: ((NSNumber, Bool) -> Void)?
    ) {
        self.remoteId = remoteId
        self.onToggle = onToggle

        guard remoteId != nil else {
            accessoryView = nil
            return
        }

        layerSwitch.isOn = isOn
        layerSwitch.onTintColor = onTintColor
        accessoryView = layerSwitch
    }

    @objc private func switchChanged(_ sender: UISwitch) {
        guard let remoteId else { return }
        onToggle?(remoteId, sender.isOn)
    }
}
