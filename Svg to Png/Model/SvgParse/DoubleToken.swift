
import Foundation

struct DoubleToken {
    var value: Double
    var isPercentage: Bool
    
    init(value: Double = 0, isPercentage: Bool = false) {
        self.value = value
        self.isPercentage = isPercentage
    }
}

extension String {
    func tokenize() -> [DoubleToken] {
        var result = [DoubleToken]()
        
        let source = self.split(maxSplits: Int.max, omittingEmptySubsequences: true) {
            return " \t\n".contains($0)
        }
        
        for str in source {
            switch str {
            case "px":
                continue
            case "%":
                let last = result.count - 1
                guard last >= 0 else { continue }
                result[last].isPercentage = true
            default:
                if str.hasSuffix("px") {
                    let work = str.replacingOccurrences(of: "px", with: "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    guard let double = Double(work) else { continue }
                    result.append(DoubleToken(value: double))
                    continue
                }
                
                if str.hasSuffix("%") {
                    let work = str.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    guard let double = Double(work) else { continue }
                    result.append(DoubleToken(value: double, isPercentage: true))
                    continue
                }
                
                if let double = Double(str) {
                    result.append(DoubleToken(value: double))
                } else {
                    // print("barf") -- don't know what the heck this is
                    continue
                }
                
            }
        }
        return result
    }
}
