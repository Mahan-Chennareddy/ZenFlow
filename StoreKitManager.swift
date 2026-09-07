import Foundation
import StoreKit

class StoreKitManager: ObservableObject {
    @Published var isPro: Bool = false
    
    private let productID = "com.zenflow.subscription.pro"
    
    func purchase() {
        // In a real app, use StoreKit 2 transaction flow
        // For now, we simulate a successful purchase for the prototype
        self.isPro = true
    }
    
    func fetchProducts() async -> [Product] {
        // Mock product fetch
        return []
    }
}
