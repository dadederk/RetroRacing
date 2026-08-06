//
//  SimctlDeviceCatalog.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

struct SimctlDevicesResponse: Decodable {
    let devices: [String: [SimctlDevice]]
}

struct SimctlDevice: Decodable {
    let udid: String
    let name: String
    let state: String?
    let isAvailable: Bool?
    let dataPath: String?
}
