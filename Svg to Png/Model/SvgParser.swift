
import Foundation

public class SvgParser: XMLParser {
    // MARK: - Public Variables

    public var error: Error?
    public var completionBlock: ((SvgParser) -> Void)?

    // MARK: - constuctors

    public convenience init?(svgURL: URL, completion: ((SvgParser) -> Void)? = nil) {
        do {
            let urlData = try Data(contentsOf: svgURL)
            self.init(SVGData: urlData)
        } catch {
            debugLog(error)
            return nil
        }
    }

    public required init(SVGData: Data, completion: ((SvgParser) -> Void)? = nil) {
        super.init(data: SVGData)
        delegate = self
        completionBlock = completion
    }
}

// MARK: - XMLParserDelegate

extension SvgParser: XMLParserDelegate {
    open func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
//
        guard elementName == "svg" else { return }
        let attrWidth = attributeDict["width"]
        let attrHeight = attributeDict["height"]
        let attrViewBox = attributeDict["viewBox"]
        
        guard (attrWidth != nil || attrHeight != nil || attrViewBox != nil) else { return }
        debugLog(attrWidth as Any, attrHeight as Any, attrViewBox as Any)
        
        abortParsing()
    }
    
    public func parserDidEndDocument(_ parser: XMLParser) {
        debugLog()
    }
    
    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        debugLog("Parsing Error", parseError)
    }
}
