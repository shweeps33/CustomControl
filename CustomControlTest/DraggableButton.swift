//
//  DraggableButton.swift
//  CustomControlTest
//
//  Created by Davyd Shved on 4/16/18.
//  Copyright © 2018 Davyd Shved. All rights reserved.
//

import Foundation
import UIKit

class DraggableButton: UISlider {
    var isLeft = true
    var isLocked = false
    
    var dragRange = 0.0...9.0
    var startPoint = 0.0
    var endPoint = 10.0
    var basePoint = 5.0
    var currentPosition = CGFloat()
    init(isLeft: Bool) {
        super.init(frame: CGRect.zero)
        if isLeft {
            dragRange = startPoint...basePoint
        } else {
            dragRange = basePoint...endPoint
        }
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
