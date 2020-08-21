import XCTVapor
@testable import RateLimitMiddleware

final class RateLimitMiddlewareTests: XCTestCase {
    private var app: Application!
    
    override func setUp() {
        app = Application(.testing)
        
        try! configure(app)
    }
    
    override func tearDown() {
        app.shutdown()
    }
    
    private func configure(_ app: Application) throws {
        app.middleware.use(RateLimitMiddleware(limit: 1, refreshInterval: 1, autoPurge: false))
        // register routes
        try routes(app)
    }
    
    private func routes(_ app: Application) throws {
        app.get { req in
            return "Hello, world!"
        }
    }

    
    // MARK: Tests
    
    func testRateLimit() throws {
        // Request should return status code 200
        try app.test(.GET, "/") { res in
            XCTAssertEqual(res.status.code, 200)
        }
        
        // Request should return status code 429
        try app.test(.GET, "/") { res in
            XCTAssertEqual(res.status.code, 429)
        }
        
        sleep(1)
        
        // Request should return status code 200
        try app.test(.GET, "/") { res in
            XCTAssertEqual(res.status.code, 200)
        }
    }

    static var allTests = [
        ("testRateLimit", testRateLimit),
    ]
}
