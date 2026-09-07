import UIKit

/// The Favourites tab: a two-column grid of saved restaurants, each shown as a
/// map thumbnail tile. Long-press a tile to remove it.
final class FavouritesViewController: UIViewController {

    private enum Section { case main }

    private let viewModel: FavouritesViewModel
    private lazy var collectionView = makeCollectionView()
    private lazy var dataSource = makeDataSource()

    init(environment: AppEnvironment) {
        self.viewModel = FavouritesViewModel(environment: environment)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Favourites"
        view.backgroundColor = .systemGroupedBackground

        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        _ = dataSource
        viewModel.onChange = { [weak self] in self?.render() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reload()
    }

    // MARK: - Setup

    private func makeCollectionView() -> UICollectionView {
        let layout = UICollectionViewCompositionalLayout { _, _ in
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .estimated(196))
            )
            item.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 7, bottom: 7, trailing: 7)

            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(196)),
                subitems: [item, item]
            )
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 13, bottom: 28, trailing: 13)
            return section
        }
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.register(FavouriteTileCell.self, forCellWithReuseIdentifier: FavouriteTileCell.reuseID)
        collectionView.delegate = self
        return collectionView
    }

    private func makeDataSource() -> UICollectionViewDiffableDataSource<Section, Restaurant> {
        UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, restaurant in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FavouriteTileCell.reuseID, for: indexPath)
            (cell as? FavouriteTileCell)?.configure(with: restaurant)
            return cell
        }
    }

    // MARK: - Rendering

    private func render() {
        if viewModel.isEmpty {
            var config = UIContentUnavailableConfiguration.empty()
            config.image = UIImage(systemName: "heart")
            config.text = "No favourites yet"
            config.secondaryText = "Tap the heart on a restaurant to save it here."
            contentUnavailableConfiguration = config
        } else {
            contentUnavailableConfiguration = nil
        }

        var snapshot = NSDiffableDataSourceSnapshot<Section, Restaurant>()
        snapshot.appendSections([.main])
        snapshot.appendItems(viewModel.restaurants)
        dataSource.apply(snapshot, animatingDifferences: !dataSource.snapshot().itemIdentifiers.isEmpty)
    }
}

// MARK: - UICollectionViewDelegate

extension FavouritesViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let restaurant = dataSource.itemIdentifier(for: indexPath) else { return }
        let detail = RestaurantDetailViewController(
            restaurant: restaurant,
            favourites: viewModel.favouritesRepository
        )
        navigationController?.pushViewController(detail, animated: true)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let restaurant = dataSource.itemIdentifier(for: indexPath) else { return nil }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let remove = UIAction(
                title: "Remove from Favourites",
                image: UIImage(systemName: "heart.slash"),
                attributes: .destructive
            ) { _ in
                self?.viewModel.remove(restaurant)
            }
            return UIMenu(children: [remove])
        }
    }
}
