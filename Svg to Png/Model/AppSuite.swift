
import Foundation

struct AppSuite {
    static let Name = "biz.denlinger.svgtopng"
    static func defaultsCreate() -> UserDefaults {
        return UserDefaults(suiteName: Name)!
    }
}
