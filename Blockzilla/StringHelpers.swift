//
//  StringHelpers.swift
//  Blockzilla
//
//  Created by Jeffrey Boek on 8/9/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation

extension String {
    enum TruncationPosition {
        case head
        case middle
        case tail
    }

    func truncated(limit: Int, position: TruncationPosition = .tail, leader: String = "...") -> String {
        guard self.characters.count > limit else {
            return self
        }

        switch position {
        case .head:
            let truncated = substring(from: characters.index(startIndex, offsetBy: limit - leader.characters.count))
            return leader + truncated
        case .middle:
            let headCharactersCount = Int(ceil(Float(limit - leader.characters.count) / 2.0))
            let head = substring(to: characters.index(startIndex, offsetBy: headCharactersCount))

            let tailCharactersCount = Int(floor(Float(limit - leader.characters.count) / 2.0))
            let tail = substring(from: characters.index(endIndex, offsetBy: -tailCharactersCount))

            return head + leader + tail
        case .tail:
            let truncated = substring(to: characters.index(startIndex, offsetBy: limit -  leader.characters.count))
            return truncated + leader
        }
    }
}
