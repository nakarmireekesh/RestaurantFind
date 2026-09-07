import UIKit

/// Card-style list row: a category icon badge, name, "category • distance"
/// subtitle and a heart toggle.
final class RestaurantCell: UITableViewCell {

    static let reuseID = "RestaurantCell"

    /// Called when the heart button is tapped.
    var onToggleFavourite: (() -> Void)?

    private let card = UIView()
    private let iconBackground = UIView()
    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let favouriteButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setUp() {
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 16
        card.layer.cornerCurve = .continuous
        contentView.addSubview(card)

        iconBackground.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.backgroundColor = UIColor.tintColor.withAlphaComponent(0.12)
        iconBackground.layer.cornerRadius = 22
        iconBackground.layer.cornerCurve = .continuous

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = .tintColor
        iconView.contentMode = .center
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)

        nameLabel.font = .preferredFont(forTextStyle: .headline)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.numberOfLines = 2

        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 1

        favouriteButton.translatesAutoresizingMaskIntoConstraints = false
        favouriteButton.setContentHuggingPriority(.required, for: .horizontal)
        favouriteButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        favouriteButton.addTarget(self, action: #selector(didTapFavourite), for: .touchUpInside)

        iconBackground.addSubview(iconView)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 3

        let rowStack = UIStackView(arrangedSubviews: [iconBackground, textStack, favouriteButton])
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 14
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(rowStack)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            rowStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            rowStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            rowStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            rowStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: 8),

            iconBackground.widthAnchor.constraint(equalToConstant: 44),
            iconBackground.heightAnchor.constraint(equalToConstant: 44),

            iconView.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),

            favouriteButton.widthAnchor.constraint(equalToConstant: 44),
            favouriteButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    func configure(with row: DiscoverViewModel.RestaurantRow) {
        nameLabel.text = row.restaurant.name
        subtitleLabel.text = [row.restaurant.category, row.distanceText]
            .compactMap { $0 }
            .joined(separator: "  •  ")
        iconView.image = UIImage(systemName: RestaurantCategoryStyle.symbolName(for: row.restaurant.category))

        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: row.isFavourite ? "heart.fill" : "heart")
        config.baseForegroundColor = .tintColor
        favouriteButton.configuration = config
        favouriteButton.accessibilityLabel = row.isFavourite
            ? "Remove \(row.restaurant.name) from favourites"
            : "Add \(row.restaurant.name) to favourites"
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        UIView.animate(withDuration: 0.15) {
            self.card.transform = highlighted
                ? CGAffineTransform(scaleX: 0.98, y: 0.98)
                : .identity
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onToggleFavourite = nil
        card.transform = .identity
    }

    @objc private func didTapFavourite() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        UIView.animate(withDuration: 0.1, animations: {
            self.favouriteButton.transform = CGAffineTransform(scaleX: 0.82, y: 0.82)
        }, completion: { _ in
            UIView.animate(withDuration: 0.1) { self.favouriteButton.transform = .identity }
        })
        onToggleFavourite?()
    }
}
