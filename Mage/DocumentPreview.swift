import Foundation
import UIKit
import SwiftUI
import QuickLook

extension View {
    
    func documentPreview<Content: View>(
        previewUrl: Binding<URL?>,
        previewDate: Binding<Date>,
        viewController: UIViewController? = nil,
        @ViewBuilder content: @escaping () -> Content) -> some View {
        background {
            Color.clear
                .onChange(of: previewDate.wrappedValue) { _ in
                    if let url = previewUrl.wrappedValue {
                        DocumentController.shared.presentQL(url: url, viewControllerToPresentFrom: viewController)
                    }
                }
        }
    }
}

class DocumentController: NSObject, ObservableObject, UIDocumentInteractionControllerDelegate, QLPreviewControllerDelegate, QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> any QLPreviewItem {
        return url! as QLPreviewItem
    }
    

    public static let shared = DocumentController()
    var controller: UIDocumentInteractionController?
    var presentingViewController: UIViewController?
    var viewControllerToPresentFrom: UIViewController?
    
    var url: URL?
    
    override private init() {
        
    }
    
    func dismissPreview() {
        controller?.dismissPreview(animated: true)
        presentingViewController?.dismiss(animated: true, completion: {
            print("dismissed")
        })
    }
    
    func getQuickLookViewController(url: URL) -> QLPreviewController {
        self.url = url
        let previewController = QLPreviewController()
        previewController.dataSource = self
        return previewController
    }
    
    func presentQL(url: URL, viewControllerToPresentFrom: UIViewController? = nil) {
        self.url = url
        let previewController = QLPreviewController()
        previewController.dataSource = self
        presentingViewController = viewControllerToPresentFrom ?? UIApplication.shared.keyWindow?.rootViewController ?? UIViewController()
        if let nav = presentingViewController?.navigationController {
            nav.pushViewController(previewController, animated: true)
        } else {
            presentingViewController?.present(previewController, animated: true)
        }

    }
    
    func presentDocument(url: URL, viewControllerToPresentFrom: UIViewController? = nil) {
        print("xxx show the url \(url)")
        self.viewControllerToPresentFrom = viewControllerToPresentFrom
        controller = UIDocumentInteractionController()
        controller?.delegate = self
        controller?.url = url
        controller?.presentPreview(animated: true)
    }
    
    func documentInteractionControllerViewControllerForPreview(_: UIDocumentInteractionController) -> UIViewController {
        presentingViewController = viewControllerToPresentFrom ?? UIApplication.shared.keyWindow?.rootViewController ?? UIViewController()
        if let nav = presentingViewController?.navigationController {
            return nav
        }
        return presentingViewController!
    }
}
