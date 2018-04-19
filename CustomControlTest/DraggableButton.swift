//
//  DraggableButton.swift
//  CustomControlTest
//
//  Created by Davyd Shved on 4/16/18.
//  Copyright © 2018 Davyd Shved. All rights reserved.
//

import Foundation
import UIKit

protocol DraggableButtonDelegate {
    func didBeginMoving(button: DraggableButton, inView: UIView)
}

class DraggableButton: UIButton {
    var isLeft = true
    var isLocked = false
    
    var dragRange = CGFloat()...CGFloat()
    var startPoint = CGFloat()
    var endPoint = CGFloat()
    var tagPoint = CGFloat()
    var currentPosition = CGFloat()
    
    let pan = UIPanGestureRecognizer(target: self, action: #selector(panButton(pan:)))
    
    required init(startPt: CGFloat, endPt: CGFloat, tagPt: CGFloat, isLeft: Bool) {
        super.init(frame: CGRect.zero)
        if isLeft {
            dragRange = startPt...tagPt
        } else {
            dragRange = tagPt...endPt
        }
        self.addGestureRecognizer(pan)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc func panButton(pan: UIPanGestureRecognizer) {
        let location = pan.location(in: self.superview) // get pan location
        self.center.x = location.x // set button to where finger is
    }
}
