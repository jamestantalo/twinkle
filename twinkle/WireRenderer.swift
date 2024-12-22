import SpriteKit
import CoreGraphics

class WireRenderer {
    private let hueManager: HueManager
    var settingsModel: SettingsModel
    private var wireNode: SKShapeNode?

    init(settingsModel: SettingsModel, hueManager: HueManager) {
        self.settingsModel = settingsModel
        self.hueManager = hueManager
        print("WireRenderer: WireRenderer initialized with SettingsModel.")
    }

    /// Render the wire and lightbulbs in the given scene
    private func determineColor(for index: Int) -> String {
        let colors = settingsModel.selectedPatternColors
        guard !colors.isEmpty else { return "white" } // Default to white if no pattern is selected
        return colors[index % colors.count]
    }

    private func loadTextures(for color: String, hueOffset: CGFloat) -> (SKTexture, SKTexture, SKTexture) {
        if settingsModel.usePredefinedColors {
            // Predefined colors
            return (
                SKTexture(imageNamed: "\(color.lowercased())_bulb_off"),
                SKTexture(imageNamed: "\(color.lowercased())_bulb_on"),
                SKTexture(imageNamed: "\(color.lowercased())_flare")
            )
        } else {
            // Dynamic hue-shifting
            return (
                hueManager.texture(for: "\(color.lowercased())_bulb_off", hueOffset: hueOffset)
                    ?? SKTexture(imageNamed: "\(color.lowercased())_bulb_off"),
                hueManager.texture(for: "\(color.lowercased())_bulb_on", hueOffset: hueOffset)
                    ?? SKTexture(imageNamed: "\(color.lowercased())_bulb_on"),
                hueManager.texture(for: "\(color.lowercased())_flare", hueOffset: hueOffset)
                    ?? SKTexture(imageNamed: "\(color.lowercased())_flare")
            )
        }
    }

    
    func prepareLightbulbs() {
        print("WireRenderer.prepareLightbulbs: Preparing lightbulb textures...")

        // Safely gather required hues by unwrapping optional values in namedColors
        let requiredHues: Set<CGFloat> = Set(
            settingsModel.selectedPatternColors.compactMap { colorName in
                guard let offset = SettingsModel.namedColors[colorName], let unwrappedOffset = offset else {
                    print("WireRenderer.prepareLightbulbs: Warning: No valid hue offset for color '\(colorName)'. Skipping.")
                    return nil
                }
                print("WireRenderer.prepareLightbulbs: Required hue offset for \(colorName): \(unwrappedOffset)")
                return round(unwrappedOffset * 10000) / 10000
            }
        )

        print("WireRenderer.prepareLightbulbs: Hue offsets being processed: \(requiredHues)")

        for imageName in ["bulb_off", "bulb_on", "flare"] {
            let baseTexture = SKTexture(imageNamed: imageName)
            if baseTexture.size() != .zero {
                print("WireRenderer.prepareLightbulbs: Base texture \(imageName) loaded successfully.")
                hueManager.preloadHueRotations(for: imageName, baseTexture: baseTexture, requiredHueOffsets: requiredHues)
            } else {
                print("WireRenderer.prepareLightbulbs: Error: Failed to load base texture \(imageName).")
            }
        }
    }

    
    func renderWire(in scene: SKScene) {
        print("WireRenderer: Rendering wire...")
        clearExistingNodes(in: scene)
        addWire(scene: scene, droopHeight: settingsModel.droopHeight)
        print("WireRenderer: Wire and lightbulbs re-rendered.")

        let anchorPointsWithNormals = extractAnchorPointsWithNormals(
            count: settingsModel.numberOfLights,
            buffer: settingsModel.anchorPointBuffer
        )

        for (index, anchor) in anchorPointsWithNormals.enumerated() {
            let position = CGPoint(
                x: anchor.point.x + settingsModel.socketOffset * anchor.normal.x,
                y: anchor.point.y + settingsModel.socketOffset * anchor.normal.y
            )
            let color = determineColor(for: index) // Use the correct color
            let normalAngle = atan2(anchor.normal.y, anchor.normal.x) - CGFloat.pi / 2

            print("WireRenderer.renderWire: Attempting to load textures for color: \(color) (index \(index))")

            // Load textures based on the correct color
            let bulbOffTexture = SKTexture(imageNamed: "\(color.lowercased())_bulb_off")
            if bulbOffTexture.size() == .zero {
                print("WireRenderer.renderWire: Error: Failed to load bulb_off texture for color: \(color)")
            }

            let bulbOnTexture = SKTexture(imageNamed: "\(color.lowercased())_bulb_on")
            if bulbOnTexture.size() == .zero {
                print("WireRenderer.renderWire: Error: Failed to load bulb_on texture for color: \(color)")
            }

            let flareTexture = SKTexture(imageNamed: "\(color.lowercased())_flare")
            if flareTexture.size() == .zero {
                print("WireRenderer.renderWire: Error: Failed to load flare texture for color: \(color)")
            }

            let socketTexture = SKTexture(imageNamed: settingsModel.lightbulbSocketImage)
            if socketTexture.size() == .zero {
                print("WireRenderer.renderWire: Error: Failed to load socket texture.")
            }

            // Initialize LightbulbNode
            let lightbulbNode = LightbulbNode(
                scale: settingsModel.lightbulbScale,
                position: position,
                socketTexture: socketTexture,
                bulbOffTexture: bulbOffTexture,
                bulbOnTexture: bulbOnTexture,
                flareTexture: flareTexture,
                animationStyle: settingsModel.animationStyle,
                normalAngle: normalAngle,
                index: index, // Pass the index directly as defined in the initializer
                lightbulbOffset: settingsModel.lightbulbOffset,
                zPositions: [
                    "socketNode": 3,
                    "bulbOffNode": 1,
                    "bulbOnNode": 2,
                    "flareNode": 0
                ]
            )

            // Use the existing index for the unique name
            lightbulbNode.name = "lightbulbNode_\(index)" // Assign unique name based on index
            scene.addChild(lightbulbNode)
        }
    }
    

    private func clearExistingNodes(in scene: SKScene) {
        print("WireRenderer: Clearing existing nodes...")
        scene.children.forEach { node in
            if node.name == "wireNode" || node.name?.hasPrefix("lightbulbNode_") == true {
                print("WireRenderer: Stopping actions and removing node \(node.name ?? "unknown").")
                node.removeAllActions() // Stop all ongoing animations
                node.removeFromParent() // Remove the node from the scene
            }
        }
    }

    /// Add a drooping wire to the given scene
    func addWire(scene: SKScene, droopHeight: CGFloat) {
        print("WireRenderer: Entering addWire...")
        print("WireRenderer: Adding wire with droop height \(droopHeight)...")

        let pinPoints = calculatePinPoints(screenWidth: scene.frame.size.width)
        print("WireRenderer: Pin Points:")
        for (index, point) in pinPoints.enumerated() {
            print("  Pin \(index): \(point)")
        }

        let path = createDroopingPath(pinPoints: pinPoints, droopHeight: droopHeight)
        let newWireNode = SKShapeNode(path: path)
        print("WireRenderer: Configuring wire node properties.")
        newWireNode.strokeTexture = SKTexture(imageNamed: settingsModel.wireTexture)
        newWireNode.lineWidth = settingsModel.wireThickness
        newWireNode.strokeColor = NSColor(named: settingsModel.wireColor) ?? .white
        newWireNode.fillColor = .clear

        if let existingWireNode = wireNode {
            print("WireRenderer: Removing existing wire node...")
            scene.removeChildren(in: [existingWireNode])
        }

        wireNode = newWireNode
        print("WireRenderer: Adding wire node to scene.")
        scene.addChild(newWireNode)
        print("WireRenderer: Wire added to scene.")
        print("WireRenderer: Exiting addWire.")
    }

    /// Calculate the pin points for the wire
    func calculateNormalAtPoint(_ point: CGPoint, sampledPoints: [CGPoint]) -> CGPoint {
        guard let index = sampledPoints.firstIndex(of: point) else {
            return .zero
        }

        let prev = index > 0 ? sampledPoints[index - 1] : sampledPoints[index]
        let next = index < sampledPoints.count - 1 ? sampledPoints[index + 1] : sampledPoints[index]
        let tangent = CGPoint(x: next.x - prev.x, y: next.y - prev.y)

        // Rotate tangent 90° counterclockwise to get normal
        let normal = CGPoint(x: -tangent.y, y: tangent.x)

        // Normalize the normal vector
        let length = sqrt(normal.x * normal.x + normal.y * normal.y)
        return CGPoint(x: normal.x / length, y: normal.y / length)
    }

    /// Extract evenly spaced anchor points and their normals from the wire
    func extractAnchorPointsWithNormals(count: Int, buffer: CGFloat = 10) -> [(point: CGPoint, normal: CGPoint)] {
        print("WireRenderer: Entering extractAnchorPointsWithNormals...")
        guard let path = wireNode?.path else {
            print("WireRenderer: Error: No wire path available.")
            return []
        }

        print("WireRenderer: Extracting anchor points and normals...")

        // Sample the path
        let sampledPoints = samplePathPoints(path, resolution: settingsModel.droopCalculationSamples)
        print("WireRenderer: Sampled \(sampledPoints.count) points from path.")

        // Filter points to avoid buffer regions
        let pathStartX = sampledPoints.first?.x ?? 0
        let pathEndX = sampledPoints.last?.x ?? path.boundingBox.maxX
        let filteredPoints = sampledPoints.filter {
            $0.x >= (pathStartX + buffer) && $0.x <= (pathEndX - buffer)
        }

        print("WireRenderer: Filtered Points (after buffer): \(filteredPoints.count)")

        // Evenly distribute points
        guard !filteredPoints.isEmpty else {
            print("WireRenderer: Warning: No points after filtering.")
            return []
        }

        let segmentLength = CGFloat(filteredPoints.count) / CGFloat(max(count - 1, 1))
        var anchorPointsWithNormals: [(point: CGPoint, normal: CGPoint)] = []

        for i in stride(from: 0, to: CGFloat(filteredPoints.count), by: segmentLength) {
            let index = Int(round(i))
            guard index < filteredPoints.count else { continue }
            let point = filteredPoints[index]
            let normal = calculateNormalAtPoint(point, sampledPoints: filteredPoints)
            anchorPointsWithNormals.append((point: point, normal: normal))
        }

        // Ensure the last point is included
        if let lastPoint = filteredPoints.last, !anchorPointsWithNormals.contains(where: { $0.point == lastPoint }) {
            let normal = calculateNormalAtPoint(lastPoint, sampledPoints: filteredPoints)
            anchorPointsWithNormals.append((point: lastPoint, normal: normal))
        }

        print("WireRenderer: Extracted \(anchorPointsWithNormals.count) anchor points with normals.")
        print("WireRenderer: Exiting extractAnchorPointsWithNormals.")
        return anchorPointsWithNormals
    }

    /// Sample points along the path
    private func samplePathPoints(_ path: CGPath, resolution: Int) -> [CGPoint] {
        var points: [CGPoint] = []
        var currentPoint: CGPoint = .zero

        // Use path.applyWithBlock to extract points
        path.applyWithBlock { element in
            let elementType = element.pointee.type
            let pointsPointer = element.pointee.points

            switch elementType {
            case .moveToPoint:
                currentPoint = pointsPointer[0]
                points.append(currentPoint)

            case .addQuadCurveToPoint:
                let controlPoint = pointsPointer[0]
                let endPoint = pointsPointer[1]
                let interpolatedPoints = interpolateQuadCurve(from: currentPoint, control: controlPoint, to: endPoint, resolution: resolution)
                points.append(contentsOf: interpolatedPoints)
                currentPoint = endPoint

            default:
                break
            }
        }
        return points
    }

    
    private func interpolateQuadCurve(from start: CGPoint, control: CGPoint, to end: CGPoint, resolution: Int) -> [CGPoint] {
        var interpolatedPoints: [CGPoint] = []

        for t in stride(from: 0.0, through: 1.0, by: 1.0 / CGFloat(resolution)) {
            let oneMinusT = 1.0 - t
            let interpolatedPoint = CGPoint(
                x: oneMinusT * oneMinusT * start.x + 2 * oneMinusT * t * control.x + t * t * end.x,
                y: oneMinusT * oneMinusT * start.y + 2 * oneMinusT * t * control.y + t * t * end.y
            )
            interpolatedPoints.append(interpolatedPoint)
        }
        return interpolatedPoints
    }

    
    private func interpolatePoints(_ points: [CGPoint], resolution: Int) -> [CGPoint] {
        print("WireRenderer: Entering interpolatePoints...")
        guard points.count > 1 else {
            print("WireRenderer: Warning: Not enough points to interpolate.")
            return points
        }

        var interpolated: [CGPoint] = []
        for i in 0..<points.count - 1 {
            let start = points[i]
            let end = points[i + 1]
            for step in 0...resolution {
                let t = CGFloat(step) / CGFloat(resolution)
                let interpolatedPoint = CGPoint(
                    x: start.x + t * (end.x - start.x),
                    y: start.y + t * (end.y - start.y)
                )
                interpolated.append(interpolatedPoint)
            }
        }
        print("WireRenderer: Interpolated \(interpolated.count) points.")
        print("WireRenderer: Exiting interpolatePoints.")
        return interpolated
    }

    func calculatePinPoints(screenWidth: CGFloat) -> [CGPoint] {
        print("WireRenderer: Entering calculatePinPoints...")
        let points = (0..<settingsModel.numberOfPins).map {
            CGPoint(
                x: screenWidth * CGFloat($0) / CGFloat(max(settingsModel.numberOfPins - 1, 1)),
                y: settingsModel.wireYheight
            )
        }
        print("WireRenderer: Calculated Pin Points: \(points)")
        print("WireRenderer: Exiting calculatePinPoints.")
        return points
    }

    
    /// Create a drooping path for the wire
    private func createDroopingPath(pinPoints: [CGPoint], droopHeight: CGFloat) -> CGPath {
        print("WireRenderer: Entering createDroopingPath...")
        let path = CGMutablePath()
        guard pinPoints.count > 1 else {
            print("WireRenderer: Warning: Not enough pin points to create a drooping path.")
            return path
        }

        path.move(to: pinPoints.first!)

        for i in 0..<pinPoints.count - 1 {
            let start = pinPoints[i]
            let end = pinPoints[i + 1]
            let control = CGPoint(
                x: (start.x + end.x) / 2,
                y: min(start.y, end.y) - droopHeight
            )
            path.addQuadCurve(to: end, control: control)
        }

        print("WireRenderer: Created drooping path with \(pinPoints.count) pin points.")
        print("WireRenderer: Exiting createDroopingPath.")
        return path
    }
}
