//
//  Sequence+UniqueHash.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/29/20.
//

import Foundation
extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}
