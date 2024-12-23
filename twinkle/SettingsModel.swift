/*
 
 SettingsModel.swift
 Purpose: Encapsulates all configurable settings for the wire scene and lightbulbs.
 Pipeline: Acts as a data storage class, holding parameters such as:
 Wire properties (thickness, color, texture, droop height).
 Lightbulb properties (images, scale, animations).
 Scene settings (frame rate, background color).
 Inputs: Updated values from SettingsController.
 Outputs: Provides configuration to WireScene and WireRenderer.
 Global Role: Acts as the central configuration model, ensuring settings consistency across the app.

 */

import Foundation
import CoreGraphics
import SpriteKit

class SettingsModel {
    // Existing variables (unchanged)
    var numberOfPins: Int = 4
    var droopHeight: CGFloat = 58.0
    var numberOfLights: Int = 18
    var wireYheight: CGFloat = 165
    var wireThickness: CGFloat = 16.0
    var wireColor: String = "green"
    var wireTexture: String = "wire_evergreen"
    var droopCalculationSamples: Int = 500
    var lightbulbScale: CGFloat = 0.35
    var lightbulbSocketImage: String = "socket_green"
    var lightbulbOffImage: String = "white_bulb_off"
    var lightbulbOnImage: String = "white_bulb_on"
    var lightbulbflareImage: String = "white_flare"
    var lightbulbOffset: CGFloat = 4.0
    var socketOffset: CGFloat = -45.0
    var animationStyle: AnimationStyle = .twinkle
    var hueRange: ClosedRange<CGFloat> = 0.00...1.00
    var flashDuration: TimeInterval = 0.5
    var waitTimeBetweenFlashes: TimeInterval = 0.5
    var frameRate: Int = 10
    var anchorPointBuffer: CGFloat = 20.0
    var lightPositionSpacing: CGFloat?
    var backgroundColor: String = "clear"
    var pinToScreenMargin: CGFloat = 10.0
    var coreColor: String = "white"
    var usePredefinedColors: Bool = true
    var hueAdjustment: CGFloat = 0.0
    var globalHueRotation: CGFloat = 0.0

    // Named colors and patterns
    static let namedColors: [String: CGFloat?] = [
        "White": nil,
        "Yellow": 0.08,
        "Amber": 0.17,
        "Orange": 0.25,
        "Vermillion": 0.33,
        "Red": 0.42,
        "Magenta": 0.50,
        "Purple": 0.58,
        "Violet": 0.67,
        "Blue": 0.75,
        "Teal": 0.83,
        "Green": 0.92,
        "Chartreuse": 1.00
    ]

    static let predefinedPatterns: [String: [String]] = [
        "Red": ["Red"],
        "White": ["White"],
        "Green": ["Green"],
        "Blue": ["Blue"],
        "Orange": ["Orange"],
        "Purple": ["Purple"],
        "Red and White": ["Red", "White"],
        "Blue and White": ["Blue", "White"],
        "Rainbow": ["Red", "Yellow", "Green", "Blue", "Violet"]
    ]

    // Selected pattern name
    var selectedPatternName: String = "Rainbow" {
        didSet {
            selectedPatternColors = SettingsModel.predefinedPatterns[selectedPatternName] ?? []
            print("SettingsModel: Pattern changed to '\(selectedPatternName)'. Current colors: \(selectedPatternColors)")
        }
    }

    // Selected colors for the pattern
    var selectedPatternColors: [String] = [] {
        didSet {
            huePattern = selectedPatternColors.compactMap {
                guard let offset = SettingsModel.namedColors[$0] else {
                    print("SettingsModel: No hue offset for color '\($0)'.")
                    return nil
                }
                return offset.map { $0 * 2 * CGFloat.pi }
            }
        }
    }
    
    var selectedWireSocketPair: WireSocketPair = .evergreen {
        didSet {
            wireTexture = selectedWireSocketPair.wireTexture
            lightbulbSocketImage = selectedWireSocketPair.socketImage
            print("SettingsModel: Wire/socket pair changed to \(selectedWireSocketPair.rawValue).")

            // Automatically update predefined pattern for Halloween
            if selectedWireSocketPair == .halloween {
                selectedPatternName = "Orange" // This will trigger the didSet observer for selectedPatternName
            }
        }
    }

    enum WireSocketPair: String, CaseIterable {
        case evergreen = "Evergreen"
        case candycane = "Candycane"
        case halloween = "Halloween"
        
        var wireTexture: String {
            switch self {
            case .evergreen: return "wire_evergreen"
            case .candycane: return "wire_candycane"
            case .halloween: return "wire_black"
            }
        }
        
        var socketImage: String {
            switch self {
            case .evergreen: return "socket_green"
            case .candycane: return "socket_white"
            case .halloween: return "socket_black"
            }
        }
    }

    
    

    // Color offsets for rendering
    var huePattern: [CGFloat] = []

    // Initialization
    init() {
        // Initialize pattern colors and hue pattern
        selectedPatternColors = SettingsModel.predefinedPatterns[selectedPatternName] ?? []
        huePattern = selectedPatternColors.compactMap {
            guard let offset = SettingsModel.namedColors[$0] else {
                return nil
            }
            return offset.map { $0 * 2 * CGFloat.pi }
        }

        // Inline validation for default textures
        validateTexture(imageName: lightbulbOffImage, description: "Default Bulb Off")
        validateTexture(imageName: lightbulbOnImage, description: "Default Bulb On")
        validateTexture(imageName: lightbulbflareImage, description: "Default Flare")

        // Inline validation for color variants
        SettingsModel.namedColors.keys.forEach { color in
            let bulbOffPath = "\(color.lowercased())_bulb_off"
            let bulbOnPath = "\(color.lowercased())_bulb_on"
            let flarePath = "\(color.lowercased())_flare"

            validateTexture(imageName: bulbOffPath, description: "\(color) Bulb Off")
            validateTexture(imageName: bulbOnPath, description: "\(color) Bulb On")
            validateTexture(imageName: flarePath, description: "\(color) Flare")
        }
    }

    // Texture validation method
    private func validateTexture(imageName: String, description: String) {
        let texture = SKTexture(imageNamed: imageName)
        if texture.size() == .zero {
            print("SettingsModel: Fallback texture detected for \(description) at '\(imageName)'.")
        } else {
            print("SettingsModel: Valid texture for \(description) at '\(imageName)'. Size: \(texture.size())")
        }
    }
}
