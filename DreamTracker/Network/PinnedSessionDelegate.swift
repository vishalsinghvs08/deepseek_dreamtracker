import Foundation
import CryptoKit
import Security

public final class PinnedSessionDelegate: NSObject, URLSessionDelegate {
    public let pinnedHashes: Set<String>
    
    public init(pinnedHashes: Set<String>) {
        self.pinnedHashes = pinnedHashes
    }
    
    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        // Validate server trust first
        var error: CFError?
        guard SecTrustEvaluateWithError(serverTrust, &error) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Extract leaf certificate
        guard let certificates = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
              let leafCertificate = certificates.first,
              let publicKey = SecCertificateCopyKey(leafCertificate) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Extract public key representation
        var keyError: Unmanaged<CFError>?
        guard let keyData = SecKeyCopyExternalRepresentation(publicKey, &keyError) as Data? else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Extract Subject Public Key Info (SPKI) representation of the public key
        guard let attributes = SecKeyCopyAttributes(publicKey) as? [CFString: Any],
              let keyType = attributes[kSecAttrKeyType] as? String else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        let keySize = (attributes[kSecAttrKeySizeInBits] as? Int) ?? (attributes[kSecAttrKeySizeInBits] as? NSNumber)?.intValue ?? 0
        
        var spkiData = Data()
        if keyType == (kSecAttrKeyTypeECSECPrimeRandom as String) {
            let ecHeader: [UInt8] = [
                0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01, 0x06, 0x08,
                0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, 0x03, 0x42, 0x00
            ]
            spkiData.append(contentsOf: ecHeader)
        } else if keyType == (kSecAttrKeyTypeRSA as String) && keySize == 2048 {
            let rsaHeader: [UInt8] = [
                0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01,
                0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
            ]
            spkiData.append(contentsOf: rsaHeader)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        spkiData.append(keyData)
        
        // Calculate SHA-256 Hash of SPKI representation
        let hash = SHA256.hash(data: spkiData)
        let hashBase64 = Data(hash).base64EncodedString()
        
        // Compare against pins
        if pinnedHashes.contains(hashBase64) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
