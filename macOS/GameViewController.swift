//
//  GameViewController.swift
//  SKTiled
//
//  Created by Michael Fessenden on 9/19/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import Cocoa
import SpriteKit


class GameViewController: NSViewController {
    
    // debugging labels
    @IBOutlet weak var mapInfoLabel: NSTextField!
    @IBOutlet weak var tileInfoLabel: NSTextField!
    @IBOutlet weak var propertiesInfoLabel: NSTextField!
    @IBOutlet weak var debugInfoLabel: NSTextField!
    @IBOutlet weak var cameraInfoLabel: NSTextField!    
    @IBOutlet weak var cursorTracker: NSTextField!
    
    var loggingLevel: LoggingLevel = .debug
    let assetManager: AssetManager = AssetManager.default
    var demoFiles: [String] = []
    var currentFilename: String? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: remove debugging for master
        print("[GameViewController]: logging level: \(loggingLevel.rawValue)")
        
        // load demo files from the bundle
        demoFiles = assetManager.tilemaps
        currentFilename = demoFiles.first!

        // Configure the view.
        let skView = self.view as! SKView
        #if DEBUG
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsDrawCount = true
        #endif
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        skView.showsPhysics = false
        setupDebuggingLabels()
        
        
        /* create the game scene */
        let scene = SKTiledDemoScene(size: self.view.bounds.size)
        
        /* set the scale mode to scale to fit the window */
        scene.scaleMode = .aspectFill
        
        //set up notifications for managing scene transitions
        NotificationCenter.default.addObserver(self, selector: #selector(reloadScene), name: NSNotification.Name(rawValue: "reloadScene"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadNextScene), name: NSNotification.Name(rawValue: "loadNextScene"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadPreviousScene), name: NSNotification.Name(rawValue: "loadPreviousScene"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabels), name: NSNotification.Name(rawValue: "updateDebugLabels"), object: nil)
        
        skView.presentScene(scene)
        scene.setup(tmxFile: currentFilename!, verbosity: loggingLevel)
        debugInfoLabel?.isHidden = true
    }
    

    override func viewDidAppear() {
        super.viewDidAppear()
        guard let view = self.view as? SKView else { return }
        
        if let currentScene = view.scene as? SKTiledScene {
            if let tmxName = currentScene.tmxFilename {
                updateWindowTitle(withString: tmxName)
            }
        }
    }
    
    /**
     Set up the debugging labels. (Mimics the text style in iOS controller).
     */
    func setupDebuggingLabels() {
        mapInfoLabel.stringValue = "Map: "
        tileInfoLabel.stringValue = "Tile: "
        propertiesInfoLabel.stringValue = "Properties:"
        cameraInfoLabel.stringValue = "~"
        
        // text shadow
        let shadow = NSShadow()
        shadow.shadowOffset = NSSize(width: 2, height: 1)
        shadow.shadowColor = NSColor(calibratedWhite: 0.1, alpha: 0.75)
        shadow.shadowBlurRadius = 0.5
        
        mapInfoLabel.shadow = shadow
        tileInfoLabel.shadow = shadow
        propertiesInfoLabel.shadow = shadow
        debugInfoLabel.shadow = shadow
        cameraInfoLabel.shadow = shadow
    }
    
    /**
     Action called when `fit to view` button is pressed.
     
     - parameter sender: `Any` ui button.
     */
    @IBAction func fitButtonPressed(_ sender: Any) {
        guard let view = self.view as? SKView,
            let scene = view.scene as? SKTiledScene else { return }
        
        if let cameraNode = scene.cameraNode {
            cameraNode.fitToView(newSize: view.bounds.size)
        }
    }
    
    /**
     Action called when `show grid` button is pressed.
     
     - parameter sender: `Any` ui button.
     */
    @IBAction func gridButtonPressed(_ sender: Any) {
        guard let view = self.view as? SKView,
            let scene = view.scene as? SKTiledScene else { return }
        
        if let tilemap = scene.tilemap {
            tilemap.baseLayer.debugDrawOptions = (tilemap.baseLayer.debugDrawOptions != []) ? [] : [.demo]
        }
    }
    
    /**
     Action called when `show graph` button is pressed.
     
     - parameter sender: `Any` ui button.
     */
    @IBAction func graphButtonPressed(_ sender: Any) {
        guard let view = self.view as? SKView,
            let scene = view.scene as? SKTiledScene else { return }
        
        if let tilemap = scene.tilemap {
            for tileLayer in tilemap.tileLayers() {
                if tileLayer.graph != nil {
                    tileLayer.debugDrawOptions = (tileLayer.debugDrawOptions != []) ? [] : [.graph]
                }
            }
        }
    }
    
    /**
     Action called when `show objects` button is pressed.
     
     - parameter sender: `Any` ui button.
     */
    @IBAction func objectsButtonPressed(_ sender: Any) {
        guard let view = self.view as? SKView,
            let scene = view.scene as? SKTiledScene else { return }
        
        if let tilemap = scene.tilemap {
            tilemap.showObjects = !tilemap.showObjects
        }
    }
    
    /**
     Action called when `next` button is pressed.
     
     - parameter sender: `Any` ui button.
     */
    @IBAction func nextButtonPressed(_ sender: Any) {
        loadNextScene()
    }
    
    /**
     Mouse scroll wheel event handler.
     
     - parameter event: `NSEvent` mouse event.
     */
    override func scrollWheel(with event: NSEvent) {
        guard let view = self.view as? SKView else { return }
        
        if let currentScene = view.scene as? SKTiledDemoScene {
            currentScene.scrollWheel(with: event)
        }
    }
    
    /**
     Reload the current scene.
     
     - parameter interval: `TimeInterval` transition duration.
     */
    func reloadScene(_ interval: TimeInterval=0.4) {
        guard let currentFilename = currentFilename else { return }
        loadScene(withMap: currentFilename, usePreviouCamera: true, interval: interval)
    }
    
    /**
     Load the next tilemap scene.
     
     - parameter interval: `TimeInterval` transition duration.
     */
    func loadNextScene(_ interval: TimeInterval=0.4) {
        guard let currentFilename = currentFilename else { return }
        var nextFilename = demoFiles.first!
        if let index = demoFiles.index(of: currentFilename) , index + 1 < demoFiles.count {
            nextFilename = demoFiles[index + 1]
        }
        loadScene(withMap: nextFilename, usePreviouCamera: false, interval: interval)
    }
    
    /**
     Load the previous tilemap scene.
     
     - parameter interval: `TimeInterval` transition duration.
     */
    func loadPreviousScene(_ interval: TimeInterval=0.4) {
        guard let currentFilename = currentFilename else { return }
        var nextFilename = demoFiles.last!
        if let index = demoFiles.index(of: currentFilename), index > 0, index - 1 < demoFiles.count {
            nextFilename = demoFiles[index - 1]
        }
        
        loadScene(withMap: nextFilename, usePreviouCamera: false, interval: interval)
    }
    
    /**
     Loads a named scene.
     
     - parameter interval: `TimeInterval` transition duration.
     */
    func loadScene(withMap: String, usePreviouCamera: Bool, interval: TimeInterval=0.4) {
        guard let view = self.view as? SKView else { return }
        
        var debugDrawOptions: DebugDrawOptions = []
        var liveMode = false
        var showOverlay = true
        var cameraPosition = CGPoint.zero
        var cameraZoom: CGFloat = 1
        
        if let currentScene = view.scene as? SKTiledDemoScene {
            // block the scene
            currentScene.blocked = true
            if let cameraNode = currentScene.cameraNode {
                showOverlay = cameraNode.showOverlay
                cameraPosition = cameraNode.position
                cameraZoom = cameraNode.zoom
                
            }
            
            liveMode = currentScene.liveMode
            if let tilemap = currentScene.tilemap {
                debugDrawOptions = tilemap.debugDrawOptions
                //currentFilename = tilemap.filename!
            }
        }
        
        DispatchQueue.main.async {
            view.presentScene(nil)
            
            let nextScene = SKTiledDemoScene(size: view.bounds.size)
            nextScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: interval)
            view.presentScene(nextScene, transition: transition)
            
            nextScene.setup(tmxFile: withMap, verbosity: self.loggingLevel)
            nextScene.liveMode = liveMode
            if (usePreviouCamera == true) {
                nextScene.cameraNode?.showOverlay = showOverlay
                nextScene.cameraNode?.position = cameraPosition
                nextScene.cameraNode?.setCameraZoom(cameraZoom)
            }
            nextScene.tilemap?.debugDrawOptions = debugDrawOptions
            self.currentFilename = withMap
        }
    }
    
    /**
     Update the window's title bar with the current scene name.
     
     - parameter withFile: `String` currently loaded scene name.
     */
    func updateWindowTitle(withString named: String) {
        // Update the application window title with the current scene
        if let infoDictionary = Bundle.main.infoDictionary {
            if let bundleName = infoDictionary[kCFBundleNameKey as String] as? String {
                self.view.window?.title = "\(bundleName): \(named) "
            }
        }
    }
    
    /**
     Update the debugging labels with scene information.
     
     - parameter notification: `Notification` notification.
     */
    func updateDebugLabels(notification: Notification) {
        if let mapInfo = notification.userInfo!["mapInfo"] {
            mapInfoLabel.stringValue = mapInfo as! String
        }
        
        if let tileInfo = notification.userInfo!["tileInfo"] {
            tileInfoLabel.stringValue = tileInfo as! String
        }
        
        if let propertiesInfo = notification.userInfo!["propertiesInfo"] {
            propertiesInfoLabel.stringValue = propertiesInfo as! String
        }
        
        if let debugInfo = notification.userInfo!["debugInfo"] {
            debugInfoLabel.stringValue = debugInfo as! String
        }
        
        if let cameraInfo = notification.userInfo!["cameraInfo"] {
            cameraInfoLabel.stringValue = cameraInfo as! String
        }
    }
}
