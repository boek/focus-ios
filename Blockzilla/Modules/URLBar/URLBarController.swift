//
//  URLBarController.swift
//  Blockzilla
//
//  Created by Jeffrey Boek on 9/21/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

enum URLBarState {
    case passive
    case active
    case loading(URL, Int)
    case browsing(URL)
}

protocol URLBar: class {
    weak var delegate: URLBarDelegate? { get set }
    var state: URLBarState { get }
}

protocol URLBarDelegate: class {
    func urlBar(_ URLBar: URLBar, stateDidChange state: URLBarState)
}

class URLBarController: UIViewController, URLBar {
    weak var delegate: URLBarDelegate?

    var state: URLBarState = .passive {
        didSet {
            delegate?.urlBar(self, stateDidChange: state)

            switch state {
            case .passive: backgroundView.state = .hidden
            case .active: backgroundView.state = .dark
            default: break
            }
        }
    }

    private var backgroundView = URLBarContainer()
    private var barView = URLBarView()

    convenience init() {
        self.init(nibName: nil, bundle: nil)
        backgroundView.addSubview(barView)
        barView.delegate = self
    }

    override func loadView() {
        self.view = backgroundView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        barView.snp.makeConstraints { make in
            make.edges.equalTo(backgroundView.snp.edges).priority(500)
            make.top.equalTo(topLayoutGuide.snp.bottom)
        }
    }
}

extension URLBarController: URLBarViewDelegate {
    func urlBar(_ urlBar: URLBarView, didEnterText text: String) {

    }

    func urlBar(_ urlBar: URLBarView, didSubmitText text: String) {

    }

    func urlBarDidActivate(_ urlBar: URLBarView) {
        state = .active
    }

    func urlBarDidDeactivate(_ urlBar: URLBarView) {
        state = .passive
    }

    func urlBarDidFocus(_ urlBar: URLBarView) {

    }

    func urlBarDidDismiss(_ urlBar: URLBarView) {

    }

    func urlBarDidPressDelete(_ urlBar: URLBarView) {

    }


}
