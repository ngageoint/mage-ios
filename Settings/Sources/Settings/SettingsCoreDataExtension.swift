// 
//     
//  SettingsCoreDataExtension.swift
//  SettingsFetch
//
// 


import Persistence
import ServerDTO

public extension Settings {
    
    var mapSearchType: MapSearchType {
        get { return MapSearchType(rawValue: self.mapSearchTypeCode) ?? .none }
        set { self.mapSearchTypeCode = newValue.rawValue }
    }
}
