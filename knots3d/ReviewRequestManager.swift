import Foundation
import StoreKit

class ReviewRequestManager {
    static let shared = ReviewRequestManager()
    
    private let reviewRequestKey = "lastReviewRequestDate"
    private let reviewRequestInterval: TimeInterval = 7 * 24 * 60 * 60 // 7天
    
    private init() {}
    
    // 请求用户评分
    func requestReviewIfAppropriate() {
        guard shouldRequestReview() else {
            return
        }
        
        // 记录本次请求时间
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: reviewRequestKey)
        
        // 请求评分
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        }
    }
    
    // 判断是否应该显示评分请求
    private func shouldRequestReview() -> Bool {
        let lastRequestTime = UserDefaults.standard.double(forKey: reviewRequestKey)
        
        // 如果从未请求过，则可以请求
        if lastRequestTime == 0 {
            return true
        }
        
        // 检查距离上次请求是否超过7天
        let now = Date().timeIntervalSince1970
        return now - lastRequestTime > reviewRequestInterval
    }
}