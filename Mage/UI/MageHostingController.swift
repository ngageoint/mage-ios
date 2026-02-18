//
//  MageHostingController.swift
//  MAGE
//
//  Created by Daniel Barela on 4/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI

class MageHostingController<Content>: UIHostingController<Content> where Content: View {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.invalidateIntrinsicContentSize()
    }
    
    override init(rootView: Content) {
        super.init(rootView: rootView)
        sizingOptions = .preferredContentSize
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}

class SwiftUIViewController: UIViewController {
    var swiftUIView: AnyView?
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    public init(swiftUIView: some View) {
        self.swiftUIView = AnyView(swiftUIView)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addSwiftUIView()
    }

    func addSwiftUIView() {
        if let swiftUIView = swiftUIView {
            let controller = MageHostingController(
                rootView: swiftUIView
            )
            addChild(controller)
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(controller.view)
            controller.didMove(toParent: self)
            view.backgroundColor = UIColor.clear
            controller.view.backgroundColor = UIColor.clear
            NSLayoutConstraint.activate([
                controller.view.widthAnchor.constraint(equalTo: view.widthAnchor),
                controller.view.heightAnchor.constraint(equalTo: view.heightAnchor),
                controller.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                controller.view.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }
    }
}
