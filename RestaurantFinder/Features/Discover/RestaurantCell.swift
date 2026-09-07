import UIKit

/// List cell: restaurant name, "category · distance" subtitle and a heart toggle.
final class RestaurantCell: UITableViewCell {

    static let reuseID = "RestaurantCell"

    /// Called when the heart button is tapped.
    var onToggleFavourite: (() -> Void)?

    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let favouriteButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setUp() {
        accessoryType = .disclosureIndicator

        nameLabel.font = .preferredFont(forTextStyle: .headline)
        nameLabel.adjustsFontForContentSizeCategory = true

        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = .secondaryLabel

        favouriteButton.setContentHuggingPriority(.required, for: .horizontal)
        favouriteButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        favouriteButton.addTarget(self, action: #selector(didTapFavourite), for: .touchUpInside)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let rowStack = UIStackView(arrangedSubviews: [textStack, favouriteButton])
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 12
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(rowStack)

        NSLayoutConstraint.activate([
            rowStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            rowStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            rowStack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            rowStack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
        ])
    }

    func configure(with row: DiscoverViewModel.RestaurantRow) {
        nameLabel.text = row.restaurant.name
        subtitleLabel.text = [row.restaurant.category, row.distanceText]
            .compactMap { $0 }
            .joined(separator: " · ")

        let symbol = row.isFavourite ? "heart.fill" : "heart"
        favouriteButton.setImage(UIImage(systemName: symbol), for: .normal)
        favouriteButton.accessibilityLabel = row.isFavourite
            ? "Remove \(row.restaurant.name) from favourites"
            : "Add \(row.restaurant.name) to favourites"
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onToggleFavourite = nil
    }

    @objc private func didTapFavourite() {
        onToggleFavourite?()
    }
}
