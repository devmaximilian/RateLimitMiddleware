# RateLimitMiddleware

A simple rate limit middleware for Vapor 4.

- `Rate-Limit-Limit`, `Rate-Limit-Remaining` and `Rate-Limit-Reset` headers are set for responses.
- Optional auto-purge for stale cache (off by default).g

### Installation

To use `RateLimitMiddleware`, add the following to your package manifest.

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/devmaximilian/RateLimitMiddleware.git", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "<target name>",
            dependencies: [
                .product(name: "RateLimitMiddleware", package: "RateLimitMiddleware")
            ]
        )
    ]
)
```

### Usage

```swift
/// Limits requests to 60 requests per 30 minutes 
let rateLimitMiddleware = RateLimitMiddleware(
    limit: 60,
    refreshInterval: .minutes(30)
)
```

#### Application

To enforce an application-wide rate limit per endpoint, register the middleware in `configure.swift`.

```swift
public func configure(_ app: Application) throws {
    ...
    app.middleware.use(rateLimitMiddleware)
    ...
}
```

#### RouteGroup

To enforce a rate limit per route group, register the middleware for that route specific group.

```swift
let rateLimitedGroup = app.routes.grouped(rateLimitMiddleware)

rateLimitedGroup.get("hello") { _ in
    return "Hello, world!"
}
```

alternatively

```swift
app.routes.group(rateLimitMiddleware) { builder in
    builder.get("hello") { _ in
        return "Hello, world!"
    }
}
```

#### Auto purging cache

To prevent stale cache from remaining in memory forever, there's an option to enable auto purge.

```swift
/// Limits requests to 60 requests per 30 minutes 
let rateLimitMiddleware = RateLimitMiddleware(
    limit: 60,
    refreshInterval: .minutes(30),
    autoPurge: true
)
```

As this feature _may_ impact performance (when the cache purge runs), it is off by default.
