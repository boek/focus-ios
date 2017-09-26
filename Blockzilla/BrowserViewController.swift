/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Telemetry

class BrowserViewController: UIViewController {
    private let webViewController = WebViewController()
    private let urlBarController = URLBarController()

    fileprivate let browserToolbar = BrowserToolbar()
    fileprivate let homeView = HomeView()
    fileprivate let overlayView = OverlayView()
    fileprivate let searchEngineManager = SearchEngineManager(prefs: .standard)
    fileprivate let requestHandler = RequestHandler()

    fileprivate var toolbarBottomConstraint: Constraint!
    fileprivate var urlBarConstraint: Constraint!
    fileprivate var overlayConstraint: Constraint!
    fileprivate var homeViewBottomConstraint: Constraint!
    fileprivate var browserBottomConstraint: Constraint!
    fileprivate var lastScrollOffset = CGPoint.zero
    fileprivate var lastScrollTranslation = CGPoint.zero
    fileprivate var scrollBarOffsetAlpha: CGFloat = 0
    fileprivate var scrollBarState: URLBarScrollState = .expanded

    fileprivate let urlCacheManager = URLCacheManeger()

    fileprivate enum URLBarScrollState {
        case collapsed
        case expanded
        case transitioning
        case animating
    }

    private let urlBarContainer = UIView()
    private let webViewContainer = UIView()
    private var homeViewContainer = UIView()
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }


    fileprivate var showsToolsetInURLBar = false {
        didSet {
            if showsToolsetInURLBar {
                browserBottomConstraint.deactivate()
            } else {
                browserBottomConstraint.activate()
            }
        }
    }

    private var shouldEnsureBrowsingMode = false
    private var initialUrl: URL?

    convenience init() {
        self.init(nibName: nil, bundle: nil)
        KeyboardHelper.defaultHelper.addDelegate(delegate: self)
        urlBarController.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        webViewController.delegate = self

        homeView.delegate = self
        homeViewContainer.addSubview(homeView)

        homeView.snp.makeConstraints { make in
            make.edges.equalTo(homeViewContainer)
        }

        let background = GradientBackgroundView(alpha: 0.7, startPoint: CGPoint.zero, endPoint: CGPoint(x: 1, y: 1))
        view.addSubview(background)

        view.addSubview(homeViewContainer)

        webViewContainer.isHidden = true
        webViewContainer.backgroundColor = .yellow
        view.addSubview(webViewContainer)

        view.addSubview(urlBarContainer)

        browserToolbar.isHidden = true
        browserToolbar.alpha = 0
        browserToolbar.delegate = self
        browserToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(browserToolbar)

        overlayView.isHidden = true
        overlayView.alpha = 0
        overlayView.delegate = self
        overlayView.backgroundColor = UIConstants.colors.overlayBackground
        view.addSubview(overlayView)

        background.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }

        urlBarContainer.snp.makeConstraints { make in
            make.trailing.equalTo(homeView.settingsButton.snp.leading).offset(-8).priority(500)
            urlBarConstraint = make.trailing.equalTo(view).constraint
            make.top.leading.equalTo(view)
        }
        urlBarConstraint.deactivate()

        browserToolbar.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view)
            make.height.equalTo(UIConstants.layout.browserToolbarHeight)
            toolbarBottomConstraint = make.bottom.equalTo(view).constraint
        }

        homeViewContainer.snp.makeConstraints { make in
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.leading.trailing.equalTo(view)
            homeViewBottomConstraint = make.bottom.equalTo(view).constraint
            homeViewBottomConstraint.activate()
        }

        webViewContainer.snp.makeConstraints { make in
            make.top.equalTo(urlBarContainer.snp.bottom).priority(500)
            make.bottom.equalTo(view).priority(500)
            browserBottomConstraint = make.bottom.equalTo(browserToolbar.snp.top).priority(1000).constraint

            if !showsToolsetInURLBar {
                browserBottomConstraint.activate()
            }

            make.leading.trailing.equalTo(view)
        }

        overlayView.snp.makeConstraints { make in
            make.top.equalTo(homeView.snp.bottom).dividedBy(2).priority(500)
            
            print(urlBarContainer.snp.bottom)
            overlayConstraint = make.top.equalTo(urlBarContainer.snp.bottom).constraint
            make.leading.trailing.bottom.equalTo(view)
        }
        
        overlayConstraint.deactivate()

        showsToolsetInURLBar = UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.orientation.isLandscape

        containWebView()
        containUrlBar()

        guard shouldEnsureBrowsingMode else { return }
        ensureBrowsingMode()
        guard let url = initialUrl else { return }
        submit(url: url)
    }

    

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)

        // Prevent the keyboard from showing up until after the user has viewed the Intro.
        let userHasSeenIntro = UserDefaults.standard.integer(forKey: AppDelegate.prefIntroDone) == AppDelegate.prefIntroVersion

        // WKTODO: Focus URLBar
        // if userHasSeenIntro && !urlBar.inBrowsingMode {
        //     urlBar.becomeFirstResponder()
        // }

        super.viewWillAppear(animated)
    }

    private func containWebView() {
        addChildViewController(webViewController)
        webViewContainer.addSubview(webViewController.view)
        webViewController.didMove(toParentViewController: self)

        webViewController.view.snp.makeConstraints { make in
            make.edges.equalTo(webViewContainer.snp.edges)
        }
    }

    private func containUrlBar() {
        addChildViewController(urlBarController)
        urlBarContainer.addSubview(urlBarController.view)
        urlBarController.didMove(toParentViewController: self)

        urlBarController.view.snp.makeConstraints { make in
            make.edges.equalTo(urlBarContainer.snp.edges)
        }
    }

    fileprivate func resetBrowser() {
        // Screenshot the browser, showing the screenshot on top.
        let image = view.screenshot()
        let screenshotView = UIImageView(image: image)
        view.addSubview(screenshotView)
        screenshotView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }

        // Reset the views. These changes won't be immediately visible since they'll be under the screenshot.

        // WKTODO: Reset
        // browser.reset()
        webViewContainer.isHidden = true
        browserToolbar.isHidden = true
        // urlBar.removeFromSuperview()
        urlBarContainer.alpha = 0
        homeViewContainer.addSubview(homeView)
        // createHomeView()
        // createURLBar()

        // Clear the cache and cookies, starting a new session.
        WebCacheUtils.reset()

        // Zoom out on the screenshot, then slide down, then remove it.
        view.layoutIfNeeded()
        UIView.animate(withDuration: UIConstants.layout.deleteAnimationDuration, delay: 0, options: .curveEaseInOut, animations: {
            screenshotView.snp.remakeConstraints { make in
                make.center.equalTo(self.view)
                make.size.equalTo(self.view).multipliedBy(0.9)
            }
            self.view.layoutIfNeeded()
        }, completion: { _ in
            UIView.animate(withDuration: UIConstants.layout.deleteAnimationDuration, animations: {
                screenshotView.snp.remakeConstraints { make in
                    make.centerX.equalTo(self.view)
                    make.top.equalTo(self.view.snp.bottom)
                    make.size.equalTo(self.view).multipliedBy(0.9)
                }
                screenshotView.alpha = 0
                self.view.layoutIfNeeded()
            }, completion: { _ in
                // WKTDO: URLBar
                // self.urlBar.becomeFirstResponder()
                Toast(text: UIConstants.strings.eraseMessage).show()
                screenshotView.removeFromSuperview()
            })
        })

        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.eraseButton)
    }

    fileprivate func showSettings() {
        // WKTDO: URLBar
        // urlBar.shouldPresent = false
        let settingsViewController = SettingsViewController(searchEngineManager: searchEngineManager)
        navigationController!.pushViewController(settingsViewController, animated: true)
        navigationController!.setNavigationBarHidden(false, animated: true)

        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.settingsButton)
    }

    func ensureBrowsingMode() {
        // WKTDO: URLBar
        // guard urlBar != nil else { shouldEnsureBrowsingMode = true; return }
        // guard !urlBar.inBrowsingMode else { return }

        urlBarContainer.alpha = 1
        // urlBar.ensureBrowsingMode()

        // WKTODO: UrlBar
        // topURLBarConstraints?.activate()
        shouldEnsureBrowsingMode = false
    }

    func submit(url: URL) {
        // If this is the first navigation, show the browser and the toolbar.
        guard isViewLoaded else { initialUrl = url; return }

        if webViewContainer.isHidden {
            webViewContainer.isHidden = false
            homeView.removeFromSuperview()
            // WKTDO: URLBar
            // urlBar.inBrowsingMode = true

            if !showsToolsetInURLBar {
                browserToolbar.animateHidden(false, duration: UIConstants.layout.toolbarFadeAnimationDuration)
            }
        }

        webViewController.load(URLRequest(url: url))
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        guard UIDevice.current.userInterfaceIdiom == .phone else { return }

        // UIDevice.current.orientation isn't reliable. See https://bugzilla.mozilla.org/show_bug.cgi?id=1315370#c5
        // As a workaround, consider the phone to be in landscape if the new width is greater than the height.
        showsToolsetInURLBar = size.width > size.height

        coordinator.animate(alongsideTransition: { _ in
            // WKTDO: URLBar
            // self.urlBar.showToolset = self.showsToolsetInURLBar
            self.browserToolbar.animateHidden(self.homeView.superview != nil || self.showsToolsetInURLBar, duration: coordinator.transitionDuration)
        })
    }

    private func snapToolbars(scrollView: UIScrollView) {
        guard scrollBarState == .transitioning else { return }

        if scrollBarOffsetAlpha < 0.05 || scrollView.contentOffset.y < UIConstants.layout.urlBarHeight {
            showToolbars()
        } else {
            hideToolbars()
        }
    }

    private func showToolbars() {
        // WKTODO: ScrollView
        // guard let scrollView = browser.scrollView else { return }

        scrollBarState = .animating
        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration, delay: 0, options: .allowUserInteraction, animations: {
            // WKTDO: URLBar
            // self.urlBar.collapseUrlBar(expandAlpha: 1, collapseAlpha: 0)
//            self.urlBarTopConstraint.update(offset: 0)
            self.toolbarBottomConstraint.update(inset: 0)
            // WKTODO: scrollView
            // scrollView.bounds.origin.y += self.scrollBarOffsetAlpha * UIConstants.layout.urlBarHeight
            self.scrollBarOffsetAlpha = 0
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.scrollBarState = .expanded
        })
    }

    private func hideToolbars() {
        // WKTODO: scrollView
        // guard let scrollView = browser.scrollView else { return }

        scrollBarState = .animating
        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration, delay: 0, options: .allowUserInteraction, animations: {
            // WKTDO: URLBar
            // self.urlBar.collapseUrlBar(expandAlpha: 0, collapseAlpha: 1)
            // self.urlBarTopConstraint.update(offset: -UIConstants.layout.urlBarHeight + UIConstants.layout.collapsedUrlBarHeight)
            self.toolbarBottomConstraint.update(offset: UIConstants.layout.browserToolbarHeight)
            // WKTODO: scrollView
            // scrollView.bounds.origin.y += (self.scrollBarOffsetAlpha - 1) * UIConstants.layout.urlBarHeight
            self.scrollBarOffsetAlpha = 1
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.scrollBarState = .collapsed
        })
    }
}

//extension BrowserViewController: URLBarViewDelegate {
//    func urlBar(_ urlBar: URLBarView, didEnterText text: String) {
//        overlayView.setSearchQuery(query: text, animated: true)
//    }
//
//    func urlBar(_ urlBar: URLBarView, didSubmitText text: String) {
//        let text = text.trimmingCharacters(in: .whitespaces)
//
//        guard !text.isEmpty else {
//            // WKTODO: url
//            // urlBar.url = browser.url
//            return
//        }
//
//        var url = URIFixup.getURL(entry: text)
//        if url == nil {
//            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.typeQuery, object: TelemetryEventObject.searchBar)
//            url = searchEngineManager.activeEngine.urlForQuery(text)
//        } else {
//            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.typeURL, object: TelemetryEventObject.searchBar)
//        }
//        if let urlBarURL = url {
//            submit(url: urlBarURL)
//            urlBar.url = urlBarURL
//        }
//        urlBar.dismiss()
//    }
//
//    func urlBarDidDismiss(_ urlBar: URLBarView) {
//        overlayView.dismiss()
//        // WKTODO: isLoading
//        // urlBarContainer.isBright = !browser.isLoading
//    }
//
//    func urlBarDidPressDelete(_ urlBar: URLBarView) {
//        self.resetBrowser()
//    }
//
//    func urlBarDidFocus(_ urlBar: URLBarView) {
//        overlayView.present()
//        // WKTODO: change urlbar color
//        // urlBarContainer.isBright = false
//    }
//
//    func urlBarDidActivate(_ urlBar: URLBarView) {
//        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration) {
//            self.topURLBarConstraints.forEach { $0.activate() }
//            self.urlBarContainer.alpha = 1
//            self.view.layoutIfNeeded()
//        }
//    }
//
//    func urlBarDidDeactivate(_ urlBar: URLBarView) {
//        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration) {
//            self.topURLBarConstraints.forEach { $0.deactivate() }
//            self.urlBarContainer.alpha = 0
//            self.view.layoutIfNeeded()
//        }
//    }
//}

extension BrowserViewController: BrowserToolsetDelegate {
    func browserToolsetDidPressBack(_ browserToolset: BrowserToolset) {
        // WKTDO: URLBar
        // urlBar.dismiss()
        // // WKTODO: actions
        // browser.goBack()
    }

    func browserToolsetDidPressForward(_ browserToolset: BrowserToolset) {
        // WKTDO: URLBar
        // urlBar.dismiss()
        // WKTODO: actions
        // browser.goForward()
    }

    func browserToolsetDidPressReload(_ browserToolset: BrowserToolset) {
        // WKTDO: URLBar
        // urlBar.dismiss()
        // WKTODO: actions
        // browser.reload()
    }

    func browserToolsetDidPressStop(_ browserToolset: BrowserToolset) {
        // WKTDO: URLBar
        // urlBar.dismiss()
        // WKTODO: actions
        // browser.stop()
    }

    func browserToolsetDidPressSend(_ browserToolset: BrowserToolset) {
        // WKTODO: url
        // guard let url = browser.url else { return }
        // present(OpenUtils.buildShareViewController(url: url, anchor: browserToolset.sendButton), animated: true, completion: nil)
    }

    func browserToolsetDidPressSettings(_ browserToolbar: BrowserToolset) {
        showSettings()
    }
}

extension BrowserViewController: WebControllerDelegate {
    func webController(_ controller: WebController, scrollViewWillBeginDragging scrollView: UIScrollView) {
        lastScrollOffset = scrollView.contentOffset
        lastScrollTranslation = scrollView.panGestureRecognizer.translation(in: scrollView)
    }

    func webController(_ controller: WebController, scrollViewDidEndDragging scrollView: UIScrollView) {
        snapToolbars(scrollView: scrollView)
    }

    func webController(_ controller: WebController, scrollViewDidScroll scrollView: UIScrollView) {
        let translation = scrollView.panGestureRecognizer.translation(in: scrollView)
        let isDragging = scrollView.panGestureRecognizer.state != .possible

        // This will be 0 if we're moving but not dragging (i.e., gliding after dragging).
        let dragDelta = translation.y - lastScrollTranslation.y

        // This will match dragDelta unless the URL bar is transitioning.
        let offsetDelta = scrollView.contentOffset.y - lastScrollOffset.y

        lastScrollOffset = scrollView.contentOffset
        lastScrollTranslation = translation

        guard scrollBarState != .animating, !scrollView.isZooming else { return }

        guard scrollView.contentOffset.y + scrollView.frame.height < scrollView.contentSize.height && (scrollView.contentOffset.y > 0 || scrollBarOffsetAlpha > 0) else {
            // We're overscrolling, so don't do anything.
            return
        }

        if !isDragging && offsetDelta < 0 {
            // We're gliding up after dragging, so fully show the toolbars.
            showToolbars()
            return
        }

        let pageExtendsBeyondScrollView = scrollView.frame.height + UIConstants.layout.browserToolbarHeight + UIConstants.layout.urlBarHeight < scrollView.contentSize.height
        let toolbarsHiddenAtTopOfPage = scrollView.contentOffset.y <= 0 && scrollBarOffsetAlpha > 0

        guard isDragging, (dragDelta < 0 && pageExtendsBeyondScrollView) || toolbarsHiddenAtTopOfPage || scrollBarState == .transitioning else { return }

        let lastOffsetAlpha = scrollBarOffsetAlpha
        scrollBarOffsetAlpha = (0 ... 1).clamp(scrollBarOffsetAlpha - dragDelta / UIConstants.layout.urlBarHeight)
        switch scrollBarOffsetAlpha {
        case 0:
            scrollBarState = .expanded
        case 1:
            scrollBarState = .collapsed
        default:
            scrollBarState = .transitioning
        }

        // WKTDO: URLBar
        // self.urlBar.collapseUrlBar(expandAlpha: max(0, (1 - scrollBarOffsetAlpha * 2)), collapseAlpha: max(0, -(1 - scrollBarOffsetAlpha * 2)))
        // self.urlBarTopConstraint.update(offset: -scrollBarOffsetAlpha * (UIConstants.layout.urlBarHeight - UIConstants.layout.collapsedUrlBarHeight))
        self.toolbarBottomConstraint.update(offset: scrollBarOffsetAlpha * UIConstants.layout.browserToolbarHeight)
        scrollView.bounds.origin.y += (lastOffsetAlpha - scrollBarOffsetAlpha) * UIConstants.layout.urlBarHeight
        lastScrollOffset = scrollView.contentOffset
    }

    func webControllerShouldScrollToTop(_ controller: WebController) -> Bool {
        guard scrollBarOffsetAlpha == 0 else {
            showToolbars()
            return false
        }

        return true
    }

    func webController(_ controller: WebController, stateDidChange state: BrowserState) {}
}

extension BrowserViewController: HomeViewDelegate {
    func homeViewDidPressSettings(homeView: HomeView) {
        showSettings()
    }
}

extension BrowserViewController: OverlayViewDelegate {
    func overlayViewDidPressSettings(_ overlayView: OverlayView) {
        showSettings()
    }

    func overlayViewDidTouchEmptyArea(_ overlayView: OverlayView) {
        // WKTDO: URLBar
        // urlBar.dismiss()
    }

    func overlayView(_ overlayView: OverlayView, didSearchForQuery query: String) {
        if let url = searchEngineManager.activeEngine.urlForQuery(query) {
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.selectQuery, object: TelemetryEventObject.searchBar)
            submit(url: url)
            // WKTDO: URLBar
            // urlBar.url = url
        }

        // WKTDO: URLBar
        // urlBar.dismiss()
    }
    func overlayView(_ overlayView: OverlayView, didSubmitText text: String) {
        let text = text.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else {
            // WKTODO: url
            // urlBar.url = browser.url
            return
        }

        var url = URIFixup.getURL(entry: text)
        if url == nil {
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.typeQuery, object: TelemetryEventObject.searchBar)
            url = searchEngineManager.activeEngine.urlForQuery(text)
        } else {
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.typeURL, object: TelemetryEventObject.searchBar)
        }
        if let overlayURL = url {
            submit(url: overlayURL)
            // WKTDO: URLBar
            // urlBar.url = overlayURL
        }
        
        // WKTDO: URLBar
        // urlBar.dismiss()
    }
}

extension BrowserViewController: URLBarDelegate {
    func urlBar(_ URLBar: URLBar, stateDidChange state: URLBarState) {
        print(state)
        switch state {
        case .passive:
            urlBarConstraint.deactivate()
            overlayConstraint.deactivate()
            overlayView.dismiss()
        case .active:
            urlBarConstraint.activate()
            overlayConstraint.activate()
            overlayView.present()
        case .typing(let text):
            overlayView.setSearchQuery(query: text, animated: true)
        default: break
        }
    
        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration) {
            self.view.layoutIfNeeded()
        }
    }
}

extension BrowserViewController: KeyboardHelperDelegate {

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        UIView.animate(withDuration: state.animationDuration) {
            self.homeViewBottomConstraint.update(offset: -state.intersectionHeightForView(view: self.view))
            self.view.layoutIfNeeded()
        }
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        UIView.animate(withDuration: state.animationDuration) {
            self.homeViewBottomConstraint.update(offset: 0)
            self.view.layoutIfNeeded()
        }
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidHideWithState state: KeyboardState) { }
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) { }
}
