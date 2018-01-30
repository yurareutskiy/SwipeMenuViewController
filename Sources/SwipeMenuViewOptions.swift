import UIKit

// MARK: - SwipeMenuViewOptions
public struct SwipeMenuViewOptions {

    public struct TabView {

        public enum Style {
            case flexible
            case segmented
            // TODO: case infinity
        }

        public enum Addition {
            case underline
            case none
        }

        public struct ItemView {
            /// ItemView width. Defaults to `100.0`.
            public var width: CGFloat = 100.0

            /// ItemView side margin. Defaults to `5.0`.
            public var margin: CGFloat = 5.0

            /// ItemView font. Defaults to `14 pt as bold SystemFont`.
            public var font: UIFont = UIFont.boldSystemFont(ofSize: 14)

            /// ItemView clipsToBounds. Defaults to `true`.
            public var clipsToBounds: Bool = true

            /// ItemView textColor. Defaults to `.lightGray`.
            public var textColor: UIColor = UIColor(red: 170 / 255, green: 170 / 255, blue: 170 / 255, alpha: 1.0)

            /// ItemView selected textColor. Defaults to `.black`.
            public var selectedTextColor: UIColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        }

        public struct UndelineView {
            /// UndelineView height. Defaults to `2.0`.
            public var height: CGFloat = 2.0

            /// UndelineView side margin. Defaults to `0.0`.
            public var margin: CGFloat = 0.0

            /// UndelineView backgroundColor. Defaults to `.black`.
            public var backgroundColor: UIColor = .black

            /// UnderlineView animating duration. Defaults to `0.3`.
            public var animationDuration: CGFloat = 0.3
        }


        /// TabView height. Defaults to `44.0`.
        public var height: CGFloat = 44.0

        /// TabView side margin. Defaults to `0.0`.
        public var margin: CGFloat = 0.0

        /// TabView background color. Defaults to `.clear`.
        public var backgroundColor: UIColor = .clear

        /// TabView clipsToBounds. Defaults to `true`.
        public var clipsToBounds: Bool = true

        /// TabView style. Defaults to `.flexible`. Style type has [`.flexible` , `.segmented`].
        public var style: Style = .flexible

        /// TabView addition. Defaults to `.underline`. Addition type has [`.underline`, `.none`].
        public var addition: Addition = .underline

        /// TabView adjust width or not. Defaults to `true`.
        public var needsAdjustItemViewWidth: Bool = true

        /// Convert the text color of ItemView to selected text color by scroll rate of ContentScrollView. Defaults to `true`.
        public var needsConvertTextColorRatio: Bool = true

        /// TabView enable safeAreaLayout. Defaults to `true`.
        public var isSafeAreaEnabled: Bool = true

        /// ItemView options
        public var itemView = ItemView()

        /// UnderlineView options
        public var underlineView = UndelineView()
    }

    public struct ContentScrollView {

        /// ContentScrollView backgroundColor. Defaults to `.clear`.
        public var backgroundColor: UIColor = .clear

        /// ContentScrollView clipsToBounds. Defaults to `true`.
        public var clipsToBounds: Bool = true

        /// ContentScrollView scroll enabled. Defaults to `true`.
        public var isScrollEnabled: Bool = true

        /// ContentScrollView enable safeAreaLayout. Defaults to `true`.
        public var isSafeAreaEnabled: Bool = true
    }

    /// TabView and ContentScrollView Enable safeAreaLayout. Defaults to `true`.
    public var isSafeAreaEnabled: Bool = true {
        didSet {
            tabView.isSafeAreaEnabled = isSafeAreaEnabled
            contentScrollView.isSafeAreaEnabled = isSafeAreaEnabled
        }
    }

    /// TabView options
    public var tabView = TabView()

    /// ContentScrollView options
    public var contentScrollView = ContentScrollView()

    public init() { }
}
