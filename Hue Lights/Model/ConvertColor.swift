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
    
    static func getRGB(xy: [Double]?, bri: Int) -> UIColor{
        guard let xy = xy else {return .white}
        let x = CGFloat(xy[0])
        let y = CGFloat(xy[1])
        let z: CGFloat = CGFloat(1.0) - x - y
        let brightness = CGFloat(CGFloat(bri) / 255)
//        let bri: CGFloat = 1
        
        let X: CGFloat = (brightness / y) * x
        let Z: CGFloat = (brightness / y) * z
        
        var r: CGFloat =  X * CGFloat(1.656492) - brightness * CGFloat(0.354851) - Z * CGFloat(0.255038)
        var g: CGFloat = -X * CGFloat(0.707196) + brightness * CGFloat(1.655397) + Z * CGFloat(0.036152)
        var b: CGFloat =  X * CGFloat(0.051713) - brightness * CGFloat(0.121364) + Z * CGFloat(1.011530)
        
        r = r <= 0.0031308 ? 12.92 * r : (1.0 + 0.055) * pow(r, (1.0 / 2.4)) - 0.055
        g = g <= 0.0031308 ? 12.92 * g : (1.0 + 0.055) * pow(g, (1.0 / 2.4)) - 0.055
        b = b <= 0.0031308 ? 12.92 * b : (1.0 + 0.055) * pow(b, (1.0 / 2.4)) - 0.055
        
        let color = UIColor(red: r, green: g, blue: b, alpha: brightness)
        return color
    }
}
