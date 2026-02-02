//
//  ObservationTableHeaderView.swift
//  MAGE
//
//  Created by Daniel Benner on 1/28/26.
//  Copyright © 2026 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

final class ObservationTableHeaderViewSwift: UIView {
    private let label = UILabel()

    init(name: String?, scheme: MDCContainerScheming) {
        super.init(frame: .zero)

        preservesSuperviewLayoutMargins = true

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = scheme.typographyScheme.overline
        label.text = (name ?? "").uppercased()
        label.textColor = scheme.colorScheme.onBackgroundColor

        backgroundColor = scheme.colorScheme.backgroundColor

        addSubview(label)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 45),

            // Respect layout margins + safe area automatically
            label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
