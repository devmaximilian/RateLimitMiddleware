import Foundation

extension TimeInterval {
    public static func seconds(_ value: UInt64) -> TimeInterval {
        return TimeInterval(value)
    }
    public static func minutes(_ value: UInt64) -> TimeInterval {
        return seconds(value * 60)
    }
    public static func hours(_ value: UInt64) -> TimeInterval {
        return minutes(value * 60)
    }
    public static func days(_ value: UInt64) -> TimeInterval {
        return hours(value * 24)
    }
}
