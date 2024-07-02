//
//  StaticPointAnnotation.swift
//  MAGE
//
//

class StaticPointAnnotation: MapAnnotation {
    
    var feature: [AnyHashable: Any]?
    var iconUrl: String?
    var layerName: String?
    
    public convenience init(feature: [AnyHashable: Any]) {
        self.init()
        self.feature = feature
        // set a title so that the annotation tap event will actually occur on the map delegate
        self.title = " "
        if let coordinates = (feature["geometry"] as? [AnyHashable: Any])?["coordinates"] as? [Double] {
            self.coordinate = CLLocationCoordinate2D(latitude: coordinates[1], longitude: coordinates[0])
        }
        if let properties = feature["properties"] as? [AnyHashable: Any],
           let style = properties["style"] as? [AnyHashable: Any],
           let iconStyle = style["iconStyle"] as? [AnyHashable: Any],
           let icon = iconStyle["icon"] as? [AnyHashable: Any],
           let href = icon["href"] as? String {
            self.iconUrl = href
        }
    }
    
    public override func viewForAnnotation(on mapView: MKMapView, scheme: MDCContainerScheming?) -> MKAnnotationView {
        if let iconUrl = self.iconUrl {
            return customAnnotationView(mapView: mapView, iconUrl: iconUrl)
        }
        return defaultAnnotationView(mapView: mapView)
    }
    
    func defaultAnnotationView(mapView: MKMapView) -> MKAnnotationView {
        let annotationView: MKAnnotationView = {
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "pinAnnotation") {
                annotationView.annotation = self
                return annotationView
            }
            return MKMarkerAnnotationView(annotation: self, reuseIdentifier: "pinAnnotation")
        }()
        
        self.view = annotationView
        return annotationView
    }
    
    func customAnnotationView(mapView: MKMapView, iconUrl: String) -> MKAnnotationView {
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: iconUrl) {
            annotationView.annotation = self
            self.view = annotationView
            return annotationView
        }
        NSLog("Showing icon from \(iconUrl)")
        let annotationView = MKAnnotationView(annotation: self, reuseIdentifier: iconUrl)
        annotationView.isEnabled = false
        annotationView.canShowCallout = false
        DispatchQueue.global(qos: .userInitiated).async {
            let image: UIImage? = {
                if iconUrl.lowercased().hasPrefix("http"), let iconUrl = URL(string: iconUrl) {
                    if let data = try? Data(contentsOf: iconUrl) {
                        return UIImage(data: data)
                    }
                } else {
                    if let data = try? Data(contentsOf: self.getDocumentsDirectory().appending(component: iconUrl)) {
                        return UIImage(data: data)
                    }
                }
                return UIImage(named: "marker")
            }()
            if let image = image, let cgImage = image.cgImage {
                let widthScale = 35.0 // * UIScreen.main.scale
                let scaledImage = image.aspectResize(to: CGSize(width: widthScale, height: image.size.height / (image.size.width / widthScale)))
                Task { @MainActor in
                    annotationView.image = scaledImage
                    annotationView.centerOffset = CGPoint(x: 0, y: -(scaledImage.size.height / 2.0))
                }
            }
        }
        annotationView.annotation = self
        self.view = annotationView
        return annotationView
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func detailTextForAnnotation() -> String {
        let title: String? = {
            if let properties = feature?["properties"] as? [AnyHashable: Any],
               let name = properties["name"] as? String
            {
                return name
            }
            return nil
        }()
        
        let description: String? = {
            if let properties = feature?["properties"] as? [AnyHashable: Any],
               let description = properties["description"] as? String
            {
                return description
            }
            return nil
        }()
        
        return "\(title ?? "")</br>\(description ?? "")"
    }
}
