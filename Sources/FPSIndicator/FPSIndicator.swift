import UIKit

class FPSWindow: UIWindow {

    static let userInteractFPSViewTag: Int = 377463422837

    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)

        windowLevel = .init(rawValue: UIWindow.Level.statusBar.rawValue + 1)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for view in subviews {
            guard let hitTestView = view.hitTest(point, with: event),
                  hitTestView.tag == FPSWindow.userInteractFPSViewTag else {
                continue
            }
            return true
        }

        return false
    }

}

public class FPSIndicator {

    static var screenMargin = UIEdgeInsets(top: 44, left: 8, bottom: 44, right: 8)
    static var backgroundColor: UIColor = .secondarySystemBackground
    /// attributes for "999" in 999.9FPS
    static var fpsNumberAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
    ]
    /// attributes for "FPS" in 999.9FPS
    static var fpsTextAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
    ]
    static var fpsNumberColor: (Double) -> UIColor = { fps in
        if fps >= 55 { return .systemGreen}
        if fps >= 50 { return .systemTeal }
        if fps >= 40 { return .systemYellow }
        return .systemRed
    }
    static var fpsTextColor: (Double) -> UIColor = { fps in
        return .label
    }

    let window: FPSWindow

    public init(windowScene: UIWindowScene) {
        self.window = FPSWindow(windowScene: windowScene)

        window.makeKeyAndVisible()
        window.rootViewController = UINavigationController(
            rootViewController: FPSIndicatorViewController()
        )
    }
}

class FPSIndicatorViewController: UIViewController {

    let indicatorLabel: UILabel = {
        let label = UILabel()
        label.tag = FPSWindow.userInteractFPSViewTag
        label.layer.cornerCurve = .continuous
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        return label
    }()

    var displayLink: CADisplayLink!

    static let fpsNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.maximumIntegerDigits = 3
        formatter.minimumIntegerDigits = 1
        formatter.roundingMode = .up
        return formatter
    }()
    static let fpsNumberLength = 5 // e.g. 999.9

    private var count: Int = 0
    private var lastTimestamp: TimeInterval?


    override func viewDidLoad() {
        super.viewDidLoad()

        createDisplayLink()

        view.backgroundColor = .clear

        navigationController?.navigationBar.isUserInteractionEnabled = false

        let barAppearance = UINavigationBarAppearance()
        barAppearance.configureWithTransparentBackground()
        navigationItem.standardAppearance = barAppearance
        navigationItem.compactAppearance = barAppearance
        navigationItem.scrollEdgeAppearance = barAppearance

        // may still needs fallback
        navigationController?.navigationBar.alpha = 0

        configureIndicatorLabel(fps: 999.999)

        indicatorLabel.frame.origin = CGPoint(x: -999, y: -999)
        view.addSubview(indicatorLabel)

        let panGestureRecognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(FPSIndicatorViewController.indicatorLabelPanGestureRecognizer(_:))
        )
        indicatorLabel.addGestureRecognizer(panGestureRecognizer)
        indicatorLabel.isUserInteractionEnabled = true
    }

    private func createDisplayLink() {
        self.displayLink = CADisplayLink(
            target: self,
            selector: #selector(FPSIndicatorViewController.step(displayLink:))
        )
        displayLink.add(to: RunLoop.main, forMode: .common)
    }

    private func configureIndicatorLabel(fps: Double) {
        guard let formattedFPS = FPSIndicatorViewController.fpsNumberFormatter.string(from: NSNumber(value: fps)) else { return }
        let padding = String(repeating: " ", count: (FPSIndicatorViewController.fpsNumberLength - formattedFPS.count))

        indicatorLabel.attributedText = {
            let FPS = "FPS"

            let attributedString = NSMutableAttributedString()
            let fpsNumberAttributes: [NSAttributedString.Key: Any] = {
                var attributes = FPSIndicator.fpsNumberAttributes
                attributes[.foregroundColor] = FPSIndicator.fpsNumberColor(fps)
                return attributes
            }()
            attributedString.append(NSAttributedString(string: "\(padding)\(formattedFPS)", attributes: fpsNumberAttributes))

            let fpsTextAttributes: [NSAttributedString.Key: Any] = {
                var attributes = FPSIndicator.fpsTextAttributes
                attributes[.foregroundColor] = FPSIndicator.fpsTextColor(fps)
                return attributes
            }()
            attributedString.append(NSAttributedString(string: FPS, attributes: fpsTextAttributes))

            var kernRange = (attributedString.string as NSString).range(of: FPS)
            kernRange.location -= 1
            kernRange.length = 1
            attributedString.addAttributes([.kern: 2], range: kernRange)

            return attributedString
        }()

        indicatorLabel.backgroundColor = FPSIndicator.backgroundColor
        indicatorLabel.sizeToFit()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        if indicatorLabel.frame.origin.x < 0 {
            indicatorLabel.frame.origin = CGPoint(
                x: view.frame.width - indicatorLabel.frame.width - max(view.safeAreaInsets.right, FPSIndicator.screenMargin.right),
                y: max(view.safeAreaInsets.top + 8, FPSIndicator.screenMargin.top)     // 8pt padding to navigation bar
            )
        }
    }

    @objc private func indicatorLabelPanGestureRecognizer(_ sender: UIPanGestureRecognizer) {
        guard sender.view === indicatorLabel else { return }
        let translation = sender.translation(in: self.view)

        let screenMargin = FPSIndicator.screenMargin
        let x: CGFloat = max(0.5 * indicatorLabel.frame.width + screenMargin.left, min(
            indicatorLabel.center.x + translation.x,
            self.view.frame.width - 0.5 * indicatorLabel.frame.width - screenMargin.right
        ))
        let y: CGFloat = max(0.5 * indicatorLabel.frame.height + screenMargin.top, min(
            indicatorLabel.center.y + translation.y,
            self.view.frame.height - 0.5 * indicatorLabel.frame.height - screenMargin.bottom
        ))

        indicatorLabel.center = CGPoint(x: x, y: y)

        sender.setTranslation(CGPoint(x: 0, y: 0), in: sender.view)
    }

    @objc private func step(displayLink: CADisplayLink) {
        guard let lastTimestamp = self.lastTimestamp else {
            self.lastTimestamp = displayLink.timestamp
            return
        }
        count += 1

        let duration = displayLink.timestamp - lastTimestamp
        guard duration >= 1.0 else { return }
        self.lastTimestamp = displayLink.timestamp
        defer { count = 0 }

        let fps = Double(count) / duration
        configureIndicatorLabel(fps: fps)
    }

}
