import AuthenticationServices
import UIKit

@MainActor
public final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let authService: AuthServiceProtocol
    private var continuation: CheckedContinuation<Void, Error>?
    private var isSigningIn = false
    
    public init(authService: AuthServiceProtocol) {
        self.authService = authService
        super.init()
    }
    
    public func startSignIn() async throws {
        guard !isSigningIn else {
            throw SecurityError.authenticationFailed(reason: "Sign in already in progress.")
        }
        isSigningIn = true

        // CRITICAL-3 fix: use withTaskCancellationHandler so cancellation (app background,
        // timeout) always resets isSigningIn and resumes the continuation cleanly.
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation

                let provider = ASAuthorizationAppleIDProvider()
                let request = provider.createRequest()
                request.requestedScopes = [.fullName, .email]

                let controller = ASAuthorizationController(authorizationRequests: [request])
                controller.delegate = self
                controller.presentationContextProvider = self
                controller.performRequests()
            }
        } onCancel: {
            // Called on actor's executor when the Task is cancelled
            Task { @MainActor in
                self.isSigningIn = false
                self.continuation?.resume(throwing: CancellationError())
                self.continuation = nil
            }
        }
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let idTokenData = credential.identityToken,
              let idToken = String(data: idTokenData, encoding: .utf8),
              let authCodeData = credential.authorizationCode,
              let authCode = String(data: authCodeData, encoding: .utf8) else {
            isSigningIn = false
            continuation?.resume(throwing: SecurityError.authenticationFailed(reason: "Invalid credentials"))
            continuation = nil
            return
        }
        
        Task {
            do {
                try await authService.loginWithApple(identityToken: idToken, authorizationCode: authCode)
                isSigningIn = false
                continuation?.resume()
                continuation = nil
            } catch {
                isSigningIn = false
                continuation?.resume(throwing: error)
                continuation = nil
            }
        }
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        isSigningIn = false
        continuation?.resume(throwing: error)
        continuation = nil
    }
    
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return UIWindow()
        }
        return window
    }
}
