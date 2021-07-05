extension KeyboardHelper {
    enum Animation {
        case keyboardWillShow
        case keyboardWillHide
    }
    
    typealias HandleBlock = (_ animation: Animation, _ keyboardFrame: CGRect, _ duration: TimeInterval) -> Void
}

final class KeyboardHelper {
    private let handleBlock: HandleBlock
    
    init(handleBlock: @escaping HandleBlock) {
        self.handleBlock = handleBlock
        setupNotification()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotification() {
        _ = NotificationCenter.default
            .addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] notification in
                self?.handle(animation: .keyboardWillShow, notification: notification)
            }
        
        _ = NotificationCenter.default
            .addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] notification in
                self?.handle(animation: .keyboardWillHide, notification: notification)
            }
    }
    
    private func handle(animation: Animation, notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }
        
        handleBlock(animation, keyboardFrame, duration)
    }
}
