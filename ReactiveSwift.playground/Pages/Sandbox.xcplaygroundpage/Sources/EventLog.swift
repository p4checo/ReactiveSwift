import Foundation

public func feedbackEventLog(identifier: String, event: String, fileName: String, functionName: String, lineNumber: Int) {
    print("[\(identifier)] \(event)")
}
