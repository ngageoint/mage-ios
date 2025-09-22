//
//  IntroTabView.swift
//  MAGE
//
//  Created by James McDougall on 8/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct IntroTabView: View {
    init() {
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(.primary)
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(.secondary)
    }
    
    var body: some View {
        TabView {
            IntroView(title: "Welcome to MAGE", description: "Connect to a team server to sync and share field data.", imageName: "ExamplePhotoOne", isEndOfIntroViews: false)
                
                
            IntroView(title: "Make an Observation", description: "Capture a point of interest by placing a pin or drawing a shape on the map.", imageName: "ExamplePhotoTwo", isEndOfIntroViews: false)
                
            
            IntroView(title: "Join an Event", description: "Events are shared workspaces for a mission. All your observations are automatically saved and shared within your active event. \n\n Please contact your server administrator to be added to an event.", imageName: "", isEndOfIntroViews: false)
                .padding()
                
            
            IntroView(title: "Add Details with Forms", description: "Use forms to enhance observations with photos, videos, notes, and audio.", imageName: "FormsExamplePhoto", isEndOfIntroViews: true)
                
        }
        .tabViewStyle(.page)
        
    }
}

#Preview {
    IntroTabView()
}
