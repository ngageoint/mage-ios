//
//  ThemedTextField.swift
//  MAGE
//
//  Created by Brent Danger Michalski on 7/2/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

@objcMembers
@IBDesignable
public class ThemedTextField: UITextField {

    public let floatingLabel = UILabel()
    public let leadingAssistiveLabel = UILabel()
    public let trailingAssistiveLabel = UILabel()
    
    public var scheme: AppContainerScheming? {
        didSet { updateStyle() }
    }

    public var isErrorState: Bool = false {
        didSet { updateStyle() }
    }

    public var isDisabled: Bool = false {
        didSet {
            isEnabled = !isDisabled
            updateStyle()
        }
    }

    private var floatingLabelTopConstraint: NSLayoutConstraint?
    private var originalPlaceholder: String?

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        borderStyle = .none
        backgroundColor = .systemGray6
        layer.cornerRadius = 4
        layer.borderWidth = 1

        clipsToBounds = false

        floatingLabel.translatesAutoresizingMaskIntoConstraints = false
        floatingLabel.font = UIFont.systemFont(ofSize: 12)
        floatingLabel.alpha = 0

        leadingAssistiveLabel.translatesAutoresizingMaskIntoConstraints = false
        leadingAssistiveLabel.font = UIFont.systemFont(ofSize: 12)
        leadingAssistiveLabel.numberOfLines = 0

        trailingAssistiveLabel.translatesAutoresizingMaskIntoConstraints = false
        trailingAssistiveLabel.font = UIFont.systemFont(ofSize: 12)
        trailingAssistiveLabel.numberOfLines = 0

        addSubview(floatingLabel)
        addSubview(leadingAssistiveLabel)
        addSubview(trailingAssistiveLabel)

        addTarget(self, action: #selector(editingChanged), for: .editingChanged)

        setupConstraints()
    }

    private func setupConstraints() {
        floatingLabelTopConstraint = floatingLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8)

        NSLayoutConstraint.activate([
            floatingLabelTopConstraint!,
            floatingLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            floatingLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),

            leadingAssistiveLabel.topAnchor.constraint(equalTo: bottomAnchor, constant: 4),
            leadingAssistiveLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),

            trailingAssistiveLabel.topAnchor.constraint(equalTo: bottomAnchor, constant: 4),
            trailingAssistiveLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            trailingAssistiveLabel.leadingAnchor.constraint(equalTo: leadingAssistiveLabel.trailingAnchor, constant: 4)
        ])
    }

    // MARK: - Floating Label Logic

    public override var placeholder: String? {
        didSet {
            originalPlaceholder = placeholder
            floatingLabel.text = placeholder
        }
    }

    public override func becomeFirstResponder() -> Bool {
        let didBecome = super.becomeFirstResponder()
        animateFloatingLabel(up: true)
        return didBecome
    }

    public override func resignFirstResponder() -> Bool {
        let didResign = super.resignFirstResponder()
        if text?.isEmpty ?? true {
            animateFloatingLabel(up: false)
        }
        return didResign
    }

    @objc private func editingChanged() {
        if !(text?.isEmpty ?? true) {
            animateFloatingLabel(up: true)
        }
    }

    private func animateFloatingLabel(up: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.floatingLabel.alpha = up ? 1 : 0
            self.floatingLabelTopConstraint?.constant = up ? -10 : 8
            self.layoutIfNeeded()
        }
    }

    // MARK: - Assistive Text

    public func setLeadingAssistiveText(_ text: String?) {
        leadingAssistiveLabel.text = text ?? " "
    }

    public func setTrailingAssistiveText(_ text: String?) {
        trailingAssistiveLabel.text = text ?? " "
    }

    // MARK: - State Styling

    private func updateStyle() {
        guard let scheme = scheme else { return }

        if isErrorState {
            layer.borderColor = scheme.colorScheme.errorColor?.cgColor
            leadingAssistiveLabel.textColor = scheme.colorScheme.errorColor
            trailingAssistiveLabel.textColor = scheme.colorScheme.errorColor
            floatingLabel.textColor = scheme.colorScheme.errorColor
        } else if isDisabled {
            layer.borderColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.12).cgColor
            textColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.38)
            leadingAssistiveLabel.textColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.38)
            trailingAssistiveLabel.textColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.38)
            floatingLabel.textColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.38)
        } else {
            layer.borderColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.38).cgColor
            textColor = scheme.colorScheme.onSurfaceColor
            leadingAssistiveLabel.textColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.6)
            trailingAssistiveLabel.textColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.6)
            floatingLabel.textColor = scheme.colorScheme.primaryColor
        }

        backgroundColor = scheme.colorScheme.surfaceColor
        tintColor = scheme.colorScheme.primaryColor
    }

    // MARK: - Intrinsic Size

    public override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 64)
    }
}
