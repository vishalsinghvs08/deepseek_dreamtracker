import StoreKit
import SwiftUI

// MARK: - Store Manager

@MainActor
final class StoreManager: ObservableObject {
    @Published var isPro = false
    @Published var product: Product?
    @Published var purchaseInProgress = false
    @Published var purchaseError: String?

    private let productID = "com.dreamtracker.pro"
    private var updateListenerTask: Task<Void, Error>?
    private var didSetup = false

    nonisolated init() {
        // Defer all async work to avoid MainActor deadlock at app launch
    }

    func setupIfNeeded() {
        guard !didSetup else { return }
        didSetup = true
        updateListenerTask = listenForTransactions()
        Task {
            await loadProduct()
            await checkEntitlement()
        }
    }

    func teardown() {
        updateListenerTask?.cancel()
        updateListenerTask = nil
        didSetup = false
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product Loading

    private func loadProduct() async {
        do {
            let products = try await Product.products(for: [productID])
            product = products.first
        } catch {
            print("StoreKit: Failed to load product: \(error)")
        }
    }

    // MARK: - Entitlement Check

    func checkEntitlement() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == productID {
                isPro = true
                break
            }
        }
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product = product else {
            purchaseError = "Product not available. Try again later."
            return
        }

        purchaseInProgress = true
        purchaseError = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    purchaseError = "Purchase verification failed."
                    purchaseInProgress = false
                    return
                }
                isPro = true
                await transaction.finish()

            case .userCancelled:
                break

            case .pending:
                purchaseError = "Purchase is pending approval."

            @unknown default:
                purchaseError = "Unknown purchase result."
            }
        } catch {
            purchaseError = error.localizedDescription
        }

        purchaseInProgress = false
    }

    // MARK: - Restore

    func restorePurchases() async {
        purchaseInProgress = true
        purchaseError = nil

        do {
            try await AppStore.sync()
            await checkEntitlement()
            if !isPro {
                purchaseError = "No previous purchase found."
            }
        } catch {
            purchaseError = error.localizedDescription
        }

        purchaseInProgress = false
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                guard let self else { break }
                if transaction.productID == self.productID {
                    await MainActor.run { self.isPro = true }
                }
                await transaction.finish()
            }
        }
    }

    // MARK: - Formatted Price

    var formattedPrice: String {
        product?.displayPrice ?? "$2.99"
    }
}
