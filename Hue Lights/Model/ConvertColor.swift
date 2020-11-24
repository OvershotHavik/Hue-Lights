//
//  ConvertColor.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/23/20.
//

import UIKit

class ConvertColor{
    static func getXY(red: CGFloat, green: CGFloat, blue: CGFloat) -> Array<Any>{
        var red = red
        var green = green
        var blue = blue
        if (red > 0.04045){
            red = pow((red + 0.055) / (1.0 + 0.055), 2.4);
        }else {
            red = (red / 12.92)
        }
        
        if (green > 0.04045){
            green = pow((green + 0.055) / (1.0 + 0.055), 2.4);
        }else{
            green = (green / 12.92);
        }
        
        if (blue > 0.04045){
            blue = pow((blue + 0.055) / (1.0 + 0.055), 2.4);
        }else{
            blue = (blue / 12.92);
        }
        
        let X = red * 0.664511 + green * 0.154324 + blue * 0.162028;
        let Y = red * 0.283881 + green * 0.668433 + blue * 0.047685;
        let Z = red * 0.000088 + green * 0.072310 + blue * 0.986039;
        let x = X / (X + Y + Z);
        let y = Y / (X + Y + Z);
        let array = [x, y]
        return array
    }
}
