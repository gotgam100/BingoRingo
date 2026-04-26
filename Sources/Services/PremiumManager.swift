import Foundation
import StoreKit

@MainActor
final class PremiumManager: ObservableObject {
    static let shared = PremiumManager()

    @Published var isPremium: Bool = false
    @Published var product: Product? = nil
    @Published var purchaseState: PurchaseState = .idle

    private let productID = "com.bingoringo.premium"
    private let purchaseDateKey = "com.bingoringo.purchaseDate"
    private var transactionListener: Task<Void, Never>?

    enum PurchaseState: Equatable {
        case idle, purchasing, failed(String)
    }

    var purchaseDate: Date? {
        UserDefaults.standard.object(forKey: purchaseDateKey) as? Date
    }

    init() {
        transactionListener = listenForTransactions()
        Task { await loadProduct() }
        Task { await refreshPurchaseStatus() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - 상품 로드

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [productID])
            self.product = products.first
        } catch {
            print("❌ StoreKit 상품 로드 실패: \(error)")
        }
    }

    // MARK: - 구매 상태 확인 (앱 시작 시)

    func refreshPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result, tx.productID == productID {
                isPremium = true
                if UserDefaults.standard.object(forKey: purchaseDateKey) == nil {
                    UserDefaults.standard.set(tx.purchaseDate, forKey: purchaseDateKey)
                }
                return
            }
        }
        isPremium = false
    }

    // MARK: - 구매

    func purchasePremium() async {
        guard let product else {
            purchaseState = .failed("상품 정보를 불러오지 못했습니다.")
            return
        }
        purchaseState = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let tx) = verification {
                    isPremium = true
                    UserDefaults.standard.set(tx.purchaseDate, forKey: purchaseDateKey)
                    await tx.finish()
                    purchaseState = .idle
                } else {
                    purchaseState = .failed("결제 검증에 실패했습니다.")
                }
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .idle
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    // MARK: - 구매 복원

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshPurchaseStatus()
        } catch {
            print("❌ 복원 실패: \(error)")
        }
    }

    // MARK: - 개발용: 프리미엄 초기화

    func refundPremium() {
        isPremium = false
        UserDefaults.standard.removeObject(forKey: purchaseDateKey)
    }

    // MARK: - 트랜잭션 리스너

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                if case .verified(let tx) = result, tx.productID == self.productID {
                    await MainActor.run {
                        self.isPremium = true
                        UserDefaults.standard.set(tx.purchaseDate, forKey: self.purchaseDateKey)
                    }
                    await tx.finish()
                }
            }
        }
    }
}
