//
//  SplitLayout.swift
//  MAGE
//
//  Created by Daniel Barela on 10/26/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
class SplitLayout: UICollectionViewLayout {
    
    var itemSpacing: CGFloat = 5
    var rowSpacing: CGFloat = 5
    
    private var itemSize: CGSize!
    private var fullWidthItemSize: CGSize!
    private var numberOfRows: Int!
    private var numberOfColumns: Int!
    private var count: Int!
    
    override func prepare() {
        super.prepare()
        
        count = collectionView!.numberOfItems(inSection: 0)
        
        numberOfColumns = 2
        numberOfRows = Int(ceil(Double(count) / Double(numberOfColumns)))
        
        if count % 2 == 1 {
            let width = (collectionView!.bounds.width - (itemSpacing * CGFloat(numberOfColumns - 1))) / CGFloat(numberOfColumns)
            let height = (collectionView!.bounds.height - (rowSpacing * CGFloat(numberOfRows - 1))) / CGFloat(numberOfRows)
            itemSize = CGSize(width: width, height: height)
            fullWidthItemSize = CGSize(width: collectionView!.bounds.width, height: height)
        } else {
            let width = 200.0
            let height = 200.0
            itemSize = CGSize(width: width, height: height)
            fullWidthItemSize = CGSize(width: collectionView!.bounds.width, height: height)
        }
    }
    
    override var collectionViewContentSize: CGSize {
        return collectionView!.bounds.size
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        
        attributes.center = centerForItem(at: indexPath)
        if (count % 2 == 1 && indexPath.item == 0) {
            attributes.size = fullWidthItemSize
        } else {
            attributes.size = itemSize
        }
        
        return attributes
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return (0 ..< collectionView!.numberOfItems(inSection: 0)).map { IndexPath(item: $0, section: 0) }
            .compactMap { layoutAttributesForItem(at: $0) }
    }
    
    private func centerForItem(at indexPath: IndexPath) -> CGPoint {
        if (count % 2 == 1 && indexPath.item == 0) {
            return CGPoint(x: fullWidthItemSize.width / 2,
                           y: fullWidthItemSize.height / 2)
        }
        
        let item = indexPath.item + (count % 2);
        
        let row = (item / numberOfColumns)
        let col = (item - row * numberOfColumns)
        
        return CGPoint(x: CGFloat(col) * (itemSize.width + itemSpacing) + itemSize.width / 2,
                       y: CGFloat(row) * (itemSize.height + rowSpacing) + itemSize.height / 2)
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}
