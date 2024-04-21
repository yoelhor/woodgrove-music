//
//  WgButton.swift
//  NativeAuthSampleApp
//
//  Created by yoelhor on 21/04/2024.
//

import UIKit
import SwiftUI

class WgButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupButton()
    }
    
    
    private func setupButton() {
        titleLabel?.font    = UIFont(name:"VenirNextCondensedDemiBold", size: 22)
        layer.cornerRadius  = frame.size.height/2
        setTitleColor(.white, for: .normal)
    }
}
