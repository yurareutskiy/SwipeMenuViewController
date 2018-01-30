import UIKit

// MARK: - SwipeMenuViewDelegate

public protocol SwipeMenuViewDelegate: class {

    /// Called before setup self.
    func swipeMenuView(_ swipeMenuView: SwipeMenuView, viewWillSetupAt currentIndex: Int)

    /// Called after setup self.
    func swipeMenuView(_ swipeMenuView: SwipeMenuView, viewDidSetupAt currentIndex: Int)

    /// Called before swiping the page.
    func swipeMenuView(_ swipeMenuView: SwipeMenuView, willChangeIndexFrom fromIndex: Int, to toIndex: Int)

    /// Called after swiping the page.
    func swipeMenuView(_ swipeMenuView: SwipeMenuView, didChangeIndexFrom fromIndex: Int, to toIndex: Int)
}

extension SwipeMenuViewDelegate {
    public func swipeMenuView(_ swipeMenuView: SwipeMenuView, viewWillSetupAt currentIndex: Int) { }
    public func swipeMenuView(_ swipeMenuView: SwipeMenuView, viewDidSetupAt currentIndex: Int) { }
    public func swipeMenuView(_ swipeMenuView: SwipeMenuView, willChangeIndexFrom fromIndex: Int, to toIndex: Int) { }
    public func swipeMenuView(_ swipeMenuView: SwipeMenuView, didChangeIndexFrom fromIndex: Int, to toIndex: Int) { }
}

// MARK: - SwipeMenuViewDataSource

public protocol SwipeMenuViewDataSource: class {

    /// Return the number of pages in `SwipeMenuView`.
    func numberOfPages(in swipeMenuView: SwipeMenuView) -> Int

    /// Return strings to be displayed at the specified tag in `SwipeMenuView`.
    func swipeMenuView(_ swipeMenuView: SwipeMenuView, titleForPageAt index: Int) -> String

    /// Return strings to be displayed at the specified tag in `SwipeMenuView`.
    func swipeMenuView(_ swipeMenuView: SwipeMenuView, tabForPageAt index: Int) -> UIView?

    /// Return a ViewController to be displayed at the specified page in `SwipeMenuView`.
    func swipeMenuView(_ swipeMenuView: SwipeMenuView, viewControllerForPageAt index: Int) -> UIViewController
}

extension SwipeMenuViewDataSource {
    public func swipeMenuView(_ swipeMenuView: SwipeMenuView, titleForPageAt index: Int) -> String {
        return ""
    }

    public func swipeMenuView(_ swipeMenuView: SwipeMenuView, tabForPageAt index: Int) -> UIView? {
        return nil
    }
}

// MARK: - SwipeMenuView

open class SwipeMenuView: UIView {

    /// An object conforms `SwipeMenuViewDelegate`. Provide views to populate the `SwipeMenuView`.
    open weak var delegate: SwipeMenuViewDelegate?

    /// An object conforms `SwipeMenuViewDataSource`. Provide views and respond to `SwipeMenuView` events.
    open weak var dataSource: SwipeMenuViewDataSource?

    open fileprivate(set) var tabView: TabView? {
        didSet {
            guard let tabView = tabView else { return }
            tabView.dataSource = self
            addSubview(tabView)
            layout(tabView: tabView)
        }
    }

    open fileprivate(set) var contentScrollView: ContentScrollView? {
        didSet {
            guard let contentScrollView = contentScrollView else { return }
            contentScrollView.delegate = self
            contentScrollView.dataSource = self
            addSubview(contentScrollView)
            layout(contentScrollView: contentScrollView)
        }
    }

    public var options: SwipeMenuViewOptions

    fileprivate var isLayoutingSubviews: Bool = false

    fileprivate var pageCount: Int {
        return dataSource?.numberOfPages(in: self) ?? 0
    }

    fileprivate var isJumping: Bool = false
    fileprivate var isPortrait: Bool = true
    fileprivate var bundle = ViewBundle<UIView>()
    fileprivate var queue = [String: [UIView]]()
    fileprivate var registeredCells = [String: UIView]()

    /// The index of the front page in `SwipeMenuView` (read only).
    open private(set) var currentIndex: Int = 0
    private var jumpingToIndex: Int?

    public init(frame: CGRect, options: SwipeMenuViewOptions? = nil) {

        if let options = options {
            self.options = options
        } else {
            self.options = .init()
        }

        super.init(frame: frame)
    }

    public required init?(coder aDecoder: NSCoder) {

        self.options = .init()

        super.init(coder: aDecoder)
    }

    open override func layoutSubviews() {

        isLayoutingSubviews = true
        super.layoutSubviews()
        reloadData(isOrientationChange: true)
    }

    open override func didMoveToSuperview() {
        super.didMoveToSuperview()

        setup()
    }

    // MARK: - Register Cell
    public func register(_ nib: UINib, forTabWithReuseIdentifier identifier: String) {
        bundle.register(ofNib: nib, for: identifier)
    }

    public func register<T: UIView>(_ tabClass: T.Type, forTabWithReuseIdentifier identifier: String) {
        bundle.register(ofClass: tabClass, for: identifier)
    }

    public func dequeueReusableTab(with identifier: String) -> UIView {
        let tab = bundle.instantiate(with: identifier)
        return tab
    }



    /// Reloads all `SwipeMenuView` item views with the dataSource and refreshes the display.
    public func reloadData(options: SwipeMenuViewOptions? = nil, default defaultIndex: Int? = nil, isOrientationChange: Bool = false) {

        if let options = options {
            self.options = options
        }

        isLayoutingSubviews = isOrientationChange

        if !isLayoutingSubviews {
            reset()
            setup(default: defaultIndex ?? currentIndex)
        }

        jump(to: defaultIndex ?? currentIndex, animated: false)

        isLayoutingSubviews = false
    }

    /// Jump to the selected page.
    public func jump(to index: Int, animated: Bool) {
        guard let tabView = tabView, let contentScrollView = contentScrollView else { return }
        if currentIndex != index {
            delegate?.swipeMenuView(self, willChangeIndexFrom: currentIndex, to: index)
        }
        jumpingToIndex = index

        tabView.jump(to: index)
        contentScrollView.jump(to: index, animated: animated)
    }

    /// Notify changing orientaion to `SwipeMenuView` before it.
    public func willChangeOrientation() {
        isLayoutingSubviews = true
    }

    fileprivate func update(from fromIndex: Int, to toIndex: Int) {

        if !isLayoutingSubviews {
            delegate?.swipeMenuView(self, willChangeIndexFrom: fromIndex, to: toIndex)
        }

        tabView?.update(toIndex)
        contentScrollView?.update(toIndex)
        if !isJumping {
            // delay setting currentIndex until end scroll when jumping
            currentIndex = toIndex
        }

        if !isJumping && !isLayoutingSubviews {
            delegate?.swipeMenuView(self, didChangeIndexFrom: fromIndex, to: toIndex)
        }
    }

    // MARK: - Setup
    private func setup(default defaultIndex: Int = 0) {

        delegate?.swipeMenuView(self, viewWillSetupAt: defaultIndex)

        backgroundColor = .clear

        tabView = TabView(frame: CGRect(x: 0, y: 0, width: frame.width, height: options.tabView.height), options: options.tabView)
        tabView?.clipsToBounds = options.tabView.clipsToBounds
        addTabItemGestures()

        contentScrollView = ContentScrollView(frame: CGRect(x: 0, y: options.tabView.height, width: frame.width, height: frame.height - options.tabView.height), default: defaultIndex, options: options.contentScrollView)
        contentScrollView?.clipsToBounds = options.contentScrollView.clipsToBounds

        tabView?.update(defaultIndex)
        contentScrollView?.update(defaultIndex)
        currentIndex = defaultIndex

        delegate?.swipeMenuView(self, viewDidSetupAt: defaultIndex)
    }

    private func layout(tabView: TabView) {

        tabView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tabView.topAnchor.constraint(equalTo: self.topAnchor),
            tabView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            tabView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            tabView.heightAnchor.constraint(equalToConstant: options.tabView.height)
            ])
    }

    private func layout(contentScrollView: ContentScrollView) {

        contentScrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentScrollView.topAnchor.constraint(equalTo: self.topAnchor, constant: options.tabView.height),
            contentScrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
            ])
    }

    private func reset() {

        if !isLayoutingSubviews {
            currentIndex = 0
        }

        if let tabView = tabView, let contentScrollView = contentScrollView {
            tabView.removeFromSuperview()
            contentScrollView.removeFromSuperview()
            tabView.reset()
            contentScrollView.reset()
        }
    }
}

// MARK: - TabViewDataSource

extension SwipeMenuView: TabViewDataSource {

    public func numberOfItems(in menuView: TabView) -> Int {
        return dataSource?.numberOfPages(in: self) ?? 0
    }

    public func tabView(_ tabView: TabView, tabForPageAt index: Int) -> UIView? {
        return dataSource?.swipeMenuView(self, tabForPageAt: index)
    }

    public func tabView(_ tabView: TabView, titleForItemAt index: Int) -> String? {
        return dataSource?.swipeMenuView(self, titleForPageAt: index)
    }
}

// MARK: - GestureRecognizer

extension SwipeMenuView {

    fileprivate var tapGestureRecognizer: UITapGestureRecognizer {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapItemView(_:)))
        gestureRecognizer.numberOfTapsRequired = 1
        gestureRecognizer.cancelsTouchesInView = false
        return gestureRecognizer
    }

    fileprivate func addTabItemGestures() {
        tabView?.itemViews.forEach {
            $0.addGestureRecognizer(tapGestureRecognizer)
        }
    }

    @objc func tapItemView(_ recognizer: UITapGestureRecognizer) {

        guard let itemView = recognizer.view as? TabItemView, let tabView = tabView, let index: Int = tabView.itemViews.index(of: itemView), let contentScrollView = contentScrollView else { return }
        if currentIndex == index { return }

        isJumping = true
        jumpingToIndex = index

        contentScrollView.jump(to: index, animated: true)
        moveTabItem(tabView: tabView, index: index)

        update(from: currentIndex, to: index)
    }

    private func moveTabItem(tabView: TabView, index: Int) {

        switch options.tabView.addition {
        case .underline:
            tabView.animateUnderlineView(index: index, completion: nil)
        case .none:
            tabView.update(index)
        }
    }
}

// MARK: - UIScrollViewDelegate

extension SwipeMenuView: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {

        if isJumping || isLayoutingSubviews { return }

        // update currentIndex
        if scrollView.contentOffset.x >= frame.width * CGFloat(currentIndex + 1) {
            update(from: currentIndex, to: currentIndex + 1)
        } else if scrollView.contentOffset.x <= frame.width * CGFloat(currentIndex - 1) {
            update(from: currentIndex, to: currentIndex - 1)
        }

        updateTabViewAddition(by: scrollView)
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {

        if isJumping || isLayoutingSubviews {
            if let toIndex = jumpingToIndex {
                delegate?.swipeMenuView(self, didChangeIndexFrom: currentIndex, to: toIndex)
                currentIndex = toIndex
                jumpingToIndex = nil
            }
            isJumping = false
            isLayoutingSubviews = false
            return
        }

        updateTabViewAddition(by: scrollView)
    }

    /// update addition in tab view
    private func updateTabViewAddition(by scrollView: UIScrollView) {
        moveUnderlineView(scrollView: scrollView)
    }

    /// update underbar position
    private func moveUnderlineView(scrollView: UIScrollView) {

        if let tabView = tabView, let contentScrollView = contentScrollView {

            let ratio = scrollView.contentOffset.x.truncatingRemainder(dividingBy: contentScrollView.frame.width) / contentScrollView.frame.width

            switch scrollView.contentOffset.x {
            case let offset where offset >= frame.width * CGFloat(currentIndex):
                tabView.moveUnderlineView(index: currentIndex, ratio: ratio, direction: .forward)
            case let offset where offset < frame.width * CGFloat(currentIndex):
                tabView.moveUnderlineView(index: currentIndex, ratio: ratio, direction: .reverse)
            default:
                break
            }
        }
    }
}

// MARK: - ContentScrollViewDataSource
extension SwipeMenuView: ContentScrollViewDataSource {

    public func numberOfPages(in contentScrollView: ContentScrollView) -> Int {
        return dataSource?.numberOfPages(in: self) ?? 0
    }

    public func contentScrollView(_ contentScrollView: ContentScrollView, viewForPageAt index: Int) -> UIView? {
        return dataSource?.swipeMenuView(self, viewControllerForPageAt: index).view
    }
}
