//
//  LegalDocumentViewController.swift
//  Xplora
//

import SnapKit
import UIKit

/// Reusable read-only screen for bundled legal/about documents. Receives an
/// already-loaded `LegalDocument`; it does not perform any file access itself.
final class LegalDocumentViewController: UIViewController {
    private enum Constants {
        static let horizontalInset: CGFloat = 22
        static let verticalInset: CGFloat = 20
    }

    private let document: LegalDocument

    private let textView = UITextView()

    init(document: LegalDocument) {
        self.document = document
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        renderContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            tabBarController?.tabBar.isHidden = false
        }
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        title = document.title
        navigationItem.largeTitleDisplayMode = .never

        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.alwaysBounceVertical = true
        textView.textContainerInset = UIEdgeInsets(
            top: Constants.verticalInset,
            left: Constants.horizontalInset,
            bottom: Constants.verticalInset,
            right: Constants.horizontalInset
        )
        textView.textContainer.lineFragmentPadding = 0
        textView.adjustsFontForContentSizeCategory = true
        view.addSubview(textView)
    }

    private func setupConstraints() {
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func renderContent() {
        textView.attributedText = MarkdownAttributedBuilder.attributedString(from: document.markdownBody)
    }
}
