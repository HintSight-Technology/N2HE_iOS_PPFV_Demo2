//
//  UIColor.swift
//  HintsightFHE
//
//  Created by Luo Kaiwen on 29/11/24.
//

import UIKit

extension UIColor {
    
    convenience init?(hexString: String, alpha: CGFloat = 1.0) {
        var rgb: UInt64 = 0
        guard Scanner(string: hexString.replacingOccurrences(of: "#", with: ""))
            .scanHexInt64(&rgb) else { return nil }
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}
