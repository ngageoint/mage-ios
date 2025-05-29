//
//  StyledPolygon.m
//  MAGE
//
//  This class exists so that I can keep style information with the polygons
//  and style them correctly.
//
//

import MapKit
import MapFramework
import DataSourceDefinition

@objc class StyledPolygon: MKPolygon, OverlayRenderable, DataSourceIdentifiable {
    var id: String = ""
    
    var itemKey: String = ""
    
    var dataSource: any DataSourceDefinition = UnknownDefinition.definition
    
    var renderer: MKOverlayRenderer {
        get {
            let renderer = MKPolygonRenderer(polygon: self)
            renderer.fillColor = fillColor
            renderer.strokeColor = lineColor
            renderer.lineWidth = lineWidth
            return renderer
        }
    }
    
    @objc public var lineColor: UIColor = .black
    @objc public var lineWidth: CGFloat = 1.0
    @objc public var fillColor: UIColor?
    @objc var observationRemoteId: String?
    public var _observation: Observation?
    
    public var observation: Observation? {
        get {
            guard let observationRemoteId = observationRemoteId else {
                return _observation
            }
            @Injected(\.nsManagedObjectContext)
            var context: NSManagedObjectContext?
            
            guard let context = context else { return nil }
            return try? context.fetchFirst(Observation.self, predicate: NSPredicate(format: "remoteId == %@", observationRemoteId))
        }
        set {
            if let remoteId = newValue?.remoteId {
                observationRemoteId = remoteId
            } else {
                _observation = newValue
            }
        }
    }
    
    @objc static func generate(coordinates: [[[NSNumber]]])-> StyledPolygon {
        // exterior polygon
        let exteriorPolygonCoordinates = coordinates[0]
        var interiorPolygonCoordinates: [[[NSNumber]]] = []
        
        var exteriorMapCoordinates: [CLLocationCoordinate2D] = []
        for point in exteriorPolygonCoordinates {
            exteriorMapCoordinates.append(CLLocationCoordinate2D(latitude: point[1].doubleValue, longitude: point[0].doubleValue))
        }
        
        // interior polygons
        var interiorPolygons: [MKPolygon] = []
        if coordinates.count > 1 {
            interiorPolygonCoordinates.append(contentsOf: coordinates)
            interiorPolygonCoordinates.remove(at: 0)
            let recursePolygon = StyledPolygon.generate(coordinates: interiorPolygonCoordinates)
            interiorPolygons.append(recursePolygon)
        }
        
        let exteriorPolygon: StyledPolygon = !interiorPolygons.isEmpty ? StyledPolygon(coordinates: exteriorMapCoordinates, count: exteriorPolygonCoordinates.count, interiorPolygons: interiorPolygons) : StyledPolygon(coordinates: exteriorMapCoordinates, count: exteriorPolygonCoordinates.count)
        
        return exteriorPolygon
    }
    
    @objc static func create(polygon: MKPolygon) -> StyledPolygon {
        let styledPolygon = StyledPolygon(points: polygon.points(), count: polygon.pointCount)
        styledPolygon.title = polygon.title
        styledPolygon.subtitle = polygon.subtitle
        return styledPolygon
    }
    
    @objc public func setLineColor(hex: String, alpha: CGFloat = 1.0) {
        self.lineColor = UIColor(hex: hex)?.withAlphaComponent(alpha) ?? self.lineColor
    }
    
    @objc public func setFillColor(hex: String, alpha: CGFloat = 1.0) {
        self.fillColor = UIColor(hex: hex)?.withAlphaComponent(alpha) ?? self.fillColor
    }

}
