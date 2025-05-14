//
//  HSHeaderButton.swift
//  HintsightFHE
//
//  Created by Luo Kaiwen on 16/7/24.
//

import UIKit

class HSHeaderButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure(titleColor: .black)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(buttonColor: UIColor, titleColor: UIColor, title: String) {
        super.init(frame: .zero)
        self.backgroundColor = buttonColor
        self.setTitle(title, for: .normal)
        configure(titleColor: titleColor)
    }
    
    private func configure(titleColor: UIColor) {
        layer.cornerRadius = 10
        setTitleColor(titleColor, for: .normal)
        titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        translatesAutoresizingMaskIntoConstraints = false
    }

}
