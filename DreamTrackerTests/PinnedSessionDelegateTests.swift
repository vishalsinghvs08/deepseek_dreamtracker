import XCTest
import Security
import CryptoKit
@testable import DreamTracker

final class PinnedSessionDelegateTests: XCTestCase {
    private var certificate: SecCertificate!
    private var correctHash: String!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let bundle = Bundle(for: PinnedSessionDelegateTests.self)
        guard let certURL = bundle.url(forResource: "cert", withExtension: "der") else {
            XCTFail("Missing cert.der in test bundle")
            return
        }
        
        let certData = try Data(contentsOf: certURL)
        guard let cert = SecCertificateCreateWithData(nil, certData as CFData) else {
            XCTFail("Failed to create certificate from DER data")
            return
        }
        self.certificate = cert
        
        // Correct SPKI SHA-256 base64 hash of cert.der
        self.correctHash = "7VsnuKD8Ynoi3DK4VDNLtqU2cTm3vpvI/LYmvho/5Dc="
    }
    
    func testPinningSuccess() throws {
        let delegate = PinnedSessionDelegate(pinnedHashes: [correctHash])
        let trust = try createMockTrust()
        let challenge = createMockChallenge(trust: trust)
        
        let expectation = self.expectation(description: "Auth challenge completed")
        delegate.urlSession(URLSession.shared, didReceive: challenge) { disposition, credential in
            XCTAssertEqual(disposition, .useCredential)
            XCTAssertNotNil(credential)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testPinningFailure() throws {
        let delegate = PinnedSessionDelegate(pinnedHashes: ["invalid-pin-hash-value"])
        let trust = try createMockTrust()
        let challenge = createMockChallenge(trust: trust)
        
        let expectation = self.expectation(description: "Auth challenge completed")
        delegate.urlSession(URLSession.shared, didReceive: challenge) { disposition, credential in
            XCTAssertEqual(disposition, .cancelAuthenticationChallenge)
            XCTAssertNil(credential)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testPinningTrustEvaluationFailure() throws {
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        let status = SecTrustCreateWithCertificates([certificate] as CFArray, policy, &trust)
        guard status == errSecSuccess, let trust = trust else {
            throw SecurityError.keychainError(status: status)
        }
        
        let challenge = createMockChallenge(trust: trust)
        let delegate = PinnedSessionDelegate(pinnedHashes: [correctHash])
        
        let expectation = self.expectation(description: "Auth challenge completed")
        delegate.urlSession(URLSession.shared, didReceive: challenge) { disposition, credential in
            XCTAssertEqual(disposition, .cancelAuthenticationChallenge)
            XCTAssertNil(credential)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testNonServerTrustChallenge() throws {
        let delegate = PinnedSessionDelegate(pinnedHashes: [correctHash])
        let trust = try createMockTrust()
        
        let protectionSpace = MockProtectionSpace(
            host: "localhost",
            port: 443,
            protocol: "https",
            realm: nil,
            authenticationMethod: NSURLAuthenticationMethodHTTPBasic,
            trust: trust
        )
        let challenge = URLAuthenticationChallenge(
            protectionSpace: protectionSpace,
            proposedCredential: nil,
            previousFailureCount: 0,
            failureResponse: nil,
            error: nil,
            sender: MockChallengeSender()
        )
        
        let expectation = self.expectation(description: "Auth challenge completed")
        delegate.urlSession(URLSession.shared, didReceive: challenge) { disposition, credential in
            XCTAssertEqual(disposition, .performDefaultHandling)
            XCTAssertNil(credential)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Helpers
    
    private func createMockTrust() throws -> SecTrust {
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        let status = SecTrustCreateWithCertificates([certificate] as CFArray, policy, &trust)
        guard status == errSecSuccess, let trust = trust else {
            throw SecurityError.keychainError(status: status)
        }
        
        // Configure the trust to treat the self-signed cert as a root anchor
        let anchorStatus = SecTrustSetAnchorCertificates(trust, [certificate] as CFArray)
        XCTAssertEqual(anchorStatus, errSecSuccess)
        
        return trust
    }
    
    private func createMockChallenge(trust: SecTrust) -> URLAuthenticationChallenge {
        let protectionSpace = MockProtectionSpace(
            host: "localhost",
            port: 443,
            protocol: "https",
            realm: nil,
            authenticationMethod: NSURLAuthenticationMethodServerTrust,
            trust: trust
        )
        return URLAuthenticationChallenge(
            protectionSpace: protectionSpace,
            proposedCredential: nil,
            previousFailureCount: 0,
            failureResponse: nil,
            error: nil,
            sender: MockChallengeSender()
        )
    }
}

private final class MockProtectionSpace: URLProtectionSpace, @unchecked Sendable {
    private let mockTrust: SecTrust
    
    init(host: String, port: Int, protocol: String?, realm: String?, authenticationMethod: String?, trust: SecTrust) {
        self.mockTrust = trust
        super.init(host: host, port: port, protocol: `protocol`, realm: realm, authenticationMethod: authenticationMethod)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var serverTrust: SecTrust? {
        return mockTrust
    }
}

private final class MockChallengeSender: NSObject, URLAuthenticationChallengeSender {
    @objc func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}
    @objc func cancel(_ challenge: URLAuthenticationChallenge) {}
    @objc func rejectProtectionSpaceAndContinue(with challenge: URLAuthenticationChallenge) {}
    @objc func performDefaultHandling(for challenge: URLAuthenticationChallenge) {}
    @objc func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}
}
