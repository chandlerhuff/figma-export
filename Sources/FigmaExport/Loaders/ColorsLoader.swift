import FigmaAPI
import FigmaExportCore

/// Loads colors from Figma
final class ColorsLoader {
    
    private let client: Client
    private let figmaParams: Params.Figma
    private let colorParams: Params.Common.Colors?

    init(client: Client, figmaParams: Params.Figma, colorParams: Params.Common.Colors?) {
        self.client = client
        self.figmaParams = figmaParams
        self.colorParams = colorParams
    }
    
    func load() throws -> (light: [Color], dark: [Color]?) {
        if let useSingleFile = colorParams?.useSingleFile, useSingleFile {
            return try loadColorsFromSingleFile()
        } else {
            return try loadColorsFromLightAndDarkFile()
        }
    }

    private func loadColorsFromLightAndDarkFile() throws -> (light: [Color], dark: [Color]?) {
        let lightColors = try loadColors(fileId: figmaParams.lightFileId)
        let darkColors = try figmaParams.darkFileId.map { try loadColors(fileId: $0) }
        return (lightColors, darkColors)
    }

    private func loadColorsFromSingleFile() throws -> (light: [Color], dark: [Color]?) {
        let colors = try loadColors(fileId: figmaParams.lightFileId)
        let lightSuffix = colorParams?.lightModeSuffix
        let darkSuffix = colorParams?.darkModeSuffix ?? "_dark"
        let lightColors = colors
            .filter { !$0.name.hasSuffix(darkSuffix) }
            .map { color -> Color in
                guard let lightSuffix = lightSuffix, color.name.hasSuffix(lightSuffix) else { return color }
                var newColor = color
                newColor.name = String(color.name.dropLast(lightSuffix.count))
                return newColor
            }
        let darkColors = colors
            .filter { $0.name.hasSuffix(darkSuffix) }
            .map { color -> Color in
                var newColor = color
                newColor.name = String(color.name.dropLast(darkSuffix.count))
                return newColor
            }
        return (lightColors, darkColors)
    }
    
    private func loadColors(fileId: String) throws -> [Color] {
        let styles = try loadStyles(fileId: fileId)
        
        guard !styles.isEmpty else {
            throw FigmaExportError.stylesNotFound
        }
        
        let nodes = try loadNodes(fileId: fileId, nodeIds: styles.map { $0.nodeId } )
        return nodesAndStylesToColors(nodes: nodes, styles: styles)
    }
    
    /// Соотносит массив Style и Node чтобы получит массив Color
    private func nodesAndStylesToColors(nodes: [NodeId: Node], styles: [Style]) -> [Color] {
        return styles.compactMap { style -> Color? in
            guard let node = nodes[style.nodeId] else { return nil }
            guard let fill = node.document.fills.first?.asSolid else { return nil }
            let alpha: Double = fill.opacity ?? fill.color.a
            let platform = Platform(rawValue: style.description)
            
            return Color(name: style.name, platform: platform,
                         red: fill.color.r, green: fill.color.g, blue: fill.color.b, alpha: alpha)
        }
    }
    
    private func loadStyles(fileId: String) throws -> [Style] {
        let endpoint = StylesEndpoint(fileId: fileId)
        let styles = try client.request(endpoint)
        return styles.filter {
            $0.styleType == .fill && useStyle($0)
        }
    }
    
    private func useStyle(_ style: Style) -> Bool {
        guard !style.description.isEmpty else {
            return true // Цвет общий
        }
        return !style.description.lowercased().contains("none")
    }
    
    private func loadNodes(fileId: String, nodeIds: [String]) throws -> [NodeId: Node] {
        let endpoint = NodesEndpoint(fileId: fileId, nodeIds: nodeIds)
        return try client.request(endpoint)
    }
}
