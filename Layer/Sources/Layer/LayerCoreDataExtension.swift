// 
//     
//  LayerCoreDataExtension.swift
//  Layer
//
// 


import Foundation
import Persistence

extension Layer {
    @objc public static let OFFLINE_LAYER_LOADED = 1.0;
    @objc public static let OFFLINE_LAYER_NOT_DOWNLOADED = 0.0;
    @objc public static let EXTERNAL_LAYER_LOADED = 0.5;
    @objc public static let EXTERNAL_LAYER_PROCESSING = -1.0;
    
    public func initializeDownloadState() {
        self.loaded = NSNumber(floatLiteral: Layer.OFFLINE_LAYER_NOT_DOWNLOADED)
    }
}

import ServerDTO

public extension Layer {
    func apply(dto: MapLayerDTO, eventID: EventID) {
        self.remoteId = dto.remoteId.rawValue
        self.name = dto.name
        self.type = dto.type
        self.url = dto.url
        self.file = dto.file
        self.layerDescription = dto.layerDescription
        self.state = dto.state
        self.base = dto.base
        self.eventId = eventID.rawValue;
    }
}

extension ImageryLayer {
    public func applyImageryLayer(dto: MapLayerDTO, eventID: EventID) {
        self.remoteId = dto.remoteId.rawValue
        self.name = dto.name
        self.type = dto.type
        self.url = dto.url
        self.file = dto.file
        self.layerDescription = dto.layerDescription
        self.state = dto.state
        self.base = dto.base
        self.format = dto.format
        self.options = dto.options
        self.isSecure = self.url?.hasPrefix("https") ?? false
        self.eventId = eventID.rawValue
    }
}
