//
//  NavigationControllerObserver.swift
//  MAGE
//
//  Created by Daniel Barela on 4/6/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc public protocol NavigationControllerObserverDelegate : class {
    /**
     Callback when a `viewController` is popped from the `navigationController` stack
     - parameter observer: the observer that observed the pop transition
     - parameter viewController: the `UIViewController` that has been popped from the stack
     */
    func navigationControllerObserver(_ observer: NavigationControllerObserver,
                                      didObservePopTransitionFor viewController: UIViewController)
}

// We can't use Weak<T: AnyObject> here because we would have
// to declare NavigationControllerObserverDelegate as @objc
private class NavigationControllerObserverDelegateContainer {
    
    private(set) weak var value: NavigationControllerObserverDelegate?
    
    init(value: NavigationControllerObserverDelegate) {
        self.value = value
    }
}

/**
 The `NavigationControllerObserver` class provides a simple API to observe the
 pop transitions that occur in a `navigationController` stack.
 One drawback of `UINavigationController` is that its delegate is shared among multiple
 view controllers and this requires a lot of bookkeeping to register multiple delegates.
 `NavigationControllerObserver` allows to register a delegate per viewController we want to observe.
 What's more the class provides a `navigationControllerDelegate` property used to forward all the
 `UINavigationControllerDelegate` methods to another navigationController delegate if need be.
 - important: The `NavigationControllerObserver` will observe only *animated* pop transitions.
 Indeed, if you call `popViewController(animated: false)` you won't be notified.
 */
@objc public class NavigationControllerObserver : NSObject, UINavigationControllerDelegate {
    
    /**
     All calls from `UINavigationControllerDelegate` methods are forwarded to this object
     */
    @objc public weak var navigationControllerDelegate: UINavigationControllerDelegate? {
        didSet {
            // Make the navigationController reevaluate respondsToSelector
            // for UINavigationControllerDelegate methods
            navigationController.delegate = nil
            navigationController.delegate = self
        }
    }
    
    private var viewControllersToDelegates: [UIViewController: NavigationControllerObserverDelegateContainer] = [:]
    private let navigationController: UINavigationController
    
    /**
     - parameter navigationController: the `UINavigationController` we want to observe
     */
    @objc public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
        navigationController.delegate = self
    }
    
    //MARK: - NSObject
    @objc override public func responds(to aSelector: Selector!) -> Bool {
        if shouldForwardSelector(aSelector) {
            return navigationControllerDelegate?.responds(to: aSelector) ?? false
        }
        return super.responds(to: aSelector)
    }
    
    @objc override public func forwardingTarget(for aSelector: Selector!) -> Any? {
        if shouldForwardSelector(aSelector) {
            return navigationControllerDelegate
        }
        return super.forwardingTarget(for: aSelector)
    }
    
    //MARK: - Public
    /**
     Observe a pop transition in the `navigationController` stack
     - parameter viewController: the `UIViewController` instance to observe in the `navigationController` stack
     - parameter delegate: The delegate that will be notified of the transition
     */
    @objc public func observePopTransition(of viewController: UIViewController,
                                     delegate: NavigationControllerObserverDelegate) {
        let wrappedDelegate = NavigationControllerObserverDelegateContainer(value: delegate)
        viewControllersToDelegates[viewController] = wrappedDelegate
    }
    
    //MARK: - UINavigationControllerDelegate
    @objc public func navigationController(_ navigationController: UINavigationController,
                                     didShow viewController: UIViewController,
                                     animated: Bool) {
        navigationControllerDelegate?.navigationController?(
            navigationController,
            didShow: viewController,
            animated: animated
        )
        
        guard
            let fromViewController = navigationController.transitionCoordinator?.viewController(forKey: .from),
            !navigationController.viewControllers.contains(fromViewController) else {
                return
        }
        
        if let wrappedDelegate = viewControllersToDelegates[fromViewController] {
            let delegate = wrappedDelegate.value
            delegate?.navigationControllerObserver(self, didObservePopTransitionFor: fromViewController)
            viewControllersToDelegates.removeValue(forKey: fromViewController)
        }
        
        cleanOutdatedViewControllers()
    }
    
    //MARK: - Private
    private func shouldForwardSelector(_ aSelector: Selector!) -> Bool {
        let description = protocol_getMethodDescription(UINavigationControllerDelegate.self, aSelector, false, true)
        return
            description.name != nil // belongs to UINavigationControllerDelegate
                && class_getInstanceMethod(type(of: self), aSelector) == nil // self does not implement aSelector
    }
    
    private func cleanOutdatedViewControllers() {
        let viewControllersToRemove = viewControllersToDelegates.keys.filter {
            $0.parent != self.navigationController
        }
        viewControllersToRemove.forEach {
            viewControllersToDelegates.removeValue(forKey: $0)
        }
    }
}
