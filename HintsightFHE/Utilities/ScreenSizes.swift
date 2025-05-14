//
//  Paddings.swift
//  HintsightFHE
//
//  Created by Luo Kaiwen on 5/12/24.
//

import Foundation

class ScreenSizes {
    private var screenWidth: CGFloat
    public var screenHeight: CGFloat
    
    init() {
        self.screenWidth = 0
        self.screenHeight = 0
    }
    
    public func setScreenHeight(height: CGFloat) {
        self.screenHeight = height
    }
    
    public func setScreenWidth(width: CGFloat) {
        self.screenWidth = width
    }
    
    public func getScreenHeight() -> CGFloat {
        return self.screenHeight
    }
    
    public func getScreenWidth() -> CGFloat {
        return self.screenWidth
    }
    
}
