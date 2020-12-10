//
//  Constants.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/19/20.
//

import UIKit


class UI{
    static let horizontalSpacing = CGFloat(12)
    static let verticalSpacing = CGFloat(8)
    static let backgroundColor = UIColor.systemBlue
    static let whiteXY = [0.3227,0.3290] // white per xy printout
}
struct Cells {
    static let cell = "HueLightsCell"
}

enum HueSender : String {
    case lights = "Lights"
    case groups = "Groups"
    case schedules = "Schedules"
    case scenes = "Scenes"
    case lightScenes = "Light Scenes"
}
