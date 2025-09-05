//
//  AuthenticationPreviews.swift
//  MAGE
//
//  Created by Brent Michalski on 9/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

//#if DEBUG

// MARK: - Preview Doubles

final class PreviewAuthService: AuthService {
    enum Mode {
        case success
        case unauthorized
        case invalidInput(String)
        case rateLimited
        case network
        case server(String)
    }
    
    var signupMode: Mode = .success
    var changePasswordMode: Mode = .success
    
    func signup(_ req: SignupRequest) async throws -> AuthSession {
        switch signupMode {
        case .success: return AuthSession(token: "preview-token")
        case .unauthorized: throw AuthError.unauthorized
        case .invalidInput(let msg): throw AuthError.invalidInput(msg)
        case .rateLimited: throw AuthError.rateLimited
        case .network: throw AuthError.network
        case .server(let msg): throw AuthError.server(msg)
        }
    }
    
    func changePassword(_ req: ChangePasswordRequest) async throws {
        switch changePasswordMode {
        case .success: return
        case .unauthorized: throw AuthError.unauthorized
        case .invalidInput(let msg): throw AuthError.invalidInput(msg)
        case .rateLimited: throw AuthError.rateLimited
        case .network: throw AuthError.network
        case .server(let msg): throw AuthError.server(msg)
        }
    }
}

final class PreviewSessionStore: SessionStore {
    private(set) var current: AuthSession?
    func set(_ session: AuthSession?) async { self.current = session }
    func clear() async { self.current = nil }
}

// MARK: - SignupViewSwiftUI Previews

enum SignupPreviewState {
    case empty
    case valid
    case submitting
    case errorUnauthorized
    case errorServer(String)
    case passwordMismatch
    case invalidEmail
}

@MainActor
private func makeSignupModel(_ state: SignupPreviewState,
                             auth: PreviewAuthService = .init(),
                             store: PreviewSessionStore = .init()) -> SignupViewModel {
    let vm = SignupViewModel(auth: auth, sessionStore: store)
    
    switch state {
    case .empty:
        break
        
    case .valid:
        vm.displayName = "Brent Danger"
        vm.username = "bignerd"
        vm.email = "brent@example.com"
        vm.password = "CorrectHorseBattery"
        vm.confirmPassword = "CorrectHorseBattery"
        
    case .submitting:
        vm.displayName = "Brent Danger"
        vm.username = "bignerd"
        vm.email = "brent@example.com"
        vm.password = "CorrectHorseBattery"
        vm.confirmPassword = "CorrectHorseBattery"
        vm.isSubmitting = true
        
    case .errorUnauthorized:
        auth.signupMode = .unauthorized
        vm.displayName = "Brent Danger"
        vm.username = "bignerd"
        vm.email = "brent@example.com"
        vm.password = "WrongPass!"
        vm.confirmPassword = "WrongPass!"
        vm.errorMessage = "Unauthorized. Check your credentials."
        
    case .errorServer(let msg):
        auth.signupMode = .server(msg)
        vm.displayName = "Brent Danger"
        vm.username = "bignerd"
        vm.email = "brent@example.com"
        vm.password = "CorrectHorseBattery"
        vm.confirmPassword = "CorrectHorseBattery"
        vm.errorMessage = msg
        
    case .passwordMismatch:
        vm.displayName = "Brent Danger"
        vm.username = "bignerd"
        vm.email = "brent@example.com"
        vm.password = "CorrectHorseBattery"
        vm.confirmPassword = "DifferentPassword"
        vm.errorMessage = "Passwords do not match."
        
    case .invalidEmail:
        vm.displayName = "Brent Danger"
        vm.username = "bignerd"
        vm.email = "brent_at_example"
        vm.password = "CorrectHorseBattery"
        vm.confirmPassword = "CorrectHorseBattery"
        vm.errorMessage = "Please enter a valid email."
    }
    
    return vm
}

// iOS 14+ (works on older Xcodes)
struct SignupViewSwiftUI_Previews: PreviewProvider {
    @MainActor static var previews: some View {
        Group {
            SignupViewSwiftUI(model: makeSignupModel(.empty))
                .previewDisplayName("Signup • Empty • Light")
            
            SignupViewSwiftUI(model: makeSignupModel(.valid))
                .previewDisplayName("Signup • Valid")
            
            SignupViewSwiftUI(model: makeSignupModel(.submitting))
                .previewDisplayName("Signup • Submitting")
            
            SignupViewSwiftUI(model: makeSignupModel(.errorUnauthorized))
                .previewDisplayName("Signup • Unauthorized")
            
            SignupViewSwiftUI(model: makeSignupModel(.errorServer("Server exploded (500)")))
                .previewDisplayName("Signup • Server Error")
            
            SignupViewSwiftUI(model: makeSignupModel(.passwordMismatch))
                .previewDisplayName("Signup • Password Mismatch")
            
            SignupViewSwiftUI(model: makeSignupModel(.invalidEmail))
                .previewDisplayName("Signup • Invalid Email")
            
            SignupViewSwiftUI(model: makeSignupModel(.valid))
                .preferredColorScheme(.dark)
                .previewDisplayName("Signup • Dark Mode")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

// iOS 17+ nice-to-have
@available(iOS 17, *)
#Preview("Signup • Empty • Light") { SignupViewSwiftUI(model: makeSignupModel(.empty)) }
@available(iOS 17, *)
#Preview("Signup • Valid") { SignupViewSwiftUI(model: makeSignupModel(.valid)) }
@available(iOS 17, *)
#Preview("Signup • Submitting") { SignupViewSwiftUI(model: makeSignupModel(.submitting)) }
@available(iOS 17, *)
#Preview("Signup • Unauthorized") { SignupViewSwiftUI(model: makeSignupModel(.errorUnauthorized)) }
@available(iOS 17, *)
#Preview("Signup • Server Error") { SignupViewSwiftUI(model: makeSignupModel(.errorServer("Server exploded (500)"))) }
@available(iOS 17, *)
#Preview("Signup • Password Mismatch") { SignupViewSwiftUI(model: makeSignupModel(.passwordMismatch)) }
@available(iOS 17, *)
#Preview("Signup • Invalid Email") { SignupViewSwiftUI(model: makeSignupModel(.invalidEmail)) }
@available(iOS 17, *)
#Preview("Signup • Dark Mode") {
    SignupViewSwiftUI(model: makeSignupModel(.valid)).preferredColorScheme(.dark)
}

// MARK: - ChangePasswordViewSwiftUI Previews

enum ChangePasswordPreviewState {
    case empty
    case valid
    case submitting
    case wrongCurrent
    case tooWeak
    case server(String)
}

@MainActor
private func makeChangePwModel(_ state: ChangePasswordPreviewState,
auth: PreviewAuthService = .init()) -> ChangePasswordViewModel {
    let vm = ChangePasswordViewModel(auth: auth)
    
    switch state {
    case .empty:
      break

    case .valid:
      vm.currentPassword = "OldPassword123"
      vm.newPassword = "NewPassword456"
      vm.confirmNewPassword = "NewPassword456"

    case .submitting:
      vm.currentPassword = "OldPassword123"
      vm.newPassword = "NewPassword456"
      vm.confirmNewPassword = "NewPassword456"
      vm.isSubmitting = true

    case .wrongCurrent:
      auth.changePasswordMode = .unauthorized
      vm.currentPassword = "WrongOld"
      vm.newPassword = "NewPassword456"
      vm.confirmNewPassword = "NewPassword456"
      vm.errorMessage = "Current password is incorrect."

    case .tooWeak:
      auth.changePasswordMode = .invalidInput("Password too weak.")
      vm.currentPassword = "OldPassword123"
      vm.newPassword = "weak"
      vm.confirmNewPassword = "weak"
      vm.errorMessage = "Password too weak."

    case .server(let msg):
      auth.changePasswordMode = .server(msg)
      vm.currentPassword = "OldPassword123"
      vm.newPassword = "NewPassword456"
      vm.confirmNewPassword = "NewPassword456"
      vm.errorMessage = msg
    }
    return vm
  }

  // iOS 14+ (works on older Xcodes)
  struct ChangePasswordViewSwiftUI_Previews: PreviewProvider {
    @MainActor static var previews: some View {
      Group {
        ChangePasswordViewSwiftUI(model: makeChangePwModel(.empty))
          .previewDisplayName("Change Pw • Empty")

        ChangePasswordViewSwiftUI(model: makeChangePwModel(.valid))
          .previewDisplayName("Change Pw • Valid")

        ChangePasswordViewSwiftUI(model: makeChangePwModel(.submitting))
          .previewDisplayName("Change Pw • Submitting")

        ChangePasswordViewSwiftUI(model: makeChangePwModel(.wrongCurrent))
          .previewDisplayName("Change Pw • Wrong Current")

        ChangePasswordViewSwiftUI(model: makeChangePwModel(.tooWeak))
          .previewDisplayName("Change Pw • Too Weak")

        ChangePasswordViewSwiftUI(model: makeChangePwModel(.server("Server exploded (500)")))
          .previewDisplayName("Change Pw • Server Error")

        ChangePasswordViewSwiftUI(model: makeChangePwModel(.valid))
          .preferredColorScheme(.dark)
          .previewDisplayName("Change Pw • Dark Mode")
      }
      .padding()
      .previewLayout(.sizeThatFits)
    }
  }

  // iOS 17+ nice-to-have
  @available(iOS 17, *)
  #Preview("Change Pw • Empty") { ChangePasswordViewSwiftUI(model: makeChangePwModel(.empty)) }
  @available(iOS 17, *)
  #Preview("Change Pw • Valid") { ChangePasswordViewSwiftUI(model: makeChangePwModel(.valid)) }
  @available(iOS 17, *)
  #Preview("Change Pw • Submitting") { ChangePasswordViewSwiftUI(model: makeChangePwModel(.submitting)) }
  @available(iOS 17, *)
  #Preview("Change Pw • Wrong Current") { ChangePasswordViewSwiftUI(model: makeChangePwModel(.wrongCurrent)) }
  @available(iOS 17, *)
  #Preview("Change Pw • Too Weak") { ChangePasswordViewSwiftUI(model: makeChangePwModel(.tooWeak)) }
  @available(iOS 17, *)
  #Preview("Change Pw • Server Error") { ChangePasswordViewSwiftUI(model: makeChangePwModel(.server("Server exploded (500)"))) }
  @available(iOS 17, *)
  #Preview("Change Pw • Dark Mode") {
    ChangePasswordViewSwiftUI(model: makeChangePwModel(.valid)).preferredColorScheme(.dark)
  }

//  #endif // DEBUG
