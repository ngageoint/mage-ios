//
//  ColorPickerCelliOS13.swift
//  MAGE
//
//  Created by Daniel Barela on 5/18/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class ColorPickerCelliOS13: UITableViewCell {
    
    let colorWell: UIView = UIView(forAutoLayout: ());
    var colorPreference: String? {
        didSet {
            if let colorPreference = colorPreference {
                colorWell.backgroundColor = UserDefaults.standard.color(forKey: colorPreference)
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
        colorWell.autoSetDimensions(to: CGSize(width: 20, height: 20));
        colorWell.layer.cornerRadius = 10;
    }
}
