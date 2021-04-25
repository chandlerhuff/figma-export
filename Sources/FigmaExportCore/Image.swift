import Foundation

public enum Scale {
    case all
    case individual(_ value: Double)

    public var value: Double {
        switch self {
        case .all:
            return 1
        case .individual(let value):
            return value
        }
    }
}

public struct Image: Asset {

    public var name: String
    public var path: [String]
    public let scale: Scale
    public let format: String
    public let url: URL
    public let idiom: String?
    public let preservesVectorRepresentation: Bool

    public var platform: Platform?

    public init(name: String, path: [String] = [], scale: Scale = .all, platform: Platform? = nil, idiom: String? = nil, preservesVectorRepresentation: Bool = false, url: URL, format: String) {
        self.name = name
        self.path = path
        self.scale = scale
        self.platform = platform
        self.url = url
        self.idiom = idiom
        self.preservesVectorRepresentation = preservesVectorRepresentation
        self.format = format
    }

    // MARK: Hashable

    public static func == (lhs: Image, rhs: Image) -> Bool {
        return lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

public struct ImagePack: Asset {
    public var images: [Image]
    public var name: String {
        didSet {
            images = images.map { image -> Image in
                var newImage = image
                newImage.name = name
                return newImage
            }
        }
    }
    public var path: [String]
    public var platform: Platform?
    public let preservesVectorRepresentation: Bool

    public init(name: String, path: [String] = [], images: [Image], platform: Platform? = nil) {
        self.name = name
        self.path = path
        self.images = images
        self.platform = platform
        preservesVectorRepresentation = images.first(where: { $0.preservesVectorRepresentation })?.preservesVectorRepresentation ?? false
    }

    public init(image: Image, platform: Platform? = nil) {
        self.name = image.name
        self.path = image.path
        self.images = [image]
        self.platform = platform
        preservesVectorRepresentation = image.preservesVectorRepresentation
    }

}
