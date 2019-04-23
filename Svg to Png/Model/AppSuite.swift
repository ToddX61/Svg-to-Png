
import Foundation

struct AppSuite {
    static let Name = "biz.denlinger.svgtopng"
    static func userDefaults() -> UserDefaults {
        return UserDefaults(suiteName: Name)!
    }
}
