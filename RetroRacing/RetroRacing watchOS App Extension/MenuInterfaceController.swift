//
//  MenuInterfaceController.swift
//  RetroRacing watchOS App Extension
//
//  Created by Daniel Devesa Derksen-Staats on 19/04/2020.
//  Copyright © 2020 Desfici Ltd. All rights reserved.
//

import WatchKit

class MenuInterfaceController: WKInterfaceController {
    @IBOutlet private weak var titleLabel: WKInterfaceLabel!
    @IBOutlet private weak var playButton: WKInterfaceButton!
    
    override func didAppear() {
        super.didAppear()
        
        titleLabel.setText(NSLocalizedString("gameName", comment: ""))
    }
}
