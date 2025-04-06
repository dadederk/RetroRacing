//
//  MenuViewController.swift
//  RetroRacing
//
//  Created by Dani on 06/04/2025.
//

import UIKit

final class MenuViewController: UIViewController {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var leaderboardButton: UIButton!
    @IBOutlet private weak var rateAppButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        titleLabel.adjustsFontForContentSizeCategory = true
        playButton.titleLabel?.adjustsFontForContentSizeCategory = true
        leaderboardButton.titleLabel?.adjustsFontForContentSizeCategory = true
        rateAppButton.titleLabel?.adjustsFontForContentSizeCategory = true
        
        titleLabel.text = String(localized: "gameName")
        playButton.setTitle(String(localized: "play"), for: .normal)
        leaderboardButton.setTitle(String(localized: "leaderboard"), for: .normal)
        rateAppButton.setTitle(String(localized: "rateApp"), for: .normal)
        
        if let font = UIFont(name: "PressStart2P-Regular", size: 27.0) {
            titleLabel.font = UIFontMetrics(forTextStyle: .title1).scaledFont(for: font)
        }
    }
}

