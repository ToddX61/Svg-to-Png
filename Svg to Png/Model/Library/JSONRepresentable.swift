
import Foundation

struct JSONRepresentable<T>: Codable where T: Codable {
    private var _obj: T?

    init(object: T) {
        _obj = object
    }

    init?(data: Data) {
        guard let obj = try? JSONDecoder().decode(T.self, from: data) else { return nil }
        _obj = obj
    }

    init?(json: String, using encoding: String.Encoding = .utf8) {
        guard let data = json.data(using: encoding) else { return nil }
        self.init(data: data)
    }

    init?(filename: String) {
        let url = URL(fileURLWithPath: filename)
        guard let data = try? Data(contentsOf: url, options: NSData.ReadingOptions()) else { return nil }
        self.init(data: data)
    }

    var obj: T {
        get { return _obj! }
        set { _obj = newValue }
    }

    var jsonData: Data? {
        return try? JSONEncoder().encode(obj)
    }

    var json: String? {
        guard let data = self.jsonData else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
