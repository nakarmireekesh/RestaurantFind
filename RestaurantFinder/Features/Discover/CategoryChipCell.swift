import UIKit

/// A single pill in the Discover category filter bar. Self-sizes to its title.
final class CategoryChipCell: UICollectionViewCell {

    static let reuseID = "CategoryChipCell"

    private let container = UIView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        container.translatesAutoresizingMaskIntoConstraints = false
        container.layer.cornerCurve = .continuous
        container.layer.borderWidth = 1
        contentView.addSubview(container)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        container.addSubview(label)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 7),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -7),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        container.layer.cornerRadius = container.bounds.height / 2
    }

    func configure(title: String, selected: Bool) {
        label.text = title
        label.textColor = selected ? .white : .label
        container.backgroundColor = selected ? .tintColor : .secondarySystemBackground
        container.layer.borderColor = (selected ? UIColor.clear : UIColor.separator).cgColor
    }
}
