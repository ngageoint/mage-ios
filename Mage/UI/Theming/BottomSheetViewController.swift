//
//  BottomSheetViewController.swift
//  MAGE
//
//  Created by Brent Michalski on 6/27/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

@objc public protocol BottomSheetViewControllerDelegate: AnyObject {
    @objc optional func bottomSheetDidDismiss(_ controller: BottomSheetViewController)
}

@objc public class BottomSheetViewController: UIViewController {

    @objc public let contentViewController: UIViewController
    @objc public weak var delegate: BottomSheetViewControllerDelegate?

    @objc public var dismissOnBackgroundTap: Bool = true
    @objc public var dismissOnDraggingDownSheet: Bool = true
    @objc public var scrimColor: UIColor = UIColor.black.withAlphaComponent(0.5)

    private var dimmingView: UIView?
    private let transitionDelegate = BottomSheetTransitionDelegate()

    @objc public init(contentViewController: UIViewController) {
        self.contentViewController = contentViewController
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = transitionDelegate
        transitionDelegate.bottomSheetVC = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class BottomSheetTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    weak var bottomSheetVC: BottomSheetViewController?

    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?, source: UIViewController)
        -> UIPresentationController? {
        return BottomSheetPresentationController(presentedViewController: presented,
                                                 presenting: presenting,
                                                 bottomSheetVC: bottomSheetVC)
    }
}

private class BottomSheetPresentationController: UIPresentationController {

    private weak var bottomSheetVC: BottomSheetViewController?
    private var dimmingView: UIView!

    init(presentedViewController: UIViewController,
         presenting presentingViewController: UIViewController?,
         bottomSheetVC: BottomSheetViewController?) {
        self.bottomSheetVC = bottomSheetVC
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        setupDimmingView()
    }

    private func setupDimmingView() {
        dimmingView = UIView()
        dimmingView.backgroundColor = bottomSheetVC?.scrimColor ?? UIColor.black.withAlphaComponent(0.5)
        dimmingView.alpha = 0.0
        if bottomSheetVC?.dismissOnBackgroundTap ?? true {
            let tap = UITapGestureRecognizer(target: self, action: #selector(dismissTapped))
            dimmingView.addGestureRecognizer(tap)
        }
    }

    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }
        dimmingView.frame = containerView.bounds
        containerView.insertSubview(dimmingView, at: 0)

        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 1.0
            })
        } else {
            dimmingView.alpha = 1.0
        }
    }

    override func dismissalTransitionWillBegin() {
        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 0.0
            })
        } else {
            dimmingView.alpha = 0.0
        }
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        dimmingView.frame = containerView?.bounds ?? .zero
        presentedView?.frame = frameOfPresentedViewInContainerView
        presentedView?.layer.cornerRadius = 16
        presentedView?.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        presentedView?.layer.masksToBounds = true
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }
        let containerBounds = containerView.bounds
        let targetHeight = bottomSheetVC?.contentViewController.preferredContentSize.height ?? 300
        let safeAreaBottom = containerView.safeAreaInsets.bottom
        return CGRect(x: 0,
                      y: containerBounds.height - targetHeight - safeAreaBottom,
                      width: containerBounds.width,
                      height: targetHeight + safeAreaBottom)
    }

    @objc private func dismissTapped() {
        bottomSheetVC?.dismiss(animated: true, completion: {
            self.bottomSheetVC?.delegate?.bottomSheetDidDismiss?(self.bottomSheetVC!)
        })
    }
}

