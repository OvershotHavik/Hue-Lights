//
//  SuccessModel.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 12/9/20.
//

import Foundation

struct SuccessFromBridge: Codable{
    let success : Success
    
    struct Success: Codable{
        let id : String
    }
}
