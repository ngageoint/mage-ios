//
//  ThemedTextField.swift
//  MAGE
//
//  Created by Brent Danger Michalski on 7/1/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

@objcMembers
@IBDesignable
public class ThemedTextField: UIView {

    // Public subcomponents
    public let textField = UITextField()
    public let leadingAssistiveLabel = UILabel()
    public let assistiveLabel = UILabel()
    
    private let containerView = UIView()
    private var leadingView: UIView?
    private var trailingView: UIView?

    public var scheme: AppContainerScheming? {
        didSet {
            updateStyle()
        }
    }

    public var isErrorState: Bool = false {
        didSet {
            updateStyle()
        }
    }

    public var isDisabled: Bool = false {
        didSet {
            textField.isEnabled = !isDisabled
            updateStyle()
        }
    }

    
    // MARK: - IBInspectable Bridge
    @IBInspectable public var placeholder: String? {
        get { textField.placeholder }
        set { textField.placeholder = newValue }
    }
    
    @IBInspectable public var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }
    
    @IBInspectable public var isSecureTextEntry: Bool {
        get { textField.isSecureTextEntry }
        set { textField.isSecureTextEntry = newValue }
    }
    
    // MARK: - Init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    // MARK: - View Setup
    private func setupViews() {
        addSubview(containerView)
        containerView.layer.cornerRadius = 4
        containerView.layer.borderWidth = 1
        containerView.clipsToBounds = true
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        leadingAssistiveLabel.translatesAutoresizingMaskIntoConstraints = false
        assistiveLabel.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(textField)
        addSubview(leadingAssistiveLabel)
        addSubview(assistiveLabel)

        leadingAssistiveLabel.font = UIFont.systemFont(ofSize: 12)
        leadingAssistiveLabel.numberOfLines = 0
        
        assistiveLabel.font = UIFont.systemFont(ofSize: 12)
        assistiveLabel.numberOfLines = 0

        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),

            textField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            textField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            leadingAssistiveLabel.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 4),
            leadingAssistiveLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),

            assistiveLabel.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 4),
            assistiveLabel.leadingAnchor.constraint(equalTo: leadingAssistiveLabel.trailingAnchor, constant: 8),
            assistiveLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            assistiveLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2)
        ])
    }

    private func updateStyle() {
        guard let scheme = scheme else { return }
        
        if isErrorState {
            containerView.layer.borderColor = scheme.colorScheme.errorColor?.cgColor
            assistiveLabel.textColor = scheme.colorScheme.errorColor
            leadingAssistiveLabel.textColor = scheme.colorScheme.errorColor
        } else if isDisabled {
            containerView.layer.borderColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.12).cgColor
            assistiveLabel.textColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.38)
            leadingAssistiveLabel.textColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.38)
        } else {
            containerView.layer.borderColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.38).cgColor
            assistiveLabel.textColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.6)
            leadingAssistiveLabel.textColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.6)
        }
        
        containerView.backgroundColor = scheme.colorScheme.surfaceColor
        textField.textColor = scheme.colorScheme.onSurfaceColor
        textField.tintColor = scheme.colorScheme.primaryColor
    }
    
    
    // MARK: API
    public func setLeadingView(_ view: UIView?) {
        leadingView?.removeFromSuperview()
        leadingView = view
        
        if let view = view {
            textField.leftView = view
            textField.leftViewMode = .always
        }
    }

    public func setTrailingView(_ view: UIView?) {
        trailingView?.removeFromSuperview()
        trailingView = view
            
        if let view = view {
            textField.rightView = view
            textField.rightViewMode = .always
        }
    }
    
    public func setAssistiveText(_ text: String?) {
        assistiveLabel.text = text ?? " "
    }
    
    public func setLeadingAssistiveText(_ text: String?) {
        leadingAssistiveLabel.text = text ?? " "
    }
    
    // MARK: - Forward common UITextField methods
    public override var isFirstResponder: Bool {
        return textField.isFirstResponder
    }
    
    public override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    public override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
    
    public var delegate: UITextFieldDelegate? {
        get { textField.delegate }
        set { textField.delegate = newValue }
    }
    
    public func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        textField.addTarget(target, action: action, for: controlEvents)
    }
}
