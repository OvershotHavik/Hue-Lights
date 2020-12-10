//
//  HueConfiguration.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 12/9/20.
//

import Foundation

/*
class BridgeConfiguration {
    // var sourceItems : [String] // Light/Group/Scene Identifiers
    
    let bridgeIP : String
    let bridgeUser: String
    
    // Represents the state of all Light/Group/Scene on bridge.
    // At any given time, there is only one "state" of the current working set of devices.
    // Some controllers only need a subset of the entire possible model.
    // Some child controllers like Group->Scene do not need to get the same model that the parent uses, and can have it passed in.
    //var hueResults : HueModel?
}
*/


/*
 Main->Group->Scene
 
 Main
 - IP
 - User
 
 Group
 - Model [Group]
 
 Scene
 - Model [Scene] is different based on whether or not there are color bulbs in the sGroup
 
 */
