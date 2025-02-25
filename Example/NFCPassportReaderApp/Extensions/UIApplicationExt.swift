//
//  UIApplicationExt.swift
//  NFCPassportReaderApp
//
//  Created by OCR Labs on 20/01/2021.
//  Copyright © 2021 OCR Labs. All rights reserved.
//

import UIKit

extension UIApplication {
    static var release: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String? ?? "x.x"
    }
    static var build: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String? ?? "x"
    }
    static var version: String {
        return "\(release).\(build)"
    }
}
