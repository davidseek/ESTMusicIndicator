//
//  ESTMusicIndicatorContentView.swift
//  ESTMusicIndicator
//
//  Created by Aufree on 12/6/15.
//  Copyright © 2015 The EST Group. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit

class ESTMusicIndicatorContentView: UIView {
    
    fileprivate let kBarCount = 3
    fileprivate let kBarWidth:CGFloat = 3.0
    fileprivate let kBarIdleHeight:CGFloat = 3.0
    fileprivate let kHorizontalBarSpacing:CGFloat = 2.0 // Measured on iPad 2 (non-Retina)
    fileprivate let kRetinaHorizontalBarSpacing:CGFloat = 1.5 // Measured on iPhone 5s (Retina)
    fileprivate let kBarMinPeakHeight:CGFloat = 6.0
    fileprivate let kBarMaxPeakHeight:CGFloat = 12.0
    fileprivate let kMinBaseOscillationPeriod = CFTimeInterval(0.6)
    fileprivate let kMaxBaseOscillationPeriod = CFTimeInterval(0.8)
    fileprivate let kOscillationAnimationKey:String = "oscillation"
    fileprivate let kDecayDuration = CFTimeInterval(0.3)
    fileprivate let kDecayAnimationKey:String = "decay"
    
    var barLayers = [CALayer]()
    var hasInstalledConstraints: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        prepareBarLayers()
        tintColorDidChange()
        setNeedsUpdateConstraints()
    }
    
    convenience init() {
        self.init(frame:CGRect.zero)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate func prepareBarLayers() {
        var xOffset:CGFloat = 0.0
        
        for i in 1...kBarCount {
            let newLayer = createBarLayerWithXOffset(xOffset, layerIndex: i)
            barLayers.append(newLayer)
            layer.addSublayer(newLayer)
            xOffset = newLayer.frame.maxX + horizontalBarSpacing()
        }
    }
    
    fileprivate func createBarLayerWithXOffset(_ xOffset: CGFloat, layerIndex: Int) -> CALayer {
        let layer: CALayer = CALayer()
        layer.anchorPoint = CGPoint(x: 0.0, y: 1.0) // At the bottom-left corner
        layer.position = CGPoint(x: xOffset, y: kBarMaxPeakHeight) // In superview's coordinate
        layer.bounds = CGRect(x: 0.0, y: 0.0, width: kBarWidth, height: (CGFloat(layerIndex) * kBarMaxPeakHeight/CGFloat(kBarCount))) // In its own coordinate }
        return layer
    }
    
    fileprivate func horizontalBarSpacing() -> CGFloat {
        if UIScreen.main.scale == 2.0 {
            return kRetinaHorizontalBarSpacing
        } else {
            return kHorizontalBarSpacing
        }
    }
    
    override func tintColorDidChange() {
        for layer in barLayers{
            layer.backgroundColor = tintColor.cgColor
        }
    }
    
    override var intrinsicContentSize : CGSize {
        var unionFrame:CGRect = CGRect.zero
        
        for layer in barLayers {
            unionFrame = unionFrame.union(layer.frame)
        }
        
        return unionFrame.size;
    }
    
    override func updateConstraints() {
        if !hasInstalledConstraints {
            let size = intrinsicContentSize
            addConstraint(NSLayoutConstraint(item: self,
                                        attribute: .width,
                                        relatedBy: .equal,
                                            toItem: nil,
                                        attribute: .notAnAttribute,
                                        multiplier: 0.0,
                                        constant: size.width));
            
            addConstraint(NSLayoutConstraint(item: self,
                                        attribute: .height,
                                        relatedBy: .equal,
                                        toItem: nil,
                                        attribute: .notAnAttribute,
                                        multiplier: 0.0,
                                        constant: size.height));
            hasInstalledConstraints = true
        }
        super.updateConstraints()
    }
    
    func startOscillation() {
        let basePeriod = kMinBaseOscillationPeriod + (drand48() * (kMaxBaseOscillationPeriod - kMinBaseOscillationPeriod))
        
        for layer in barLayers {
            startOscillatingBarLayer(layer, basePeriod: basePeriod)
        }
    }
    
    func stopOscillation() {
        for layer in barLayers {
            layer.removeAnimation(forKey: kOscillationAnimationKey)
        }
    }
    
    func isOscillating() -> Bool {
        if let _ = barLayers.first?.animation(forKey: kOscillationAnimationKey) {
            return true
        } else {
            return false
        }
    }
    
    func startDecay() {
        for layer in barLayers {
            startDecayingBarLayer(layer)
        }
    }
    
    func stopDecay() {
        for layer in barLayers {
            layer.removeAnimation(forKey: kDecayAnimationKey)
        }
    }
    
    fileprivate func startOscillatingBarLayer(_ layer: CALayer, basePeriod: CFTimeInterval) {
        // arc4random_uniform() will return a uniformly distributed random number **less** upper_bound.
        let peakHeight: CGFloat = kBarMinPeakHeight + CGFloat(arc4random_uniform(UInt32(kBarMaxPeakHeight - kBarMinPeakHeight + 1)))
        
        var fromBouns = layer.bounds;
        fromBouns.size.height = kBarIdleHeight;
        
        var toBounds: CGRect = layer.bounds
        toBounds.size.height = peakHeight
        
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "bounds")
        animation.fromValue = NSValue(cgRect:fromBouns)
        animation.toValue = NSValue(cgRect:toBounds)
        animation.repeatCount = Float.infinity // Forever
        animation.autoreverses = true
        animation.duration = TimeInterval((CGFloat(basePeriod) / 2) * (kBarMaxPeakHeight / peakHeight))
        animation.timingFunction = CAMediaTimingFunction.init(name: kCAMediaTimingFunctionEaseIn)
        
        layer.add(animation, forKey: kOscillationAnimationKey)
    }
    
    fileprivate func startDecayingBarLayer(_ layer: CALayer) {
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "bounds")
        
        animation.fromValue = NSValue(cgRect:CALayer(layer: layer.presentation()!).bounds)
        animation.toValue = NSValue(cgRect:layer.bounds)
        animation.duration = kDecayDuration
        animation.timingFunction = CAMediaTimingFunction.init(name: kCAMediaTimingFunctionEaseOut)
        
        layer.add(animation, forKey: kDecayAnimationKey)
    }

}
