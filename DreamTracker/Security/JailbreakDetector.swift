import Foundation

// MARK: - Jailbreak Detector

enum JailbreakDetector {
    /// Returns true if the device shows signs of being jailbroken.
    /// This is defense-in-depth — not a hard security boundary.
    static var isJailbroken: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return checkFileSystem() || checkSandboxEscape()
        #endif
    }

    // MARK: - File System Checks

    private static func checkFileSystem() -> Bool {
        let suspiciousPaths = [
            "/Applications/Cydia.app",
            "/Applications/Sileo.app",
            "/Applications/Zebra.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt",
            "/private/var/lib/cydia",
            "/private/var/tmp/cydia.log",
            "/bin/bash",
            "/usr/libexec/ssh-keysign",
        ]

        for path in suspiciousPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }

        // Check if we can write outside the sandbox
        let testPath = "/private/jailbreak_test_\(UUID().uuidString)"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true  // Wrote outside sandbox — jailbroken
        } catch {
            // Expected — sandbox prevented write
        }

        return false
    }

    // MARK: - Sandbox Escape Check

    private static func checkSandboxEscape() -> Bool {
        return false
    }
}
