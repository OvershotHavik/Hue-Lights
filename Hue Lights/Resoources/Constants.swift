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
    //These have to stsay lowercase for the URL
    case lights = "lights"
    case groups = "groups"
    case schedules = "schedules"
    case scenes = "scenes"
    case lightScenes = "Light Scenes"
    case state = "/state"
    case action = "/action"
    case lightstates = "/lightstates"
}

enum Constants: String{
    case enabled = "enabled"
    case disabled = "disabled"
    case newScene = "New Scene"
}
