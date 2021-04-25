import Foundation

public protocol Asset: Hashable {
    var name: String { get set }
    var path: [String] { get set }
    var platform: Platform? { get }
}

