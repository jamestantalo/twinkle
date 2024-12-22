/*
 
 AppDelegate.swift
 Purpose: This class initializes the application and acts as the entry point. It sets up the HUD window, menu bar icon, settings panel, and the SpriteKit scene.
 Pipeline:
 Creates the HUD window for overlaying graphical elements.
 Configures the SpriteKit view (SKView) to render the WireScene.
 Sets up a status bar menu icon with interactive menu items.
 Instantiates the SettingsController to manage user settings.
 Inputs: Application launch event and settings model configuration.
 Outputs: Initializes WireScene and connects it to the settings model. Displays the HUD and facilitates user interaction through the menu.
 Global Role: Provides the core setup for the app's graphical and interaction pipeline, acting as a bridge between UI and backend components.
 
 */


import Cocoa
import SpriteKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var hudWindow: NSWindow?
    var statusItem: NSStatusItem?
    var settingsController: SettingsController?
    var wireRenderer: WireRenderer?
    var settingsModel: SettingsModel!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        settingsModel = SettingsModel()
        createHUDWindow()

        guard let contentView = hudWindow?.contentView else { return }
        let skView = SKView(frame: contentView.bounds)
        skView.autoresizingMask = [.width, .height]
        skView.allowsTransparency = true
        skView.ignoresSiblingOrder = true
        skView.preferredFramesPerSecond = settingsModel.frameRate
        contentView.addSubview(skView)

        let hueManager = HueManager(settingsModel: settingsModel)
        wireRenderer = WireRenderer(settingsModel: settingsModel, hueManager: hueManager)
        wireRenderer?.prepareLightbulbs()

        let scene = SKScene(size: skView.bounds.size)
        scene.backgroundColor = .clear
        skView.presentScene(scene)
        renderWire(in: scene)

        setupMenuBarIcon()
        setupSettingsPanel(scene: scene)

        hudWindow?.orderFront(nil)
    }


    func createHUDWindow() {
        guard let screenFrame = NSScreen.main?.frame else { return }
        let hudFrame = NSRect(x: 0, y: screenFrame.height - 200, width: screenFrame.width, height: 200)
        hudWindow = NSWindow(contentRect: hudFrame, styleMask: [.borderless], backing: .buffered, defer: false)
        hudWindow?.level = .statusBar + 1
        hudWindow?.isOpaque = false
        hudWindow?.backgroundColor = .clear
        hudWindow?.ignoresMouseEvents = true
        hudWindow?.hasShadow = false
    }

    func renderWire(in scene: SKScene) {
        wireRenderer?.renderWire(in: scene)
    }

    func setupMenuBarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "gift.fill", accessibilityDescription: "Menu Icon")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(showSettingsWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    func setupSettingsPanel(scene: SKScene) {
        settingsController = SettingsController(settingsModel: settingsModel, scene: scene, wireRenderer: wireRenderer)
        settingsController?.onUpdateSettings = { [weak self] in
            guard let self = self else { return }
            self.renderWire(in: scene)
        }
    }

    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Twinkle"
        alert.informativeText = "For Amy, who loved Christmas."
        alert.alertStyle = .informational
        alert.runModal()
    }

    @objc func showSettingsWindow() {
        print("AppDelegate: Showing Settings window.")
        settingsController?.reopen()
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}
