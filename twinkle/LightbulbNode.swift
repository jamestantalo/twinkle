import SpriteKit
import CoreImage

enum AnimationStyle: CaseIterable {
    case none
    case steady
    case flicker
    case twinkle
    case pulse
    case chase
    
    var displayName: String {
        switch self {
        case .none: return "Off"
        case .steady: return "Steady"
        case .flicker: return "Flicker"
        case .twinkle: return "Twinkle"
        case .pulse: return "Pulse"
        case .chase: return "Chase"
        }
    }
}

enum BulbState {
    case off
    case on
    case flare
}

class LightbulbNode: SKNode {
    private let socketNode: SKSpriteNode
    private let bulbOffNode: SKSpriteNode
    private let bulbOnNode: SKSpriteNode
    private let flareNode: SKSpriteNode
    private let animationStyle: AnimationStyle
    private let index: Int
    
    // Blend mode properties
    private var flareBlendMode: SKBlendMode = .alpha
    private var bulbOnBlendMode: SKBlendMode = .alpha
    private var bulbOffBlendMode: SKBlendMode = .alpha
    private var socketBlendMode: SKBlendMode = .alpha


    init(
        scale: CGFloat,
        position: CGPoint,
        socketTexture: SKTexture,
        bulbOffTexture: SKTexture,
        bulbOnTexture: SKTexture,
        flareTexture: SKTexture,
        animationStyle: AnimationStyle,
        normalAngle: CGFloat,
        index: Int,
        flareBlendMode: SKBlendMode = .alpha,
        bulbOnBlendMode: SKBlendMode = .alpha,
        bulbOffBlendMode: SKBlendMode = .alpha,
        socketBlendMode: SKBlendMode = .alpha,
        lightbulbOffset: CGFloat,
        zPositions: [String: CGFloat]

    ) {
        print("LightbulbNode.init: Initializing LightbulbNode for index \(index):")
        print("  Position: \(position), Normal Angle: \(normalAngle)")
        print("  Socket Texture Size: \(socketTexture.size())")
        print("  Bulb Off Texture Size: \(bulbOffTexture.size())")
        print("  Bulb On Texture Size: \(bulbOnTexture.size())")
        print("  Flare Texture Size: \(flareTexture.size())")

        self.socketNode = SKSpriteNode(texture: socketTexture)
        self.bulbOffNode = SKSpriteNode(texture: bulbOffTexture)
        self.bulbOnNode = SKSpriteNode(texture: bulbOnTexture)
        self.flareNode = SKSpriteNode(texture: flareTexture)
        self.animationStyle = animationStyle
        self.index = index

        // Assign blend modes
        self.flareBlendMode = flareBlendMode
        self.bulbOnBlendMode = bulbOnBlendMode
        self.bulbOffBlendMode = bulbOffBlendMode
        self.socketBlendMode = socketBlendMode

        super.init()

        self.position = position
        self.zRotation = normalAngle

        // Configure nodes
        configureNode(socketNode, scale: scale, blendMode: socketBlendMode, zPosition: zPositions["socketNode"] ?? -2, offset: 0)
        configureNode(bulbOffNode, scale: scale, blendMode: bulbOffBlendMode, zPosition: zPositions["bulbOffNode"] ?? -1, offset: lightbulbOffset, hidden: false)
        configureNode(bulbOnNode, scale: scale, blendMode: bulbOnBlendMode, zPosition: zPositions["bulbOnNode"] ?? 0, offset: lightbulbOffset, hidden: true)
        configureNode(flareNode, scale: scale, blendMode: flareBlendMode, zPosition: zPositions["flareNode"] ?? 1, offset: lightbulbOffset, hidden: true)

        // Add nodes to the hierarchy
        self.addChild(flareNode)
        self.addChild(socketNode)
        self.addChild(bulbOffNode)
        self.addChild(bulbOnNode)

        // Set up animation
        setupAnimation()
    }

    private func configureNode(
        _ node: SKSpriteNode,
        scale: CGFloat,
        blendMode: SKBlendMode,
        zPosition: CGFloat,
        offset: CGFloat,
        hidden: Bool = false
    ) {
        node.setScale(scale)
        node.isHidden = hidden
        node.zPosition = zPosition
        node.blendMode = blendMode
        node.position = CGPoint(x: 0, y: offset)
    }

    required init?(coder: NSCoder) {
        fatalError("LightbulbNode does not support init(coder:).")
    }

    
    func updatePosition(anchor: CGPoint, normal: CGPoint, offset: CGFloat) {
        self.position = CGPoint(
            x: anchor.x + offset * normal.x,
            y: anchor.y + offset * normal.y
        )
    }

    // MARK: - Animation Setup
    func setupAnimation() {
        removeAllActions() // Ensure no overlapping actions
        print("LightbulbNode: Setting up animation for style \(animationStyle).")

        switch animationStyle {
        case .none:
            setVisibility(isOn: false)
        case .steady:
            setVisibility(isOn: true)
        case .flicker:
            FlickerAnimation()
        case .twinkle:
            TwinkleAnimation() // Call the new Twinkle function
        case .pulse:
            PulseAnimation()
        case .chase:
            ChaseAnimation()
        }
    }

    // MARK: - Visibility Management
    private func setVisibility(isOn: Bool) {
        bulbOffNode.isHidden = isOn
        bulbOnNode.isHidden = !isOn
        flareNode.isHidden = !isOn

        print("LightbulbNode.setVisibility: LightbulbNode Visibility Updated:")
        print("  Bulb Off Node Hidden: \(bulbOffNode.isHidden)")
        print("  Bulb On Node Hidden: \(bulbOnNode.isHidden)")
        print("  Flare Node Hidden: \(flareNode.isHidden)")
    }

    // MARK: - Animation Implementations
    private func FlickerAnimation() {
        let period = Double.random(in: 0.8...1.6)
        let fadeOn = SKAction.run { self.setVisibility(isOn: true) }
        let fadeOff = SKAction.run { self.setVisibility(isOn: false) }
        let sequence = SKAction.sequence([
            fadeOn,
            SKAction.wait(forDuration: period * 0.3),
            fadeOff,
            SKAction.wait(forDuration: period * 0.7)
        ])
        self.run(SKAction.repeatForever(sequence))
    }

    private func TwinkleAnimation() {
        print("LightbulbNode: Setting up Twinkle animation with independent fades for bulb_on + flare.")

        // Animation Parameters
        let fadeDuration: TimeInterval = 0.3               // Duration of fade in/out
        let minOnDuration: TimeInterval = 0.8              // Minimum time bulb_on + flare stays visible
        let maxOnDuration: TimeInterval = 1.1              // Maximum time bulb_on + flare stays visible
        let minOffDuration: TimeInterval = 0.4             // Minimum time bulb_off stays visible
        let maxOffDuration: TimeInterval = 0.6             // Maximum time bulb_off stays visible

        // Ensure socket and bulb_off are always visible
        socketNode.isHidden = false
        socketNode.alpha = 1.0
        bulbOffNode.isHidden = false
        bulbOffNode.alpha = 1.0

        // Fade in "bulb_on + flare"
        let fadeIn = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.bulbOnNode.isHidden = false
            self.flareNode.isHidden = false
            self.bulbOnNode.run(SKAction.fadeAlpha(to: 1.0, duration: fadeDuration)) // Smooth fade in
            self.flareNode.run(SKAction.fadeAlpha(to: 1.0, duration: fadeDuration)) // Smooth fade in
        }

        // Fade out "bulb_on + flare"
        let fadeOut = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.bulbOnNode.run(SKAction.fadeAlpha(to: 0.0, duration: fadeDuration)) // Smooth fade out
            self.flareNode.run(SKAction.fadeAlpha(to: 0.0, duration: fadeDuration)) // Smooth fade out
            self.bulbOnNode.isHidden = true
            self.flareNode.isHidden = true
        }

        // Randomized delays for variability
        let delayDurations = [
            SKAction.wait(forDuration: Double.random(in: minOnDuration...maxOnDuration)), // Delay after fade in
            SKAction.wait(forDuration: Double.random(in: minOffDuration...maxOffDuration)) // Delay after fade out
        ]

        // Sequence of transitions
        let sequence = SKAction.sequence([
            fadeIn,              // Fade in "bulb_on + flare"
            delayDurations[0],   // Hold "bulb_on + flare" state
            fadeOut,             // Fade out "bulb_on + flare"
            delayDurations[1]    // Hold "bulb_off" state
        ])

        // Run the animation
        self.run(SKAction.repeatForever(sequence))
    }

    
    private func PulseAnimation() {
        let fadeIn = SKAction.run { self.setVisibility(isOn: true) }
        let holdOn = SKAction.wait(forDuration: 0.7)
        let fadeOut = SKAction.run { self.setVisibility(isOn: false) }
        let holdOff = SKAction.wait(forDuration: 0.5)

        let pulseSequence = SKAction.sequence([fadeIn, holdOn, fadeOut, holdOff])
        self.run(SKAction.repeatForever(pulseSequence))
    }

    private func ChaseAnimation() {
        let glowDuration: Double = 0.5
        let delayBetweenBulbs: Double = 0.2
        let initialDelay = Double(index) * delayBetweenBulbs

        let fadeIn = SKAction.run { self.setVisibility(isOn: true) }
        let holdOn = SKAction.wait(forDuration: glowDuration)
        let fadeOut = SKAction.run { self.setVisibility(isOn: false) }

        let chaseSequence = SKAction.sequence([
            SKAction.wait(forDuration: initialDelay),
            fadeIn,
            holdOn,
            fadeOut
        ])
        self.run(SKAction.repeatForever(chaseSequence))
    }
}
