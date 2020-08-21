import Foundation

internal struct Peer {
    internal let createdAt: Date
    internal let expiresAt: Date
    internal var remaining: UInt64
    
    internal var expired: Bool {
        return Date() > expiresAt
    }
    
    internal var reset: Int {
        return Int(expiresAt.timeIntervalSince1970 - Date().timeIntervalSince1970)
    }
    
    internal init(limit: UInt64, refreshInterval: TimeInterval) {
        self.createdAt = .init()
        self.expiresAt = .init(timeIntervalSinceNow: refreshInterval)
        self.remaining = limit
    }
}
