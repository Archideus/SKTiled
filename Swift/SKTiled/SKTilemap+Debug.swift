//
//  SKTilemap+Debug.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


public extension SKTilemap {
    
    /**
     Prints out all the data it has on the tilemap's layers.
     */
    public func debugLayers() {
        guard (layerCount > 0) else { return }
        for layer in getLayers() {
            var propertiesString = ""
            for (pname, pvalue) in layer.properties {
                propertiesString += "\"\(pname)\": \(pvalue) "
            }
            print("\(layer.index): \"\(layer.name!)\", z: \(layer.zPosition) \(propertiesString)")
        }
    }

    /**
     Returns a representative grid texture to be used as an overlay.
     
     - parameter scale: image scale (2 seems to work best for fine detail).
     
     - returns: `SKTexture` grid texture.
     */
    public func generateGridTexture(scale: CGFloat=2.0, color: UIColor=UIColor.greenColor()) -> SKTexture? {
        guard let firstLayer = tileLayers.first else { return nil }
        let image: UIImage = imageOfSize(self.renderSize, scale: scale) {
            
            for col in 0 ..< Int(self.mapSize.width) {
                for row in (0 ..< Int(self.mapSize.height)) {
                    
                    let tw = self.tileSize.width
                    let th = self.tileSize.height
                    
                    //let boxRect = CGRect(x: tileWidth * CGFloat(col), y: tileHeight * CGFloat(row), width: tileWidth, height: tileHeight)
                    
                    var xpos: CGFloat = tw * CGFloat(col)
                    var ypos: CGFloat = th * CGFloat(row)
                    
                    if (self.orientation == .Isometric) {
                        let tilePosition = firstLayer.pointForCoordinate(col, row)
                        xpos = tilePosition.x
                        ypos = tilePosition.y
                    }

                    
                    let context = UIGraphicsGetCurrentContext()
                    
                    var shapePath = UIBezierPath()
                    
                    if (self.orientation == .Orthogonal) {
                        // rectangle shape
                        shapePath = UIBezierPath(rect: CGRect(x: xpos, y: ypos, width: tw, height: th))
                        color.setStroke()
                        shapePath.lineWidth = 1
                        shapePath.stroke()
                    }
                    
                    if (self.orientation == .Isometric) {
                        // isometric shape
                        shapePath = UIBezierPath()
                        // top point
                        shapePath.moveToPoint(CGPoint(x: xpos + (tw / 2), y: ypos))  // 0,0
                        // far right
                        shapePath.addLineToPoint(CGPoint(x: xpos + tw, y: ypos + (th / 2))) // 16, 4
                        shapePath.addLineToPoint(CGPoint(x: xpos + (tw / 2), y: ypos + th))
                        shapePath.addLineToPoint(CGPoint(x: xpos, y: ypos + (th / 2)))
                        shapePath.addLineToPoint(CGPoint(x: xpos + (tw / 2), y: ypos))
                        shapePath.closePath()
                        color.setStroke()
                        shapePath.lineWidth = 1
                        shapePath.stroke()
                    }
                    
                    // TODO: check warnings in Xcode
                    CGContextSaveGState(context)
                    CGContextRestoreGState(context)
                }
            }
        }
        
        let result = SKTexture(CGImage: image.CGImage!)
        result.filteringMode = .Nearest
        return result
    }
    
    /// Visualize the tilemap's anchorpoint and frame.
    public var debugDraw: Bool {
        get {
            return childNodeWithName("DEBUG_DRAW") != nil
        } set {
            
            // remove existing node
            childNodeWithName("DEBUG_DRAW")?.removeFromParent()
            
            if (newValue==true) {
                
                let debugNode = SKNode()
                debugNode.name = "DEBUG_DRAW"
                addChild(debugNode)
                debugNode.zPosition = lastZPosition + 10
                
                debugNode.position.x = -(renderSize.width * anchorPoint.x)
                debugNode.position.y = -(renderSize.height * anchorPoint.y)
        
                /// draw properties
                let debugCopy = debugColor.colorWithAlphaComponent(0.5)
                let lineWidth: CGFloat = 1
                let anchorRadius: CGFloat = 3.0
                let drawAntiAliasing: Bool = false
                
                
                // outer frame path
                let framePath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height))
                debugColor.setStroke()
                framePath.lineWidth = lineWidth
                framePath.stroke()
                
                
                // anchor path
                let anchorStartX: CGFloat = (renderSize.width / 2) - (anchorRadius / 2)
                let anchorStartY: CGFloat = (renderSize.height / 2) - (anchorRadius / 2)
                let anchorPath = UIBezierPath(ovalInRect: CGRect(x: anchorStartX, y: anchorStartY, width: anchorRadius, height: anchorRadius))
                debugCopy.setFill()
                anchorPath.fill()
                
                
                // vertical divider path
                let verticalCenterPath = UIBezierPath()
                verticalCenterPath.moveToPoint(CGPoint(x: 0, y: renderSize.height / 2))   // check this
                verticalCenterPath.addLineToPoint(CGPoint(x: renderSize.width, y: renderSize.height / 2))
                debugCopy.setStroke()
                verticalCenterPath.lineWidth = lineWidth
                verticalCenterPath.stroke()
                
                
                // horizontal divider path
                let horizontalCenterPath = UIBezierPath()
                horizontalCenterPath.moveToPoint(CGPoint(x: renderSize.width / 2, y: 0))
                horizontalCenterPath.addLineToPoint(CGPoint(x: renderSize.width / 2, y: renderSize.height))
                debugCopy.setStroke()
                horizontalCenterPath.lineWidth = lineWidth
                horizontalCenterPath.stroke()


                // shapes
                let anchorShape = SKShapeNode(path: anchorPath.CGPath)
                anchorShape.zPosition = debugNode.zPosition + zDeltaForLayers
                anchorShape.antialiased = drawAntiAliasing
                anchorShape.fillColor = debugColor
                anchorShape.strokeColor = UIColor.clearColor()
                debugNode.addChild(anchorShape)
                
                let frameShape = SKShapeNode(path: framePath.CGPath)
                frameShape.antialiased = drawAntiAliasing
                frameShape.lineJoin = .Miter
                frameShape.fillColor = UIColor.clearColor()
                frameShape.strokeColor = debugColor
                frameShape.lineWidth = lineWidth
                debugNode.addChild(frameShape)
                
                let widthIsEven: Bool = mapSize.width % 2 == 0
                let heightIsEven: Bool = mapSize.height % 2 == 0
                
                if (heightIsEven == true) {
                    let vertShape = SKShapeNode(path: verticalCenterPath.CGPath)
                    vertShape.antialiased = drawAntiAliasing
                    vertShape.lineCap = .Square
                    vertShape.fillColor = UIColor.clearColor()
                    vertShape.strokeColor = debugCopy
                    vertShape.lineWidth = lineWidth
                    debugNode.addChild(vertShape)
                }
                
                if (widthIsEven == true) {
                    let horizShape = SKShapeNode(path: horizontalCenterPath.CGPath)
                    horizShape.antialiased = drawAntiAliasing
                    horizShape.lineCap = .Square
                    horizShape.fillColor = UIColor.clearColor()
                    horizShape.strokeColor = debugCopy
                    horizShape.lineWidth = lineWidth
                    debugNode.addChild(horizShape)
                }
            }
        }
    }
}
