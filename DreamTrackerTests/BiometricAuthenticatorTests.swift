import XCTest
import LocalAuthentication
@testable import DreamTracker

final class MockLAContext: LAContextProtocol {
    var biometryType: LABiometryType = .faceID
    var canEvaluatePolicyResult: Bool = true
    var canEvaluatePolicyError: NSError? = nil
    var evaluatePolicyResult: Bool = true
    var evaluatePolicyError: Error? = nil
    
    func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        if let err = canEvaluatePolicyError {
            error?.pointee = err
            return false
        }
        return canEvaluatePolicyResult
    }
    
    func evaluatePolicy(_ policy: LAPolicy, localizedReason: String) async throws -> Bool {
        if let err = evaluatePolicyError {
            throw err
        }
        return evaluatePolicyResult
    }
}

final class BiometricAuthenticatorTests: XCTestCase {
    private var mockContext: MockLAContext!
    private var sut: BiometricAuthenticator!
    
    override func setUp() {
        super.setUp()
        mockContext = MockLAContext()
        sut = BiometricAuthenticator(contextFactory: { [weak self] in
            self?.mockContext ?? MockLAContext()
        })
    }
    
    override func tearDown() {
        sut = nil
        mockContext = nil
        super.tearDown()
    }
    
    func testCanEvaluateBiometricsSuccess() {
        mockContext.canEvaluatePolicyResult = true
        XCTAssertTrue(sut.canEvaluateBiometrics())
    }
    
    func testCanEvaluateBiometricsFailure() {
        mockContext.canEvaluatePolicyResult = false
        mockContext.canEvaluatePolicyError = NSError(
            domain: LAErrorDomain,
            code: LAError.biometryNotAvailable.rawValue,
            userInfo: [NSLocalizedDescriptionKey: "No biometrics"]
        )
        XCTAssertFalse(sut.canEvaluateBiometrics())
    }
    
    func testEvaluateBiometricsSuccess() async throws {
        mockContext.canEvaluatePolicyResult = true
        mockContext.evaluatePolicyResult = true
        
        let result = try await sut.evaluateBiometrics(reason: "Test")
        XCTAssertTrue(result)
    }
    
    func testEvaluateBiometricsCanceledThrowsUserCanceled() async {
        mockContext.canEvaluatePolicyResult = true
        mockContext.evaluatePolicyResult = false
        mockContext.evaluatePolicyError = LAError(.userCancel)
        
        do {
            _ = try await sut.evaluateBiometrics(reason: "Test")
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(error as? SecurityError, .userCanceled)
        }
    }
    
    func testEvaluateBiometricsNotAvailableThrowsBiometryNotAvailable() async {
        mockContext.canEvaluatePolicyResult = false
        mockContext.canEvaluatePolicyError = NSError(
            domain: LAErrorDomain,
            code: LAError.biometryNotAvailable.rawValue,
            userInfo: [NSLocalizedDescriptionKey: "Hardware not present"]
        )
        
        do {
            _ = try await sut.evaluateBiometrics(reason: "Test")
            XCTFail("Should have thrown error")
        } catch {
            if case .biometryNotAvailable = (error as? SecurityError) {
                // Pass
            } else {
                XCTFail("Expected biometryNotAvailable error, got \(error)")
            }
        }
    }
    
    func testBiometricTypeDetection() {
        mockContext.biometryType = .faceID
        XCTAssertEqual(sut.biometricType, .faceID)
        
        mockContext.biometryType = .touchID
        XCTAssertEqual(sut.biometricType, .touchID)
    }
}
