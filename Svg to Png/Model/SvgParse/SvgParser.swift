
import Foundation

public class SvgParser: XMLParser {
    // MARK: - Public Variables
    public var completion: ((SvgParser) -> Void)?

    // these are available after parse completes
    public var error: Error?
    public var svgSize = CGSize(width: 0.0, height: 0.0)
    
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
        self.completion = completion
    }
}

// MARK: - XMLParserDelegate

extension SvgParser: XMLParserDelegate {
    fileprivate func getDouble(_ token: [DoubleToken]?, _ viewBoxValue: Double) -> Double {
        if let token = token, !token.isEmpty, token[0].value > 0 {
            if token[0].isPercentage {
                return viewBoxValue * (token[0].value * 0.01)
            } else {
                return token[0].value
            }
        }
        return viewBoxValue
    }

    open func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {
//
        guard elementName == "svg" else { return }
        let widthToken = attributeDict["width"]?.tokenize()
        let heightToken = attributeDict["height"]?.tokenize()
        let viewBoxTokens = attributeDict["viewBox"]?.tokenize()

        var viewBoxWidth = 0.0
        var viewBoxHeight = 0.0

        if let viewBox = viewBoxTokens, viewBox.count >= 4 {
            viewBoxWidth = viewBox[2].value
            viewBoxHeight = viewBox[3].value
        }

        svgSize.width = CGFloat(getDouble(widthToken, viewBoxWidth))
        svgSize.height = CGFloat(getDouble(heightToken, viewBoxHeight))

        abortParsing()
        debugLog("parse complete")
//        parserDidEndDocument(self)
    }

    public func parserDidEndDocument(_: XMLParser) {
        debugLog()
        completion?(self)
    }

    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        debugLog(parseError)
        let err = parseError as NSError
        if err.code != XMLParser.ErrorCode.delegateAbortedParseError.rawValue {
            error = parseError
        }
        parserDidEndDocument(self)
    }
}
