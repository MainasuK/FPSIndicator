import UIKit

class FPSWindow: UIWindow {

    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)

        windowLevel = .init(rawValue: UIWindow.Level.statusBar.rawValue + 1)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

public class FPSIndicator {

    static var screenMargin = UIEdgeInsets(top: 44, left: 16, bottom: 44, right: 16)

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
        label.backgroundColor = .systemBackground
        label.font = .monospacedSystemFont(ofSize: 15, weight: .bold)
        return label
    }()

    var displayLink: CADisplayLink!

    private var count: Int = 0
    private var lastTimestamp: TimeInterval?


    override func viewDidLoad() {
        super.viewDidLoad()

        createDisplayLink()

        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false

        navigationController?.navigationBar.isUserInteractionEnabled = false
        let barAppearance = UINavigationBarAppearance()
        barAppearance.configureWithTransparentBackground()
        navigationItem.standardAppearance = barAppearance
        navigationItem.compactAppearance = barAppearance
        navigationItem.scrollEdgeAppearance = barAppearance
        if #available(iOS 15.0, *) {
            navigationItem.compactScrollEdgeAppearance = barAppearance
        }

        indicatorLabel.attributedText = NSAttributedString(string: "999.9FPS")
        indicatorLabel.sizeToFit()

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
            selector: #selector(FPSIndicatorViewController.step(displaylink:))
        )
        displayLink.add(to: RunLoop.main, forMode: .common)
    }

    private func configureIndicatorLabel(fps: Double) {
        indicatorLabel.text = String(format: "%.1fFPS", fps)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        if indicatorLabel.frame.origin.x < 0 {
            indicatorLabel.frame.origin = CGPoint(
                x: max(view.safeAreaInsets.left, FPSIndicator.screenMargin.left),
                y: max(view.safeAreaInsets.top, FPSIndicator.screenMargin.top)
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

    @objc private func step(displaylink: CADisplayLink) {
        guard let lastTimestamp = self.lastTimestamp else {
            self.lastTimestamp = displaylink.timestamp
            return
        }
        count += 1

        let duration = displaylink.timestamp - lastTimestamp
        guard duration >= 1.0 else { return }
        self.lastTimestamp = displaylink.timestamp
        defer { count = 0 }

        let fps = Double(count) / duration
        configureIndicatorLabel(fps: fps)
    }

}
