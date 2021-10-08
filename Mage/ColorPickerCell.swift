//
//  ColorPickerCell.swift
//  MAGE
//
//  Created by Daniel Barela on 5/18/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@available(iOS 14.0, *)
class ColorPickerCell: UITableViewCell {
    
    let colorWell = UIColorWell(forAutoLayout: ())
    var colorPreference: String? {
        didSet {
            if let colorPreference = colorPreference {
                colorWell.selectedColor = UserDefaults.standard.color(forKey: colorPreference)
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier);
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.addSubview(colorWell)
        colorWell.autoAlignAxis(toSuperviewAxis: .horizontal);
        colorWell.autoPinEdge(toSuperviewEdge: .right, withInset: 16);
        colorWell.title = textLabel?.text
        colorWell.addTarget(self, action: #selector(colorWellChanged(_:)), for: .valueChanged)
    }
    
    @objc func colorWellChanged(_ sender: Any) {
        if let colorPreference = colorPreference {
            UserDefaults.standard.set(colorWell.selectedColor, forKey: colorPreference)
        }
    }
}
