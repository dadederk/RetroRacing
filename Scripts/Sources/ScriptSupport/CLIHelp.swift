//
//  CLIHelp.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/07/2026.
//

import Foundation

public enum CLIHelp {
    public static func exitIfRequested(_ arguments: CLIArguments, usage: () -> String) {
        guard arguments.contains("--help") || arguments.contains("-h") else { return }
        print(usage())
        exit(0)
    }
}
