/*
 
 SettingsController.swift
 Purpose: Manages the settings window UI, allowing users to modify configuration options (e.g., number of pins, droop height, lights).
 Pipeline:
 Synchronizes UI controls (sliders, steppers) with the SettingsModel.
 Updates the model when user interacts with controls.
 Provides a callback mechanism (onUpdateSettings) to notify other components of changes.
 Inputs: User interaction via the settings UI.
 Outputs: Updates the SettingsModel and triggers updates in dependent components like WireScene.
 Global Role: Centralizes and simplifies user configuration management, ensuring the application reflects user preferences dynamically.
 
 */


import Cocoa
import SpriteKit

class SettingsController: NSWindowController {
    // MARK: - Outlets
    @IBOutlet weak var wireHeightSlider: NSSlider!
    @IBOutlet weak var wireHeightLabel: NSTextField!
    @IBOutlet weak var pinsStepper: NSStepper!
    @IBOutlet weak var pinsLabel: NSTextField!
    @IBOutlet weak var droopSlider: NSSlider!
    @IBOutlet weak var droopLabel: NSTextField!
    @IBOutlet weak var lightsSlider: NSSlider!
    @IBOutlet weak var lightsLabel: NSTextField!
    @IBOutlet weak var animationStylePopUpButton: NSPopUpButton!
    @IBOutlet weak var globalHueRotationSlider: NSSlider!   // Slider for global hue rotation
    @IBOutlet weak var patternPresetPopUpButton: NSPopUpButton!
    @IBOutlet weak var wireSocketPairPopUpButton: NSPopUpButton!
    @IBAction func coreColorChanged(_ sender: NSPopUpButton) {
        guard let selectedColor = sender.titleOfSelectedItem?.lowercased(),
              let scene = self.scene,
              let wireRenderer = self.wireRenderer else { return }
        settingsModel.coreColor = selectedColor
        wireRenderer.renderWire(in: scene) // Re-render with new core color
    }


    var settingsModel: SettingsModel
    var onUpdateSettings: (() -> Void)?
    var scene: SKScene?
    var wireRenderer: WireRenderer?


    init(settingsModel: SettingsModel, scene: SKScene?, wireRenderer: WireRenderer?) {
        self.scene = scene
        self.wireRenderer = wireRenderer
        self.settingsModel = settingsModel
        super.init(window: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadWindow() {
        Bundle.main.loadNibNamed("SettingsPanel", owner: self, topLevelObjects: nil)
        print("Settings window loaded from nib.")
        loadUIFromSettings()
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        print("SettingsController: windowDidLoad: Settings window did load!")

        self.window?.isReleasedWhenClosed = false
        loadUIFromSettings()
    }

    override func close() {
        self.window?.orderOut(nil)
        print("SettingsController: close: Settings window was hidden (not closed).")
    }

    func reopen() {
        if let window = self.window {
            if window.isVisible {
                print("SettingsController: Settings window already visible. Bringing to front.")
            } else {
                print("SettingsController: Settings window hidden. Showing and bringing to front.")
            }
            window.makeKeyAndOrderFront(nil) // Bring to front and make key
            NSApp.activate(ignoringOtherApps: true) // Ensure the app becomes active
        } else {
            print("SettingsController: Window is nil. Reloading from nib.")
            self.loadWindow()
            if let newWindow = self.window {
                print("SettingsController: Successfully reloaded window from nib.")
                newWindow.makeKeyAndOrderFront(nil) // Bring to the front
                NSApp.activate(ignoringOtherApps: true) // Ensure app focus
            } else {
                print("SettingsController: Failed to reload window from nib.")
            }
        }
    }

    private func loadUIFromSettings() {
        // Load settings into UI
        
        wireHeightSlider.minValue = 140 // Minimum value for the slider
        wireHeightSlider.maxValue = 200 // Maximum value for the slider
        wireHeightSlider.doubleValue = Double(Int(settingsModel.wireYheight)) // Initialize to integer value
        wireHeightLabel.stringValue = "\(Int(settingsModel.wireYheight))" // Display as integer

        pinsStepper.integerValue = settingsModel.numberOfPins
        pinsLabel.stringValue = "\(settingsModel.numberOfPins)"

        droopSlider.floatValue = Float(settingsModel.droopHeight)
        droopLabel.stringValue = String(format: "%.1f", settingsModel.droopHeight)

        lightsSlider.integerValue = settingsModel.numberOfLights
        lightsLabel.stringValue = "\(settingsModel.numberOfLights)"

        // Populate animation style pop-up button
        animationStylePopUpButton.removeAllItems()
        animationStylePopUpButton.addItems(withTitles: AnimationStyle.allCases.map { $0.displayName })
        if let currentStyle = AnimationStyle.allCases.first(where: { $0 == settingsModel.animationStyle }) {
            animationStylePopUpButton.selectItem(withTitle: currentStyle.displayName)
        }

        patternPresetPopUpButton.removeAllItems()
        patternPresetPopUpButton.addItems(withTitles: Array(SettingsModel.predefinedPatterns.keys))
        patternPresetPopUpButton.selectItem(withTitle: settingsModel.selectedPatternName)

        wireSocketPairPopUpButton.removeAllItems()
        wireSocketPairPopUpButton.addItems(withTitles: SettingsModel.WireSocketPair.allCases.map { $0.rawValue })
        wireSocketPairPopUpButton.selectItem(withTitle: settingsModel.selectedWireSocketPair.rawValue)
        
    }

    // MARK: - Actions
    
    @IBAction func wireHeightSliderChanged(_ sender: NSSlider) {
        let intValue = Int(sender.doubleValue) // Truncate to integer
        settingsModel.wireYheight = CGFloat(intValue) // Update the settings model
        wireHeightLabel.stringValue = "\(intValue)" // Update the label to display the integer value
        onUpdateSettings?() // Notify other components to re-render
    }

    @IBAction func pinsStepperChanged(_ sender: NSStepper) {
        settingsModel.numberOfPins = sender.integerValue
        pinsLabel.stringValue = "\(settingsModel.numberOfPins)"
        onUpdateSettings?()
    }

    @IBAction func droopSliderChanged(_ sender: NSSlider) {
        settingsModel.droopHeight = CGFloat(sender.floatValue)
        droopLabel.stringValue = String(format: "%.1f", settingsModel.droopHeight)
        onUpdateSettings?()
    }

    @IBAction func lightsSliderChanged(_ sender: NSSlider) {
        settingsModel.numberOfLights = sender.integerValue
        lightsLabel.stringValue = "\(settingsModel.numberOfLights)"
        onUpdateSettings?()
    }

    @IBAction func animationStyleChanged(_ sender: NSPopUpButton) {
        guard let selectedTitle = sender.titleOfSelectedItem,
              let selectedStyle = AnimationStyle.allCases.first(where: { $0.displayName == selectedTitle }) else {
            return
        }
        settingsModel.animationStyle = selectedStyle
        onUpdateSettings?()
    }
    
    @IBAction func patternPresetChanged(_ sender: NSPopUpButton) {
        guard let selectedPattern = sender.titleOfSelectedItem else { return }
        settingsModel.selectedPatternName = selectedPattern
        onUpdateSettings?()
        print("SettingsController: Pattern preset changed to \(selectedPattern).")
    }
    
    @IBAction func wireSocketPairChanged(_ sender: NSPopUpButton) {
        guard let selectedTitle = sender.titleOfSelectedItem,
              let selectedPair = SettingsModel.WireSocketPair.allCases.first(where: { $0.rawValue == selectedTitle }) else {
            return
        }
        settingsModel.selectedWireSocketPair = selectedPair
        onUpdateSettings?()
    }

    @IBAction func globalHueRotationChanged(_ sender: NSSlider) {
        settingsModel.globalHueRotation = CGFloat(sender.floatValue)
        onUpdateSettings?()
        print("SettingsController: Global hue rotation set to \(settingsModel.globalHueRotation).")
    }

    deinit {
        print("SettingsController: Deinitialized.")
    }
}
