//
//  EnlargedAnnotation.swift
//  MAGE
//
//  Created by Daniel Barela on 4/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import DataSourceDefinition

public protocol DataSourceIdentifiable {
    var id: String { get set }
    var itemKey: String { get set }
    
    var dataSource: any DataSourceDefinition { get set }
}

public class UnknownDefinition: DataSourceDefinition {
    public var mappable: Bool = false

    public var color: UIColor = .magenta

    public var imageName: String?
    
    public var systemImageName: String? = "face.smiling"

    public var key: String = "unknown"

    public var name: String = "Unknown"

    public var fullName: String = "Unknown"

    public static let definition = UnknownDefinition()
    private init() { }
}

//@MainActor
open class DataSourceAnnotation: NSObject, MKAnnotation, Identifiable, DataSourceIdentifiable {
    static func == (lhs: DataSourceAnnotation, rhs: DataSourceAnnotation) -> Bool {
        lhs.id == rhs.id
    }

    open override var hash: Int {
        id.hashValue
    }
    
    public var id: String
    public var itemKey: String
    
    open var dataSource: any DataSourceDefinition = UnknownDefinition.definition
    
    public var enlarged: Bool = false

    public var shouldEnlarge: Bool = false

    public var shouldShrink: Bool = false

    public var annotationView: MKAnnotationView?

    var color: UIColor {
        return UIColor.clear
    }

    dynamic public var coordinate: CLLocationCoordinate2D

    public init(coordinate: CLLocationCoordinate2D, itemKey: String) {
        self.coordinate = coordinate
//        self.dataSource = dataSource
        self.id = UUID().uuidString
        self.itemKey = itemKey
    }

    public func markForEnlarging() {
        shouldEnlarge = true
    }

    public func markForShrinking() {
        shouldShrink = true
    }

    public func enlargeAnnoation() {
        guard let annotationView = annotationView else {
            return
        }
        enlarged = true
        shouldEnlarge = false
        annotationView.clusteringIdentifier = nil
        let currentOffset = annotationView.centerOffset
        annotationView.transform = annotationView.transform.scaledBy(x: 2.0, y: 2.0)
        annotationView.centerOffset = CGPoint(x: currentOffset.x * 2.0, y: currentOffset.y * 2.0)

//        annotationView.transform = annotationView.transform.scaledBy(x: 2.0, y: 2.0)
//        annotationView.centerOffset = CGPoint(x: 0, y: -(annotationView.image?.size.height ?? 0))
    }

    public func shrinkAnnotation() {
        guard let annotationView = annotationView else {
            return
        }
        enlarged = false
        shouldShrink = false
        let currentOffset = annotationView.centerOffset
        annotationView.transform = annotationView.transform.scaledBy(x: 0.5, y: 0.5)
        annotationView.centerOffset = CGPoint(x: currentOffset.x * 0.5, y: currentOffset.y * 0.5)

//        annotationView.transform = annotationView.transform.scaledBy(x: 0.5, y: 0.5)
//        annotationView.centerOffset = CGPoint(x: 0, y: -((annotationView.image?.size.height ?? 0.0) / 2.0))
    }
}

class EnlargedAnnotationView: MKAnnotationView {
    static let ReuseID = "enlarged"

    /// - Tag: ClusterIdentifier
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
