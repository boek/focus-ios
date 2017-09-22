//
//  URLBarController.swift
//  Blockzilla
//
//  Created by Jeffrey Boek on 9/21/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

protocol URLBar: class {
    weak var delegate: URLBarDelegate? { get set }
}

protocol URLBarDelegate: class {

}

class URLBarController: UIViewController, URLBar {

    weak var delegate: URLBarDelegate?

    private var backgroundView = URLBarContainer()
    private var barView = URLBarView()

    convenience init() {
        self.init(nibName: nil, bundle: nil)
        backgroundView.addSubview(barView)

        barView.snp.makeConstraints { make in
            make.edges.equalTo(backgroundView.snp.edges)
        }
    }

    override func loadView() {
        self.view = backgroundView
    }
}
