import AppKit

/// Draws the dim mask of one screen: a dark layer above the slit and a dark
/// layer below it. The gap between them is the transparent slit.
///
/// Two resizable layers are used instead of a redraw of the full screen,
/// because a change of a layer frame is much less work for the GPU.
final class RulerView: NSView {
    private let topDim = CAGradientLayer()
    private let bottomDim = CAGradientLayer()
    /// The colour wash over the slit, like the tint of a reading ruler.
    private let tint = CAGradientLayer()

    /// Vertical centre of the slit, in the coordinates of this view.
    /// A nil value dims the full screen (the pointer is on a different screen).
    private(set) var slitCenterY: CGFloat?

    /// Height of the slit. The controller eases this value to the setting,
    /// so that a change of the height is a smooth movement.
    private(set) var slitHeight: CGFloat = CGFloat(Settings.slitHeight)

    /// Moves and resizes the slit. Both values change together, thus the
    /// layers are laid out one time only.
    func update(centerY: CGFloat?, height: CGFloat) {
        guard centerY != slitCenterY || height != slitHeight else { return }
        slitCenterY = centerY
        slitHeight = height
        layoutDimLayers()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = .clear
        for dim in [topDim, bottomDim, tint] {
            dim.autoresizingMask = []
            dim.actions = ["position": NSNull(), "bounds": NSNull(), "frame": NSNull()]
            layer?.addSublayer(dim)
        }
        // Solid end first, transparent end last. The middle stop is moved by
        // layoutDimLayers() to make the soft edge next to the slit.
        topDim.startPoint = CGPoint(x: 0.5, y: 1)
        topDim.endPoint = CGPoint(x: 0.5, y: 0)
        bottomDim.startPoint = CGPoint(x: 0.5, y: 0)
        bottomDim.endPoint = CGPoint(x: 0.5, y: 1)
        // The tint is soft at both ends, like the two dark layers.
        tint.startPoint = CGPoint(x: 0.5, y: 0)
        tint.endPoint = CGPoint(x: 0.5, y: 1)
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    override var isFlipped: Bool { false }

    override func layout() {
        super.layout()
        layoutDimLayers()
    }

    /// Applies the current settings and pointer position to the two layers.
    func layoutDimLayers() {
        let width = bounds.width
        let height = bounds.height
        guard width > 0, height > 0 else { return }

        let feather = CGFloat(Settings.feather)
        let solid = NSColor.black.withAlphaComponent(CGFloat(Settings.dimOpacity)).cgColor
        let clear = NSColor.black.withAlphaComponent(0).cgColor

        // No pointer on this screen: cover everything with one solid layer.
        guard let centerY = slitCenterY else {
            withoutAnimation {
                topDim.frame = bounds
                topDim.colors = [solid, solid]
                topDim.locations = [0, 1]
                bottomDim.isHidden = true
                tint.isHidden = true
                topDim.isHidden = false
            }
            return
        }

        let slitBottom = centerY - slitHeight / 2
        let slitTop = centerY + slitHeight / 2
        let topFrame = CGRect(x: 0, y: slitTop, width: width, height: max(0, height - slitTop))
        let bottomFrame = CGRect(x: 0, y: 0, width: width, height: max(0, slitBottom))

        withoutAnimation {
            topDim.isHidden = topFrame.height <= 0
            bottomDim.isHidden = bottomFrame.height <= 0
            topDim.frame = topFrame
            bottomDim.frame = bottomFrame
            for (dim, frame) in [(topDim, topFrame), (bottomDim, bottomFrame)] where !dim.isHidden {
                // The soft edge is a part of the layer height, never more than half of it.
                let fade = min(feather / frame.height, 0.5)
                dim.colors = [solid, solid, clear]
                dim.locations = [0, NSNumber(value: 1 - fade), 1]
            }
            layoutTint(slitBottom: slitBottom, slitTop: slitTop, width: width, feather: feather)
        }
    }

    /// The colour over the slit. It is soft at both ends, so that it starts
    /// and stops together with the dark layers.
    private func layoutTint(slitBottom: CGFloat, slitTop: CGFloat, width: CGFloat, feather: CGFloat) {
        guard let color = Settings.tintColor, slitTop > slitBottom else {
            tint.isHidden = true
            return
        }
        let frame = CGRect(x: 0, y: slitBottom, width: width, height: slitTop - slitBottom)
        let solid = color.withAlphaComponent(CGFloat(Settings.tintStrength)).cgColor
        let clear = color.withAlphaComponent(0).cgColor
        let fade = min(feather / frame.height, 0.45)

        tint.isHidden = false
        tint.frame = frame
        tint.colors = [clear, solid, solid, clear]
        tint.locations = [0, NSNumber(value: fade), NSNumber(value: 1 - fade), 1]
    }

    private func withoutAnimation(_ body: () -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        body()
        CATransaction.commit()
    }
}
