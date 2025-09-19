//
//  AuthenticationPreviews.swift
//  MAGE
//
//  Created by Brent Michalski on 9/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI
import Foundation

#if DEBUG

// MARK: - Preview Doubles

final class PreviewAuthService: AuthService {
    // Control preview outcomes
    var captchaMode: Mode = .success
    var signupMode: Mode = .success
    var changePasswordMode: Mode = .success
    
    enum Mode {
        case success
        case unauthorized
        case invalidInput(String)
        case rateLimited(Int?)
        case network
        case server(Int, String?)
        case accountDisabled
    }
    
    func fetchSignupCaptcha(username: String, backgroundHex: String) async throws -> SignupCaptcha {
        switch captchaMode {
        case .success:
            return SignupCaptcha(token: "preview-captcha-token", imageBase64: PreviewAuthService.sampleCaptchaBase64)
            
        case .unauthorized:
            throw AuthError.unauthorized
            
        case .invalidInput(let msg):
            throw AuthError.invalidInput(message: msg)
            
        case .rateLimited(let seconds):
            throw AuthError.rateLimited(retryAfterSeconds: seconds)
            
        case .network:
            throw AuthError.network(underlying: URLError(.notConnectedToInternet))
            
        case .server(let status, let msg):
            throw AuthError.server(status: status, message: msg)
            
        case .accountDisabled:
            throw AuthError.accountDisabled
        }
    }
    
    func submitSignup(_ req: SignupRequest, captchaText: String, token: String) async throws -> AuthSession {
        switch signupMode {
        case .success:
            return AuthSession(token: "preview-auth-token")
            
        case .unauthorized:
            throw AuthError.unauthorized
            
        case .invalidInput(let msg):
            throw AuthError.invalidInput(message: msg)
            
        case .rateLimited(let seconds):
            throw AuthError.rateLimited(retryAfterSeconds: seconds)
            
        case .network:
            throw AuthError.network(underlying: URLError(.notConnectedToInternet))
            
        case .server(let status, let msg):
            throw AuthError.server(status: status, message: msg)
            
        case .accountDisabled:
            throw AuthError.accountDisabled
        }
    }

    func signup(_ req: SignupRequest) async throws -> AuthSession {
        switch signupMode {
        case .success:
            return AuthSession(token: "preview-token")
            
        case .unauthorized:
            throw AuthError.unauthorized
            
        case .invalidInput(let msg):
            throw AuthError.invalidInput(message: msg)
            
        case .rateLimited(let seconds):
            throw AuthError.rateLimited(retryAfterSeconds: seconds)
            
        case .network:
            throw AuthError.network(underlying: URLError(.notConnectedToInternet))
            
        case .server(let status, let msg):
            throw AuthError.server(status: status, message: msg)
            
        case .accountDisabled:
            throw AuthError.accountDisabled
        }
    }
    
    func changePassword(_ req: ChangePasswordRequest) async throws {
        switch changePasswordMode {
        case .success:
            return
            
        case .unauthorized:
            throw AuthError.unauthorized
            
        case .invalidInput(let msg):
            throw AuthError.invalidInput(message: msg)
            
        case .rateLimited(let seconds):
            throw AuthError.rateLimited(retryAfterSeconds: seconds)
            
        case .network:
            throw AuthError.network(underlying: URLError(.notConnectedToInternet))
            
        case .server(let status, let msg):
            throw AuthError.server(status: status, message: msg)
            
        case .accountDisabled:
            throw AuthError.accountDisabled
        }
    }
    
    static let sampleCaptchaBase64 = "iVBORw0KGgoAAAANSUhEUgAAAKAAAAA8CAIAAABuCSZCAAAGYElEQVR4nO2bXUgUXRjHZ2u3j8k0d8iFLJLEhBUE8esiUGLDJMhEaQWVhKwW0VtR8MJEK+gi9EKpFDK1QmpJJWmXzJJITBOSWF3RAtFFZfFjHRZsdWffi4XYzllnZmf2jLyH87t85jn/88z+Z86ZOWdW5fP5KAK+HNjvAghoIQZjDjEYc4jBmEMMxhxiMOYQgzGHGIw5xGDMIQZjDjEYc4jBmEMMxhxiMOaoGxoa9rsGAkJUZD8Yb8gQjTnEYMwhBmMOMRhz1Ep29u7du6tXrwY9ZLfbExMTBRXy8/P7+/v3OqpSqWiapmlap9MlJCSkpKRcuXIlNTWVX3N9fX36XxwOB5BjMpkeP34sWB5FUV6vd3x8/OPHj1NTUzabzel0ulwujUYTFRV19uxZf0m5ublqtVK/vE9BCgsL9yqjtrZWjMK1a9dCPcH09PQvX77waEZFRQmKmEwmwdrGxsbu3LkTHR0tqHbq1KmXL1+K/dXkoZzBa2trhw4d2uucY2NjvV6voIgEgymK0mg0ZrN5L82wGOx0OkOtymQycRwX8u8YIsrNwa9evfJ4PHsddTgcQ0NDiLre2dkpLy9fXV1FpC+NJ0+e3L9/H3Uvyhnc2dkpM0EOm5ubL168QKcvjaampuXlZaRdKGTw9PT09+/f+XP6+vpcLpcEcafTGThUDgwMJCQkwGmfPn0K2pxhmAsXLty6devRo0cWi2VhYUHwuYwfrVZbUVFhsViWlpY8Hs/i4mJ7e/vp06fhzO3tbbPZLKcvYVDPAX6qq6uBfg0GQ3x8PBB8+vQpv07QOTjQYD8/fvyA01JTU0VWCxsscg7WarUPHz5kWRZOWF1dPXfuHFzVjRs3RFYlDSXuYK/X29PTAwRLS0tLSkqAYLhG6eTkZI1GAwQPHz4cFvGgqFSq0tJSu91eXV0dEREBJ8TExDQ1NcFx1E8GShhstVqBmebIkSMFBQWwwaOjo3Nzc/J7/Pnz587ODhCEB4wwwjBMd3f3yZMneXKysrLgINLLjlLG4OfPnwORvLy8yMjI8+fPp6WlCSaHxNra2uDgoNFohA+VlZXJUZbP9vY2HExKSkLbK9IJwOfzbWxswBdpf3+//2hzczNw6MyZMzwvxNLegymKMhqN4muWMAeLoaOjAy5sYmJCvjIPyA1ua2sDTkmr1Xo8Hv/RlZWVgwcPAgkfPnzYS02CwWq1uqqq6s+fP+JrRmEwy7LwHHH58mWZsoIgH6Lh5yaj0fj3CUin0126dAlIkDlKA+j1eoPBwLOIpgC7u7tlZWW/fv0KDDIM097ejrxvpJfPzMwM3COwMtzV1QUk0DS9tbUVVFDyEJ2Xl+d2u0WWHd47mGVZuOyjR49+/fpVsqZ40BpcU1MDnFhcXBywAMuyLE3TQFpHR0dQQckGUxRVVFQksuwwGjw3Nwc/RtE0PTQ0JE0wVBAO0RzHwa+/xcXFKpUqMBIREQHbFtILceBCh8fj+f37d0tLC7yr09vbOzIyIl5WPoODg2lpaTabLTAYHR1ttVoNBoNCRaC7diwWi5zC5ufnYU2RK1k+n+/z589w5s2bN8VULv8O5jiuoaEBuJQpioqLi7PZbCFJyQThHSxzWUrmo1Z2dnZMTAwQnJyclKMpkq2trfz8/Pr6et+/X6zm5ORMTk7q9XoFavgLKoNdLldfX58cha6uLp+8T3rh5uvr63IExTAzM5ORkTEwMADEa2tr379/r9VqURcAgMrg3t7eoAs34llYWAg6zIpkeHgY3oQ/ceKEnJIEefv2bWZm5uzsbGDw+PHjZrP5wYMHBw7swxdwqLoMy7aBBBG322232+/duxf08yB0y9Ecx9XV1RUWFrIsGxhPTEz89u1bQUEBon6FQTGxA5ewn8bGRv5Wt2/fBpocO3YM2HqT85pEUdSzZ8/gfjMzMyVIVVZWBooEfeMXA8Mwsn9vPpDcwUGfj65fv87fCk5wu91v3rwJV1V6vb64uDhcav8Xwm8wx3Hd3d1AMDk5WfCr2IsXLzIMAwTDtUMcGxv7+vXr/V2w3BdUd+/e3e8aCCgJ+6APb+NTFDU7OyumrdVqhdv6Xyj9CM7B/m/fdTpdSkpKSUlJa2urw+Hg7xTvOZj8fRRzyH+TMIcYjDnEYMwhBmMOMRhziMGYQwzGHGIw5hCDMYcYjDnEYMwhBmPOf7i6FMrrUHkUAAAAAElFTkSuQmCC"
}

public final class PreviewSessionStore: SessionStore, @unchecked Sendable {
    public private(set) var current: AuthSession?
    public init() {}
    public func set(_ session: AuthSession?) async { current = session }
    public func clear() async { current = nil }
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
        vm.displayName = "Example User"
        vm.username = "ExampleUser"
        vm.email = "user@example.com"
        vm.password = "CorrectHorseBattery"
        vm.confirmPassword = "CorrectHorseBattery"
        
    case .submitting:
        vm.displayName = "Example User"
        vm.username = "ExampleUser"
        vm.email = "user@example.com"
        vm.password = "CorrectHorseBattery"
        vm.confirmPassword = "CorrectHorseBattery"
        vm.isSubmitting = true
        
    case .errorUnauthorized:
        auth.signupMode = .unauthorized
        vm.displayName = "Example User"
        vm.username = "ExampleUser"
        vm.email = "user@example.com"
        vm.password = "WrongPass!"
        vm.confirmPassword = "WrongPass!"
        vm.errorMessage = "Unauthorized. Check your credentials."
        
    case .errorServer(let msg):
        auth.signupMode = .server(500, msg)
        vm.displayName = "Example User"
        vm.username = "ExampleUser"
        vm.email = "user@example.com"
        vm.password = "CorrectHorseBattery"
        vm.confirmPassword = "CorrectHorseBattery"
        vm.errorMessage = msg
        
    case .passwordMismatch:
        vm.displayName = "Example User"
        vm.username = "ExampleUser"
        vm.email = "user@example.com"
        vm.password = "CorrectHorseBattery"
        vm.confirmPassword = "DifferentPassword"
        vm.errorMessage = "Passwords do not match."
        
    case .invalidEmail:
        vm.displayName = "Example User"
        vm.username = "ExampleUser"
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
      auth.changePasswordMode = .server(500, msg)
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

#endif // DEBUG
