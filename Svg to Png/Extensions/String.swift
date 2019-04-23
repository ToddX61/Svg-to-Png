
import Foundation

extension String {
    func transformEnumValue() -> String {
        return String.transformEnumValue(self)
    }

    // ideal for enumeration values:
    // for example: enum ErrorType.fileNotFound
    //    will display "File Not Found
    static func transformEnumValue(_ s: String) -> String {
        var result = ""

        for (idx, c) in s.enumerated() {
            if !(c >= "a" && c <= "z"), c != " " {
                if idx != 0 {
                    result += " "
                }
            }

            result += idx == 0 ? "\(c)".uppercased() : "\(c)"
        }

        return result
    }

    var abbreviatingWithTildeInPath: String {
        let result = NSString(string: self)
        return result.abbreviatingWithTildeInPath
    }
    
    var expandingTildeInPath: String {
        if #available(OSX 10.12, *) {
            return self.replacingOccurrences(of: "~", with: FileManager.default.homeDirectoryForCurrentUser.path)
        } else {
            return self.replacingOccurrences(of: "~", with: NSHomeDirectory())
        }
    }

//    returns a string that is trim, and where multiple sequential occurences of whitespace or replaced with a single whitespace character

    var reducingWhiteSpace: String {
        let string = trimmingCharacters(in: .whitespacesAndNewlines)
        var previousWhitespace = false
        var result = ""

        for character in string {
            if " \t\n".contains(character) {
                if previousWhitespace == true {
                    continue
                } else {
                    previousWhitespace = true
                }

            } else {
                previousWhitespace = false
            }

            result.append(character)
        }

        return result
    }
}
