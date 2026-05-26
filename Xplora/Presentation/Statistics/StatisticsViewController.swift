//
//  StatisticsViewController.swift
//  Xplora
//

import UIKit

final class StatisticsViewController: UIViewController {

    private let viewModel: StatisticsViewModel
    private let scrollAnimator = StatisticsCardsScrollAnimator()
    private var cardViews: [StatisticsCardView] = []

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.alwaysBounceVertical = true
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.clipsToBounds = false
        return sv
    }()

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .large)
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    private let errorLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.textColor = .secondaryLabel
        l.font = .systemFont(ofSize: 16)
        l.numberOfLines = 0
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Init

    init(viewModel: StatisticsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bind()
        viewModel.viewDidLoad()
    }

    // MARK: - Setup

    private func setupView() {
        title = "Исследовано"
        view.backgroundColor = .systemGroupedBackground
        navigationController?.navigationBar.prefersLargeTitles = true

        scrollView.delegate = self

        view.addSubview(scrollView)
        view.addSubview(activityIndicator)
        view.addSubview(errorLabel)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    private func bind() {
        viewModel.onStateChange = { [weak self] state in
            self?.apply(state)
        }
    }

    // MARK: - State

    private func apply(_ state: StatisticsViewState) {
        switch state {
        case .idle:
            break
        case .loading:
            activityIndicator.startAnimating()
            scrollView.isHidden = true
            errorLabel.isHidden = true
        case .content(let data):
            activityIndicator.stopAnimating()
            errorLabel.isHidden = true
            scrollView.isHidden = false
            renderCards(data)
        case .error(let message):
            activityIndicator.stopAnimating()
            scrollView.isHidden = true
            errorLabel.isHidden = false
            errorLabel.text = message
        }
    }

    private func renderCards(_ data: StatisticsViewData) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        cardViews.removeAll()

        var cards: [StatisticsCardView] = []

        let totalCard = StatisticsCardView()
        totalCard.configure(with: data.totalCard)
        cards.append(totalCard)

        let continentsCard = StatisticsCardView()
        continentsCard.configure(with: data.continentsCard)
        cards.append(continentsCard)

        let countriesCard = StatisticsCardView()
        countriesCard.configure(with: data.countriesCard)
        cards.append(countriesCard)

        for cardData in data.continentCards {
            let card = StatisticsCardView()
            card.configure(with: cardData)
            cards.append(card)
        }

        for (index, card) in cards.enumerated() {
            card.layer.zPosition = CGFloat(index)
            stackView.addArrangedSubview(card)
        }
        cardViews = cards
    }
}

// MARK: - UIScrollViewDelegate

extension StatisticsViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let collapseStartY = scrollView.adjustedContentInset.top + 16
        scrollAnimator.update(cards: cardViews, in: view, collapseStartY: collapseStartY)
    }
}
