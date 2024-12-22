

import SpriteKit
import CoreImage

class HueManager {
    private let settingsModel: SettingsModel
    private var hueTextureCache: [String: [CGFloat: SKTexture]] = [:]

    init(settingsModel: SettingsModel) {
        self.settingsModel = settingsModel
    }

    // Generate and cache hue-shifted textures for a given image
    func preloadHueRotations(for imageName: String, baseTexture: SKTexture, requiredHueOffsets: Set<CGFloat>) {
        print("HueManager: Preloading hue rotations for \(imageName)...")
        for hueOffset in requiredHueOffsets {
            let roundedHueOffset = round(hueOffset * 10000) / 10000
            if let adjustedTexture = applyHueRotation(to: baseTexture, hueOffset: roundedHueOffset) {
                hueTextureCache[imageName, default: [:]][roundedHueOffset] = adjustedTexture
                print("HueManager: Cached texture for \(imageName) at hue offset \(roundedHueOffset).")
            } else {
                print("HueManager: Failed to cache texture for \(imageName) at hue offset \(roundedHueOffset).")
            }
        }
    }

    func texture(for imageName: String, hueOffset: CGFloat) -> SKTexture? {
        let adjustedHueOffset = round(hueOffset * 10000) / 10000
        if let cachedTexture = hueTextureCache[imageName]?[adjustedHueOffset] {
            print("HueManager: Using cached texture for \(imageName) at hue offset \(adjustedHueOffset).")
            return cachedTexture
        }
        print("HueManager: No cached texture for \(imageName) at hue offset \(adjustedHueOffset). Generating dynamically.")
        return applyHueRotation(to: SKTexture(imageNamed: imageName), hueOffset: adjustedHueOffset)
    }

    // Apply hue rotation using CoreImage
    private func applyHueRotation(to texture: SKTexture, hueOffset: CGFloat) -> SKTexture? {
        print("HueManager: Applying hue rotation to texture with hue offset \(hueOffset).")
        let cgImage = texture.cgImage()
        let ciImage = CIImage(cgImage: cgImage)

        let hueFilter = CIFilter(name: "CIHueAdjust")
        hueFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        hueFilter?.setValue(hueOffset * 2 * CGFloat.pi, forKey: "inputAngle")

        guard let outputImage = hueFilter?.outputImage else {
            print("HueManager: Failed to apply hue rotation.")
            return nil
        }

        let context = CIContext()
        guard let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            print("HueManager: Failed to create CGImage after hue rotation.")
            return nil
        }

        print("HueManager: Successfully applied hue rotation.")
        return SKTexture(cgImage: outputCGImage)
    }
}
