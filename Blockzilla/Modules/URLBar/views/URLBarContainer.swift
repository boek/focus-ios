/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class URLBarContainer: UIView {
    enum State {
        case hidden, dark, bright
    }

    var state: State = .hidden {
        didSet {
            switch state {
            case .hidden:
                backgroundDark.animateHidden(true, duration: 0)
                backgroundBright.animateHidden(true, duration: 0)
            case .dark: isBright = false
            case .bright: isBright = true
            }
        }
    }

    private let backgroundDark = GradientBackgroundView()
    private let backgroundBright = GradientBackgroundView(alpha: 0.8)

    private var isBright: Bool = false {
        didSet {
            backgroundDark.animateHidden(isBright, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
            backgroundBright.animateHidden(!isBright, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
        }
    }

    convenience init() {
        self.init(frame: .zero)

        backgroundDark.isHidden = true
        backgroundDark.alpha = 0
        addSubview(backgroundDark)

        backgroundBright.isHidden = true
        backgroundBright.alpha = 0
        addSubview(backgroundBright)

        backgroundDark.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        backgroundBright.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }
}
