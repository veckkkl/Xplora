//
//  CircularProgressView.swift
//  Xplora
//

import UIKit

final class CircularProgressView: UIView {

    private let lineWidth: CGFloat = 5.5
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    override var intrinsicContentSize: CGSize { CGSize(width: 52, height: 52) }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Configure

    func configure(progress: Double) {
        progressLayer.strokeEnd = CGFloat(min(1, max(0, progress)))
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        trackLayer.frame = bounds
        progressLayer.frame = bounds

        let radius = (min(bounds.width, bounds.height) - lineWidth) / 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: -.pi / 2 + 2 * .pi,
            clockwise: true
        ).cgPath
        trackLayer.path = path
        progressLayer.path = path
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .clear

        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor.systemGray5.cgColor
        trackLayer.lineWidth = lineWidth
        trackLayer.lineCap = .round
        layer.addSublayer(trackLayer)

        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor.systemBlue.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)
    }
}
