//
//  MenuViewController.swift
//  RetroRacing
//
//  Created by Daniel Devesa Derksen-Staats on 19/04/2020.
//  Copyright © 2020 Desfici Ltd. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var leaderboardButton: UIButton!
    @IBOutlet private weak var rateAppButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        playButton.titleLabel?.adjustsFontForContentSizeCategory = true
        leaderboardButton.titleLabel?.adjustsFontForContentSizeCategory = true
        rateAppButton.titleLabel?.adjustsFontForContentSizeCategory = true
        
        titleLabel.text = NSLocalizedString("gameName", comment: "")
    }
}
