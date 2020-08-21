import Foundation
import Vapor

/// A simple rate limit middleware
public struct RateLimitMiddleware: Middleware {
    private let cache: MemoryCache<Peer>
    private let limit: UInt64
    private let interval: Double
    private let autoPurge: AutoPurge
    
    /// Creates a new instance of `RateLimitMiddleware`
    /// - Parameters:
    ///   - limit: Number of requests a client is allowed to perform within the `refreshInterval`.
    ///   - refreshInterval: Time interval until `limit` is reset for a client.
    ///   - autoPurge: Enable auto purging cache.
    public init(limit: UInt64 = 60,
                refreshInterval: TimeInterval,
                autoPurge: Bool = false) {
        self.cache = MemoryCache<Peer>()
        self.limit = limit
        self.interval = refreshInterval
        self.autoPurge = AutoPurge(enabled: autoPurge)
    }
    
    /// Called with each `Request` that passes through this middleware.
    /// - parameters:
    ///     - request: The incoming `Request`.
    ///     - next: Next `Responder` in the chain, potentially another middleware or the main router.
    /// - returns: An asynchronous `Response`.
    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        let id = (request.remoteAddress?.description ?? "") + request.url.description
        
        var peer = cache[key: id] ?? Peer(limit: limit, refreshInterval: interval)
        
        // Reset peer
        if peer.expired {
            peer = Peer(
                limit: limit,
                refreshInterval: interval
            )
        }
        
        // Defer peer update
        defer {
            self.cache[key: id] = peer
            
            // Perform auto purge
            purge: if autoPurge.canRun {
                autoPurge.updateLastRun()
                self.cache.all.filter {
                    $0.value.expired
                }.forEach {
                    self.cache[key: $0.key] = nil
                }
            }
        }
        
        // Check if rate limit has been hit
        guard peer.remaining > 0 else {
            return request.eventLoop.makeFailedFuture(
                Abort(.tooManyRequests, headers: [
                    "Rate-Limit-Limit": self.limit.description,
                    "Rate-Limit-Remaining": peer.remaining.description,
                    "Rate-Limit-Reset": peer.reset.description
                ])
            )
        }
        peer.remaining -= 1
        
        return next.respond(to: request).map { response in
            response.headers.replaceOrAdd(name: "Rate-Limit-Limit", value: self.limit.description)
            response.headers.replaceOrAdd(name: "Rate-Limit-Remaining", value: peer.remaining.description)
            response.headers.replaceOrAdd(name: "Rate-Limit-Reset", value: peer.reset.description)
            return response
        }
    }
}

// MARK: MemoryCache

extension RateLimitMiddleware {
    fileprivate final class MemoryCache<Value> {
        private var store: [String: Value]
        
        fileprivate init() {
            self.store = [:]
        }

        fileprivate var all: [(key: String, value: Value)] {
            return store.map { $0 }
        }
        
        fileprivate subscript(key key: String) -> Value? {
            get { return self.store[key] }
            set { self.store[key] = newValue }
        }
    }
}

// MARK: AutoPurge

extension RateLimitMiddleware {
    fileprivate final class AutoPurge {
        fileprivate let enabled: Bool
        fileprivate var lastRun: Date = .init()
        fileprivate let interval: TimeInterval
        
        fileprivate var canRun: Bool {
            return lastRun.addingTimeInterval(interval) < Date()
        }
        
        fileprivate init(enabled: Bool = true, interval: TimeInterval = 43200) {
            self.enabled = enabled
            self.lastRun = .init()
            self.interval = interval
        }
        
        fileprivate func updateLastRun() {
            self.lastRun = .init()
        }
    }
}
