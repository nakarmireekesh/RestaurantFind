import UIKit

/// Grid tile for the Favourites screen: a static map thumbnail with the
/// restaurant's name and "category · area" underneath. Every tile is the same
/// height (two lines are always reserved for the name) so the grid stays even.
final class FavouriteTileCell: UICollectionViewCell {

    static let reuseID = "FavouriteTileCell"

    private let mapImageView = UIImageView()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()

    /// Guards against a reused cell showing a snapshot requested for a previous restaurant.
    private var snapshotToken: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setUp() {
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 18
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true

        mapImageView.translatesAutoresizingMaskIntoConstraints = false
        mapImageView.contentMode = .scaleAspectFill
        mapImageView.clipsToBounds = true
        mapImageView.backgroundColor = .tertiarySystemFill

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .preferredFont(forTextStyle: .headline)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.numberOfLines = 2

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .preferredFont(forTextStyle: .caption1)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 1

        contentView.addSubview(mapImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(subtitleLabel)

        let nameHeight = nameLabel.heightAnchor.constraint(equalToConstant: ceil(nameLabel.font.lineHeight * 2))
        nameHeight.priority = .defaultHigh

        NSLayoutConstraint.activate([
            mapImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            mapImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mapImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mapImageView.heightAnchor.constraint(equalToConstant: 108),

            nameLabel.topAnchor.constraint(equalTo: mapImageView.bottomAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            nameHeight,

            subtitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    func configure(with restaurant: Restaurant) {
        nameLabel.text = restaurant.name
        subtitleLabel.text = [restaurant.category, restaurant.locality?.nilIfEmpty]
            .compactMap { $0 }
            .joined(separator: " · ")

        let token = restaurant.id
        snapshotToken = token
        mapImageView.image = nil

        Task { [weak self] in
            let image = await MapSnapshotProvider.shared.snapshot(
                for: restaurant.coordinate,
                size: CGSize(width: 320, height: 200)
            )
            guard let self, self.snapshotToken == token else { return }
            UIView.transition(with: self.mapImageView, duration: 0.2, options: .transitionCrossDissolve) {
                self.mapImageView.image = image
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        snapshotToken = nil
        mapImageView.image = nil
    }
}
