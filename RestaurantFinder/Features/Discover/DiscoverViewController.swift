import UIKit

/// The Discover tab: a searchable, distance-sorted list of nearby restaurants
/// with a horizontal category filter bar.
final class DiscoverViewController: UIViewController {

    private enum ListSection { case main }

    private let viewModel: DiscoverViewModel

    private lazy var chipsView = makeChipsView()
    private lazy var tableView = makeTableView()
    private lazy var listDataSource = makeListDataSource()
    private var rowsByID: [Restaurant.ID: DiscoverViewModel.RestaurantRow] = [:]

    private let searchController = UISearchController(searchResultsController: nil)
    private var searchDebounce: DispatchWorkItem?
    private var chipsHeight: NSLayoutConstraint!

    init(environment: AppEnvironment) {
        self.viewModel = DiscoverViewModel(environment: environment)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Discover"
        view.backgroundColor = .systemGroupedBackground

        configureSearch()
        configureLayout()

        viewModel.onStateChange = { [weak self] state in self?.render(state) }
        viewModel.onChipsChange = { [weak self] in self?.renderChips() }

        // Retry automatically when returning from Settings (e.g. after granting location).
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.onAppear()
    }

    @objc private func handleForeground() {
        if case .failed = viewModel.state {
            viewModel.retry()
        }
    }

    // MARK: - Setup

    private func makeChipsView() -> UICollectionView {
        let layout = UICollectionViewCompositionalLayout { _, _ in
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .estimated(72), heightDimension: .fractionalHeight(1))
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(widthDimension: .estimated(72), heightDimension: .absolute(34)),
                subitems: [item]
            )
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 8
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            section.orthogonalScrollingBehavior = .continuous
            return section
        }
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(CategoryChipCell.self, forCellWithReuseIdentifier: CategoryChipCell.reuseID)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }

    private func makeTableView() -> UITableView {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 96
        table.keyboardDismissMode = .onDrag
        table.contentInset.top = 4
        table.register(RestaurantCell.self, forCellReuseIdentifier: RestaurantCell.reuseID)
        table.delegate = self
        table.refreshControl = UIRefreshControl()
        table.refreshControl?.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return table
    }

    private func makeListDataSource() -> UITableViewDiffableDataSource<ListSection, Restaurant> {
        UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, restaurant in
            let cell = tableView.dequeueReusableCell(withIdentifier: RestaurantCell.reuseID, for: indexPath)
            guard let self,
                  let restaurantCell = cell as? RestaurantCell,
                  let row = self.rowsByID[restaurant.id] else { return cell }

            restaurantCell.configure(with: row)
            restaurantCell.onToggleFavourite = { [weak self] in
                self?.viewModel.toggleFavourite(for: restaurant)
            }
            return restaurantCell
        }
    }

    private func configureSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Pizza, sushi, coffee…"
        searchController.searchBar.autocapitalizationType = .none
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func configureLayout() {
        view.addSubview(chipsView)
        view.addSubview(tableView)

        chipsHeight = chipsView.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            chipsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            chipsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chipsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chipsHeight,

            tableView.topAnchor.constraint(equalTo: chipsView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        _ = listDataSource // create the diffable data source (it wires itself to the table)
    }

    // MARK: - Rendering

    private func render(_ state: DiscoverViewModel.State) {
        switch state {
        case .idle:
            break

        case .loading:
            if listDataSource.snapshot().numberOfItems == 0 {
                contentUnavailableConfiguration = UIContentUnavailableConfiguration.loading()
            }

        case .loaded(let rows):
            tableView.refreshControl?.endRefreshing()
            contentUnavailableConfiguration = nil
            apply(rows: rows)

        case .empty(let message):
            tableView.refreshControl?.endRefreshing()
            apply(rows: [])
            var config = UIContentUnavailableConfiguration.empty()
            config.image = UIImage(systemName: "fork.knife")
            config.text = "No restaurants"
            config.secondaryText = message
            contentUnavailableConfiguration = config

        case .failed(let message, let isLocationPermissionDenied):
            tableView.refreshControl?.endRefreshing()
            apply(rows: [])
            var config = UIContentUnavailableConfiguration.empty()
            config.image = UIImage(systemName: isLocationPermissionDenied ? "location.slash" : "exclamationmark.triangle")
            config.text = isLocationPermissionDenied ? "Location is off" : "Couldn’t load restaurants"
            config.secondaryText = message

            if isLocationPermissionDenied {
                var openSettings = UIButton.Configuration.borderedProminent()
                openSettings.title = "Open Settings"
                config.button = openSettings
                config.buttonProperties.primaryAction = UIAction { _ in
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }

                var retry = UIButton.Configuration.plain()
                retry.title = "Try Again"
                config.secondaryButton = retry
                config.secondaryButtonProperties.primaryAction = UIAction { [weak self] _ in self?.viewModel.retry() }
            } else {
                var retry = UIButton.Configuration.borderedProminent()
                retry.title = "Try Again"
                config.button = retry
                config.buttonProperties.primaryAction = UIAction { [weak self] _ in self?.viewModel.retry() }
            }
            contentUnavailableConfiguration = config
        }
    }

    private func apply(rows: [DiscoverViewModel.RestaurantRow]) {
        rowsByID = Dictionary(rows.map { ($0.restaurant.id, $0) }, uniquingKeysWith: { first, _ in first })

        let existing = Set(listDataSource.snapshot().itemIdentifiers)
        var snapshot = NSDiffableDataSourceSnapshot<ListSection, Restaurant>()
        snapshot.appendSections([.main])
        let items = rows.map(\.restaurant)
        snapshot.appendItems(items)

        // Re-render rows whose identity is unchanged but whose content (favourite
        // state, distance) may have — without the scroll jump a full reload causes.
        let unchanged = items.filter { existing.contains($0) }
        if !unchanged.isEmpty {
            snapshot.reconfigureItems(unchanged)
        }
        listDataSource.apply(snapshot, animatingDifferences: !existing.isEmpty)
    }

    private func renderChips() {
        chipsView.reloadData()
        chipsHeight.constant = viewModel.chips.count > 1 ? 50 : 0
        UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
    }

    // MARK: - Actions

    @objc private func handleRefresh() {
        viewModel.search(query: searchController.searchBar.text ?? "")
    }
}

// MARK: - Category chips

extension DiscoverViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.chips.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryChipCell.reuseID, for: indexPath)
        let chip = viewModel.chips[indexPath.item]
        (cell as? CategoryChipCell)?.configure(title: chip.title, selected: chip.title == viewModel.selectedChipTitle)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let chip = viewModel.chips[indexPath.item]
        UISelectionFeedbackGenerator().selectionChanged()
        viewModel.selectChip(title: chip.title)
        collectionView.reloadData()
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
}

// MARK: - Table selection

extension DiscoverViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let restaurant = listDataSource.itemIdentifier(for: indexPath) else { return }
        let detail = RestaurantDetailViewController(
            restaurant: restaurant,
            favourites: viewModel.favouritesRepository
        )
        navigationController?.pushViewController(detail, animated: true)
    }
}

// MARK: - Search

extension DiscoverViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        // Debounce so we don't fire a MapKit request on every keystroke.
        searchDebounce?.cancel()
        let query = searchController.searchBar.text ?? ""
        let work = DispatchWorkItem { [weak self] in self?.viewModel.search(query: query) }
        searchDebounce = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }
}
