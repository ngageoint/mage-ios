//
//  NumberBadge.swift
//  MAGE
//
//  Created by Daniel Barela on 5/11/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIKit

class NumberBadge: UIView {
    var labelWidth: NSLayoutConstraint?
    var labelHeight: NSLayoutConstraint?
    var didSetupConstraints = false
    var badgeTintColor: UIColor = .systemRed
    var textColor: UIColor = .white
    
    var showsZero: Bool = false
    var _number: Int = 0
    
    var number: Int {
        get {
            return _number
        }
        set {
            _number = newValue
            updateLabel()
        }
    }
    
    let label = UILabel.newAutoLayout()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    init(number: Int, showsZero: Bool = false, tintColor: UIColor = .systemRed, textColor: UIColor = .white) {
        super.init(frame: CGRect.zero);
        self.configureForAutoLayout();
        addSubview(label)
        self.badgeTintColor = tintColor
        self.showsZero = showsZero
        self.number = number
    }
    
    func updateLabel() {
        label.text = String(describing:number)
        label.isHidden = !showsZero && number == 0
        label.clipsToBounds = true
        label.backgroundColor = badgeTintColor
        label.textColor = textColor
        label.textAlignment = .center
        label.accessibilityLabel = "Badge \(label.text ?? "")"
        setNeedsUpdateConstraints()
    }
    
    override func updateConstraints() {
        let fontSize = label.font.pointSize
        let textSize = (label.text as? NSString)?.size(withAttributes: [.font : label.font ?? .systemFont(ofSize: 10)]) ?? .zero
        if !didSetupConstraints {
            self.label.autoPinEdgesToSuperviewEdges()
            self.labelWidth = label.autoSetDimension(.width, toSize: 0)
            self.labelHeight = label.autoSetDimension(.height, toSize: 0)
        }
        
        didSetupConstraints = true
        
        self.labelHeight?.constant = (0.4 * fontSize) + textSize.height
        self.labelWidth?.constant = number <= 9 ? (self.labelHeight?.constant ?? 0) : textSize.width + fontSize
        
        label.layer.cornerRadius = (self.labelHeight?.constant ?? 0.0) / 2.0
        
        super.updateConstraints()
    }
}
