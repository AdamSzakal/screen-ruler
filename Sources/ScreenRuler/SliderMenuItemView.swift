import AppKit

/// A menu row with a title, the current value and a slider.
final class SliderMenuItemView: NSView {
    private let titleLabel = NSTextField(labelWithString: "")
    private let valueLabel = NSTextField(labelWithString: "")
    private let slider = NSSlider()
    private let format: (Double) -> String
    private let onChange: (Double) -> Void

    init(title: String,
         range: ClosedRange<Double>,
         value: Double,
         format: @escaping (Double) -> String,
         onChange: @escaping (Double) -> Void) {
        self.format = format
        self.onChange = onChange
        super.init(frame: NSRect(x: 0, y: 0, width: 240, height: 48))

        titleLabel.frame = NSRect(x: 14, y: 28, width: 150, height: 16)
        titleLabel.font = .menuFont(ofSize: 12)

        valueLabel.frame = NSRect(x: 164, y: 28, width: 62, height: 16)
        valueLabel.alignment = .right
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        valueLabel.textColor = .secondaryLabelColor

        slider.frame = NSRect(x: 14, y: 6, width: 212, height: 20)
        slider.minValue = range.lowerBound
        slider.maxValue = range.upperBound
        slider.doubleValue = value
        slider.isContinuous = true
        slider.target = self
        slider.action = #selector(sliderMoved)

        titleLabel.stringValue = title
        valueLabel.stringValue = format(value)
        for view in [titleLabel, valueLabel, slider] { addSubview(view) }
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    /// Shows a value that was changed somewhere else, e.g. by the scroll shortcut.
    var value: Double {
        get { slider.doubleValue }
        set {
            slider.doubleValue = newValue
            valueLabel.stringValue = format(newValue)
        }
    }

    @objc private func sliderMoved() {
        valueLabel.stringValue = format(slider.doubleValue)
        onChange(slider.doubleValue)
    }
}
