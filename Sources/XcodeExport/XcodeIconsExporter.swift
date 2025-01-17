import Foundation
import FigmaExportCore

final public class XcodeIconsExporter: XcodeImagesExporterBase {

    public func export(icons: [ImagePack], append: Bool, assetsMaintainDirectories: Bool? = nil) throws -> [FileContents] {
        // Generate metadata (Assets.xcassets/Icons/Contents.json)
        let contentsFile = XcodeEmptyContents().makeFileContents(to: output.assetsFolderURL)

        // Generate assets
        let assetsFolderURL = output.assetsFolderURL
        let preservesVectorRepresentation = output.preservesVectorRepresentation
        let nonTemplate = output.nonTemplate
        let renderMode = output.renderMode ?? .template

        let imageAssetsFiles = try icons.flatMap { imagePack -> [FileContents] in
            let preservesVector = preservesVectorRepresentation?.first(where: { $0 == imagePack.name }) != nil
            let nonTemplateImage = nonTemplate?.first(where: { $0 == imagePack.name }) != nil
            return try imagePack.makeFileContents(to: assetsFolderURL, preservesVector: preservesVector || imagePack.preservesVectorRepresentation, assetsMaintainDirectories: assetsMaintainDirectories, renderMode: (nonTemplateImage || imagePack.nonTemplate) ? .original : renderMode)
        }

        // Generate extensions
        let imageNames = icons.map { $0.name }
        let extensionFiles = try generateExtensions(names: imageNames, append: append)

        return [contentsFile] + imageAssetsFiles + extensionFiles
    }
    
}
