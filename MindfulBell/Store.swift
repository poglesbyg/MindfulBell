import StoreKit

/// The one-time Pro unlock, sold as a non-consumable in-app purchase.
@MainActor
final class Store: ObservableObject {
    static let shared = Store()
    static let proProductID = "com.poglesbyg.mindfulbell.pro"

    @Published private(set) var isPro = false
    /// Nil until loaded from the App Store, or if it can't be reached.
    @Published private(set) var product: Product?
    @Published private(set) var isBusy = false
    @Published var message: String?

    private var hasCheckedEntitlements = false
    private var updates: Task<Void, Never>?

    private init() {
        if Demo.isEnabled {
            // Screenshots show the full app; StoreKit is left alone entirely.
            isPro = true
            hasCheckedEntitlements = true
            return
        }
        // Purchases made on another Mac, refunds, and Ask to Buy approvals arrive here.
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.apply(result)
            }
        }
        Task {
            await refreshEntitlement()
            await loadProduct()
        }
    }

    /// Whether Pro is unlocked, checking with StoreKit first if that hasn't happened yet.
    /// App Intents use this because they can run before the launch-time check finishes.
    func checkPro() async -> Bool {
        if !hasCheckedEntitlements { await refreshEntitlement() }
        return isPro
    }

    func loadProduct() async {
        guard product == nil, !Demo.isEnabled else { return }
        do {
            product = try await Product.products(for: [Self.proProductID]).first
        } catch {
            NSLog("MindfulBell: could not load products: \(error)")
        }
    }

    /// Handles the outcome of SwiftUI's `purchase` action.
    func handle(_ result: Product.PurchaseResult) async {
        switch result {
        case .success(let verification):
            await apply(verification)
            if !isPro { message = "The purchase couldn't be verified. Try Restore Purchases." }
        case .pending:
            message = "Your purchase is waiting for approval."
        case .userCancelled:
            break
        @unknown default:
            break
        }
    }

    func restore() async {
        isBusy = true
        defer { isBusy = false }
        do {
            try await AppStore.sync()
            await refreshEntitlement()
            message = isPro ? nil : "No Pro purchase was found for this Apple Account."
        } catch StoreKitError.userCancelled {
            // Nothing to report.
        } catch {
            message = error.localizedDescription
        }
    }

    private func refreshEntitlement() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.proProductID,
               transaction.revocationDate == nil {
                owned = true
            }
        }
        isPro = owned
        hasCheckedEntitlements = true
    }

    private func apply(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        if transaction.productID == Self.proProductID {
            isPro = transaction.revocationDate == nil
        }
        await transaction.finish()
    }
}
