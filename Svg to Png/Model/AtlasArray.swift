
import Foundation

class AtlasArray: CustomStringConvertible {
    var atlases: [Atlas] 

    required init() { atlases = [Atlas]() }
    init(atlases: [Atlas]) { self.atlases = atlases }

    var description: String { return "\(atlases)" }
}
