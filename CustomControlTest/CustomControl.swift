//
//  CustomControl.swift
//  CustomControlTest
//
//  Created by Davyd Shved on 4/16/18.
//  Copyright © 2018 Davyd Shved. All rights reserved.
//

import UIKit

protocol CustomControlDelegate: class {
    /// Called when the RangeSeekSlider values are changed
    ///
    /// - Parameters:
    ///   - slider: RangeSeekSlider
    ///   - minValue: minimum value
    ///   - maxValue: maximum value
    func rangeSeekSlider(_ slider: CustomControl, didChange minValue: CGFloat, maxValue: CGFloat)
    
    /// Called when the user has started interacting with the RangeSeekSlider
    ///
    /// - Parameter slider: RangeSeekSlider
    func didStartTouches(in slider: CustomControl)
    
    /// Called when the user has finished interacting with the RangeSeekSlider
    ///
    /// - Parameter slider: RangeSeekSlider
    func didEndTouches(in slider: CustomControl)
}

class CustomControl: UIControl {
    
    private var sliderLine: CALayer = CALayer()
    private let sliderLineBetweenHandles: CALayer = CALayer()
    
    private let leftHandle: CALayer = CALayer()
    private let rightHandle: CALayer = CALayer()
    
    private enum HandleTracking { case none, left, right }
    private var handleTracking: HandleTracking = .none
    
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public required override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    open override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let touchLocation: CGPoint = touch.location(in: self)
        let insetExpansion: CGFloat = -30.0
        let isTouchingLeftHandle: Bool = leftHandle.frame.insetBy(dx: insetExpansion, dy: insetExpansion).contains(touchLocation)
        let isTouchingRightHandle: Bool = rightHandle.frame.insetBy(dx: insetExpansion, dy: insetExpansion).contains(touchLocation)
        
        guard isTouchingLeftHandle || isTouchingRightHandle else { return false }
        
        
        // the touch was inside one of the handles so we're definitely going to start movign one of them. But the handles might be quite close to each other, so now we need to find out which handle the touch was closest too, and activate that one.
        let distanceFromLeftHandle: CGFloat = touchLocation.distance(to: leftHandle.frame.center)
        let distanceFromRightHandle: CGFloat = touchLocation.distance(to: rightHandle.frame.center)
        
        if distanceFromLeftHandle < distanceFromRightHandle {
            handleTracking = .left
        } else if leftHandle.frame.midX == rightHandle.frame.midX {
            handleTracking = .left
        } else {
            handleTracking = .right
        }
        let handle: CALayer = (handleTracking == .left) ? leftHandle : rightHandle
        animate(handle: handle, selected: true)
        
        delegate?.didStartTouches(in: self)
        
        return true
    }
    
    open override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard handleTracking != .none else { return false }
        
        let location: CGPoint = touch.location(in: self)
        
        // find out the percentage along the line we are in x coordinate terms (subtracting half the frames width to account for moving the middle of the handle, not the left hand side)
        let percentage: CGFloat = (location.x - sliderLine.frame.minX - handleDiameter / 2.0) / (sliderLine.frame.maxX - sliderLine.frame.minX)
        
        // multiply that percentage by self.maxValue to get the new selected minimum value
        let selectedValue: CGFloat = percentage * (maxValue - minValue) + minValue
        
        switch handleTracking {
        case .left:
            selectedMinValue = min(selectedValue, selectedMaxValue)
        case .right:
            // don't let the dots cross over, (unless range is disabled, in which case just dont let the dot fall off the end of the screen)
            if selectedValue >= minValue {
                selectedMaxValue = selectedValue
            } else {
                selectedMaxValue = max(selectedValue, selectedMinValue)
            }
        case .none:
            // no need to refresh the view because it is done as a side-effect of setting the property
            break
        }
        
        refresh()
        
        return true
    }
    
    open override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        let handle: CALayer = (handleTracking == .left) ? leftHandle : rightHandle
        animate(handle: handle, selected: false)
        handleTracking = .none
        
        delegate?.didEndTouches(in: self)
    }
    
    /// Handle diameter (default 16.0)
    @IBInspectable open var handleDiameter: CGFloat = 16.0 {
        didSet {
            leftHandle.cornerRadius = handleDiameter / 2.0
            rightHandle.cornerRadius = handleDiameter / 2.0
            leftHandle.frame = CGRect(x: 0.0, y: 0.0, width: handleDiameter, height: handleDiameter)
            rightHandle.frame = CGRect(x: 0.0, y: 0.0, width: handleDiameter, height: handleDiameter)
        }
    }
    
    /// Selected handle diameter multiplier (default 1.7)
    @IBInspectable open var selectedHandleDiameterMultiplier: CGFloat = 1.7
    
    /// Set the slider line height (default 1.0)
    @IBInspectable open var lineHeight: CGFloat = 10.0 {
        didSet {
            updateLineHeight()
        }
    }
    
    open weak var delegate: CustomControlDelegate?
    
    /// The minimum possible value to select in the range
    @IBInspectable open var minValue: CGFloat = 0.0 {
        didSet {
            refresh()
        }
    }
    
    /// The maximum possible value to select in the range
    @IBInspectable open var maxValue: CGFloat = 100.0 {
        didSet {
            refresh()
        }
    }
    
    /// The preselected minumum value
    /// (note: This should be less than the selectedMaxValue)
    @IBInspectable open var selectedMinValue: CGFloat = 0.0 {
        didSet {
            if selectedMinValue < minValue {
                selectedMinValue = minValue
            }
        }
    }
    
    /// The preselected maximum value
    /// (note: This should be greater than the selectedMinValue)
    @IBInspectable open var selectedMaxValue: CGFloat = 100.0 {
        didSet {
            if selectedMaxValue > maxValue {
                selectedMaxValue = maxValue
            }
        }
    }
    
    private func updateLineHeight() {
        let barSidePadding: CGFloat = 16.0
        let yMiddle: CGFloat = frame.height / 2.0
        let lineLeftSide: CGPoint = CGPoint(x: barSidePadding, y: yMiddle)
        let lineRightSide: CGPoint = CGPoint(x: frame.width - barSidePadding,
                                             y: yMiddle)
        sliderLine.frame = CGRect(x: lineLeftSide.x,
                                  y: lineLeftSide.y,
                                  width: lineRightSide.x - lineLeftSide.x,
                                  height: lineHeight)
        sliderLine.cornerRadius = lineHeight / 2.0
        sliderLineBetweenHandles.cornerRadius = sliderLine.cornerRadius
    }
    
    override func layoutSubviews() {
        colorSetup()
    }
    
    func setup() {
        // draw the slider line
        layer.addSublayer(sliderLine)
        
        // draw the track distline
        layer.addSublayer(sliderLineBetweenHandles)
        
        // draw the minimum slider handle
        leftHandle.cornerRadius = handleDiameter / 2.0
        layer.addSublayer(leftHandle)
        
        // draw the maximum slider handle
        rightHandle.cornerRadius = handleDiameter / 2.0
        layer.addSublayer(rightHandle)
    }
    
    func colorSetup() {
        sliderLine.backgroundColor = UIColor.red.cgColor
        leftHandle.backgroundColor = UIColor.green.cgColor
        rightHandle.backgroundColor = UIColor.green.cgColor
    }
    
    private func animate(handle: CALayer, selected: Bool) {
        let transform: CATransform3D
        if selected {
            transform = CATransform3DMakeScale(selectedHandleDiameterMultiplier, selectedHandleDiameterMultiplier, 1.0)
        } else {
            transform = CATransform3DIdentity
        }
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.3)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        handle.transform = transform
        
        // the label above the handle will need to move too if the handle changes size
        //updateLabelPositions()
        
        CATransaction.commit()
    }
    
    fileprivate func refresh() {
        if enableStep && step > 0.0 {
            selectedMinValue = CGFloat(roundf(Float(selectedMinValue / step))) * step
            if let previousStepMinValue = previousStepMinValue, previousStepMinValue != selectedMinValue {
                TapticEngine.selection.feedback()
            }
            previousStepMinValue = selectedMinValue
            
            selectedMaxValue = CGFloat(roundf(Float(selectedMaxValue / step))) * step
            if let previousStepMaxValue = previousStepMaxValue, previousStepMaxValue != selectedMaxValue {
                TapticEngine.selection.feedback()
            }
            previousStepMaxValue = selectedMaxValue
        }
        
        let diff: CGFloat = selectedMaxValue - selectedMinValue
        
        if diff < minDistance {
            switch handleTracking {
            case .left:
                selectedMinValue = selectedMaxValue - minDistance
            case .right:
                selectedMaxValue = selectedMinValue + minDistance
            case .none:
                break
            }
        } else if diff > maxDistance {
            switch handleTracking {
            case .left:
                selectedMinValue = selectedMaxValue - maxDistance
            case .right:
                selectedMaxValue = selectedMinValue + maxDistance
            case .none:
                break
            }
        }
        
        // ensure the minimum and maximum selected values are within range. Access the values directly so we don't cause this refresh method to be called again (otherwise changing the properties causes a refresh)
        if selectedMinValue < minValue {
            selectedMinValue = minValue
        }
        if selectedMaxValue > maxValue {
            selectedMaxValue = maxValue
        }
        
        // update the frames in a transaction so that the tracking doesn't continue until the frame has moved.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        updateHandlePositions()
        updateLabelPositions()
        CATransaction.commit()
        
        updateLabelValues()
        updateColors()
        updateAccessibilityElements()
        
        // update the delegate
        if let delegate = delegate, handleTracking != .none {
            delegate.rangeSeekSlider(self, didChange: selectedMinValue, maxValue: selectedMaxValue)
        }
    }
    
}

private extension CGPoint {
    func distance(to: CGPoint) -> CGFloat {
        let distX: CGFloat = to.x - x
        let distY: CGFloat = to.y - y
        return sqrt(distX * distX + distY * distY)
    }
}

private extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}
