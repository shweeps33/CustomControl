//
//  Created by Keisuke Shoji on 2017/03/09.
//
//

import UIKit

public protocol RangeSliderDelegate: class {
    
    /// Called when the RangeSlider values are changed
    ///
    /// - Parameters:
    ///   - slider: RangeSlider
    ///   - minValue: minimum value
    ///   - maxValue: maximum value
    func rangeSlider(_ slider: RangeSlider, didChange minValue: CGFloat, maxValue: CGFloat)
    
    /// Called when the user has started interacting with the RangeSlider
    ///
    /// - Parameter slider: RangeSlider
    func didStartTouches(in slider: RangeSlider)
    
    /// Called when the user has finished interacting with the RangeSlider
    ///
    /// - Parameter slider: RangeSlider
    func didEndTouches(in slider: RangeSlider)
    
    /// Called when the RangeSlider values are changed. A return `String?` Value is displayed on the `minLabel`.
    ///
    /// - Parameters:
    ///   - slider: RangeSlider
    ///   - minValue: minimum value
    /// - Returns: String to be replaced
    func rangeSlider(_ slider: RangeSlider, stringForMinValue minValue: CGFloat) -> String?
    
    /// Called when the RangeSlider values are changed. A return `String?` Value is displayed on the `maxLabel`.
    ///
    /// - Parameters:
    ///   - slider: RangeSlider
    ///   - maxValue: maximum value
    /// - Returns: String to be replaced
    func rangeSlider(_ slider: RangeSlider, stringForMaxValue: CGFloat) -> String?
}

//
//  Created by Keisuke Shoji on 2017/03/09.
//
//

import UIKit

@IBDesignable open class RangeSlider: UIControl {
    
    // MARK: - initializers
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
    }
    
    public required override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    // MARK: - open stored properties
    
    open weak var delegate: RangeSliderDelegate?
    
    var minLabel = UILabel()
    var maxLabel = UILabel()
    var selectedRange = CATextLayer()
    var viewBetweenHandles = UIView()
    var offset = CGFloat()
    
    /// The minimum possible value to select in the range
    @IBInspectable open var minValue: CGFloat = 0.0 {
        didSet {
            refresh()
        }
    }
    
    /// The maximum possible value to select in the range
    @IBInspectable open var maxValue: CGFloat = 300.0 {
        didSet {
            refresh()
        }
    }
    
    /// The preselected minumum value
    /// (note: This should be less than the selectedMaxValue)
    @IBInspectable open var selectedMinValue: CGFloat = 40.0 {
        didSet {
            if selectedMinValue < minValue {
                selectedMinValue = minValue
            }
        }
    }
    
    /// The preselected maximum value
    /// (note: This should be greater than the selectedMinValue)
    @IBInspectable open var selectedMaxValue: CGFloat = 300.0 {
        didSet {
            if selectedMaxValue > maxValue {
                selectedMaxValue = maxValue
            }
        }
    }
    
    /// The minimum distance the two selected slider values must be apart. Default is 0.
    @IBInspectable open var minDistance: CGFloat = 0.0 {
        didSet {
            if minDistance < 0.0 {
                minDistance = 0.0
            }
        }
    }
    
    /// The maximum distance the two selected slider values must be apart. Default is CGFloat.greatestFiniteMagnitude.
    @IBInspectable open var maxDistance: CGFloat = .greatestFiniteMagnitude {
        didSet {
            if maxDistance < 0.0 {
                maxDistance = .greatestFiniteMagnitude
            }
        }
    }
    
    @IBInspectable open var handleColor: UIColor?
    @IBInspectable open var handleBorderColor: UIColor?
    @IBInspectable open var colorBetweenHandles: UIColor?
    @IBInspectable open var colorOutsideHandles: UIColor?
    
    @IBInspectable open var leftHandleImage: UIImage? {
        didSet {
            guard let image = leftHandleImage else {
                return
            }
            
            var handleFrame = CGRect.zero
            handleFrame.size = image.size
            
            leftHandle.frame = handleFrame
            leftHandle.contents = image.cgImage
        }
    }
    @IBInspectable open var rightHandleImage: UIImage? {
        didSet {
            guard let image = rightHandleImage else {
                return
            }
            
            var handleFrame = CGRect.zero
            handleFrame.size = image.size
            
            rightHandle.frame = handleFrame
            rightHandle.contents = image.cgImage
        }
    }
    
    /// Handle diameter (default 16.0)
    @IBInspectable open var handleDiameter: CGFloat = 28.0 {
        didSet {
            leftHandle.cornerRadius = handleDiameter / 2.0
            rightHandle.cornerRadius = handleDiameter / 2.0
            leftHandle.frame = CGRect(x: 0.0, y: 0.0, width: handleDiameter, height: handleDiameter)
            rightHandle.frame = CGRect(x: 0.0, y: 0.0, width: handleDiameter, height: handleDiameter)
        }
    }
    
    
    /// Set the slider line height (default 1.0)
    @IBInspectable open var lineHeight: CGFloat = 22.0 {
        didSet {
            updateLineHeight()
        }
    }
    
    /// Handle border width (default 0.0)
    @IBInspectable open var handleBorderWidth: CGFloat = 0.0 {
        didSet {
            leftHandle.borderWidth = handleBorderWidth
            rightHandle.borderWidth = handleBorderWidth
        }
    }
    
    // MARK: - private stored properties
    
    private enum HandleTracking { case none, left, right, middle }
    private var handleTracking: HandleTracking = .none
    
    private let sliderLine: CALayer = CALayer()
    private let sliderLineBetweenHandles: CALayer = CALayer()
    
    private let leftHandle: CALayer = CALayer()
    private let rightHandle: CALayer = CALayer()
    
    // MARK: - UIView
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        if handleTracking == .none {
            updateLineHeight()
            updateColors()
            updateHandlePositions()
        }
    }
    
    open override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 65.0)
    }
    
    
    // MARK: - UIControl
    
    open override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let touchLocation: CGPoint = touch.location(in: self)
        let insetExpansion: CGFloat = 0.0
        let isTouchingLeftHandle: Bool = leftHandle.frame.insetBy(dx: insetExpansion, dy: insetExpansion).contains(touchLocation)
        let isTouchingRightHandle: Bool = rightHandle.frame.insetBy(dx: insetExpansion, dy: insetExpansion).contains(touchLocation)
        let isTouchingMiddleHandle: Bool = sliderLineBetweenHandles.frame.insetBy(dx: insetExpansion, dy: insetExpansion).contains(touchLocation)
        
        guard isTouchingLeftHandle || isTouchingRightHandle || isTouchingMiddleHandle else { return false }
        
        
        // the touch was inside one of the handles so we're definitely going to start movign one of them. But the handles might be quite close to each other, so now we need to find out which handle the touch was closest too, and activate that one.
        
        let distanceFromLeftHandle: CGFloat = touchLocation.distance(to: leftHandle.frame.center)
        let distanceFromRightHandle: CGFloat = touchLocation.distance(to: rightHandle.frame.center)
        offset = touchLocation.x - sliderLineBetweenHandles.frame.center.x
        
        if (sliderLineBetweenHandles.frame).contains(touchLocation) {
            handleTracking = .middle
        } else if distanceFromLeftHandle < distanceFromRightHandle {
            handleTracking = .left
        } else if selectedMaxValue == maxValue && leftHandle.frame.midX == rightHandle.frame.midX {
            handleTracking = .left
        } else {
            handleTracking = .right
        }
        
        
        
        delegate?.didStartTouches(in: self)
        
        return true
    }
    
    open override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard handleTracking != .none else { return false }
        
        let location: CGPoint = touch.location(in: self)
        //let offset = location.x - sliderLineBetweenHandles.frame.center.x
        
        // find out the percentage along the line we are in x coordinate terms (subtracting half the frames width to account for moving the middle of the handle, not the left hand side)
        let percentage: CGFloat = (location.x - sliderLine.frame.minX - handleDiameter / 2.0) / (sliderLine.frame.maxX - sliderLine.frame.minX)
        
        // multiply that percentage by self.maxValue to get the new selected minimum value
        let selectedValue: CGFloat = percentage * (maxValue - minValue) + minValue
        
        switch handleTracking {
        case .left:
            selectedMinValue = min(selectedValue, selectedMaxValue)
            updateHandlePositions()
        case .right:
            // don't let the dots cross over, (unless range is disabled, in which case just dont let the dot fall off the end of the screen)
            if selectedValue >= minValue {
                selectedMaxValue = selectedValue
            } else {
                selectedMaxValue = max(selectedValue, selectedMinValue)
            }
            updateHandlePositions()
        case .middle:
            sliderLineBetweenHandles.position.x = location.x - offset
            updateMiddleHandlePosition()
        case .none:
            // no need to refresh the view because it is done as a side-effect of setting the property
            break
        }
        
        updateRangeLabel()
        
        //refresh()
        
        return true
    }
    
    open override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        handleTracking = .none
        
        delegate?.didEndTouches(in: self)
    }
    
    // MARK: - private methods
    
    private func setup() {
        
        // draw the slider line
        layer.addSublayer(sliderLine)
        
        // draw the track distline
        layer.addSublayer(sliderLineBetweenHandles)
        
        // draw the minimum slider handle
        leftHandle.cornerRadius = handleDiameter / 2.0
        leftHandle.borderWidth = handleBorderWidth
        layer.addSublayer(leftHandle)
        
        // draw the maximum slider handle
        rightHandle.cornerRadius = handleDiameter / 2.0
        rightHandle.borderWidth = handleBorderWidth
        layer.addSublayer(rightHandle)
        
        let handleFrame: CGRect = CGRect(x: 0.0, y: 0.0, width: handleDiameter, height: handleDiameter)
        leftHandle.frame = handleFrame
        rightHandle.frame = handleFrame
        
        let labelFontSize: CGFloat = 15.0
        let font = UIFont.systemFont(ofSize: labelFontSize)
        
        selectedRange.alignmentMode = kCAAlignmentCenter
        selectedRange.contentsScale = UIScreen.main.scale
        selectedRange.font = font as CFTypeRef
        selectedRange.fontSize = font.pointSize
        selectedRange.frame.size = CGSize(width: 50, height: 20)
        layer.addSublayer(selectedRange)
        
        refresh()
    }

    
    private func percentageAlongLine(for value: CGFloat) -> CGFloat {
        // stops divide by zero errors where maxMinDif would be zero. If the min and max are the same the percentage has no point.
        guard minValue < maxValue else { return 0.0 }
        
        // get the difference between the maximum and minimum values (e.g if max was 100, and min was 50, difference is 50)
        let maxMinDif: CGFloat = maxValue - minValue
        
        // now subtract value from the minValue (e.g if value is 75, then 75-50 = 25)
        let valueSubtracted: CGFloat = value - minValue
        
        // now divide valueSubtracted by maxMinDif to get the percentage (e.g 25/50 = 0.5)
        return valueSubtracted / maxMinDif
    }
    
    private func xPositionAlongLine(for value: CGFloat) -> CGFloat {
        // first get the percentage along the line for the value
        let percentage: CGFloat = percentageAlongLine(for: value)
        
        // get the difference between the maximum and minimum coordinate position x values (e.g if max was x = 310, and min was x=10, difference is 300)
        let maxMinDif: CGFloat = sliderLine.frame.maxX - sliderLine.frame.minX
        
        // now multiply the percentage by the minMaxDif to see how far along the line the point should be, and add it onto the minimum x position.
        let offset: CGFloat = percentage * maxMinDif
        
        return sliderLine.frame.minX + offset
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
    
    private func updateColors() {
        let tintCGColor = tintColor.cgColor
        sliderLineBetweenHandles.backgroundColor = colorBetweenHandles?.cgColor ?? tintCGColor
        sliderLine.backgroundColor = colorOutsideHandles?.cgColor ?? tintCGColor
        
        let color: CGColor
        color = handleColor?.cgColor ?? tintCGColor
        
        leftHandle.backgroundColor = color
        leftHandle.borderColor = handleBorderColor.map { $0.cgColor }
        rightHandle.backgroundColor = color
        rightHandle.borderColor = handleBorderColor.map { $0.cgColor }
    }
    
    private func updateHandlePositions() {
        leftHandle.position = CGPoint(x: xPositionAlongLine(for: selectedMinValue),
                                      y: sliderLine.frame.midY)
        
        rightHandle.position = CGPoint(x: xPositionAlongLine(for: selectedMaxValue),
                                       y: sliderLine.frame.midY)
        
        // positioning for the dist slider line
        sliderLineBetweenHandles.frame = CGRect(x: leftHandle.position.x,
                                                y: sliderLine.frame.minY,
                                                width: rightHandle.position.x - leftHandle.position.x,
                                                height: lineHeight)
    }
    
    private func updateMiddleHandlePosition() {
        leftHandle.position = CGPoint(x: sliderLineBetweenHandles.frame.minX,
                                      y: sliderLine.frame.midY)
        
        rightHandle.position = CGPoint(x: sliderLineBetweenHandles.frame.maxX,
                                       y: sliderLine.frame.midY)
    }
    
    private func updateRangeLabel() {
        let range = selectedMaxValue - selectedMinValue
        selectedRange.frame.origin = CGPoint(x: sliderLineBetweenHandles.frame.center.x - selectedRange.frame.width/2, y: 30)
        selectedRange.string = "\(range)"
    }
    
    fileprivate func refresh() {
        
//        let diff: CGFloat = selectedMaxValue - selectedMinValue
//
//        if diff < minDistance {
//            switch handleTracking {
//            case .left:
//                selectedMinValue = selectedMaxValue - minDistance
//            case .right:
//                selectedMaxValue = selectedMinValue + minDistance
//            case .middle:
//                selectedMinValue = selectedMaxValue - minDistance
//                selectedMaxValue = selectedMinValue + minDistance
//            case .none:
//                break
//            }
//        }
        
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
        CATransaction.commit()
        
        updateColors()
        
        // update the delegate
        if let delegate = delegate, handleTracking != .none {
            delegate.rangeSlider(self, didChange: selectedMinValue, maxValue: selectedMaxValue)
        }
    }
    
}

private extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}

private extension CGPoint {
    func distance(to: CGPoint) -> CGFloat {
        let distX: CGFloat = to.x - x
        let distY: CGFloat = to.y - y
        return sqrt(distX * distX + distY * distY)
    }
}
