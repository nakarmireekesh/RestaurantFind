import UIKit

/// The Discover tab. Shows a searchable, distance-sorted list of nearby restaurants.
final class DiscoverViewController: UIViewController {

    private let viewModel: DiscoverViewModel

    private lazy var tableView = makeTableView()
    private let searchController = UISearchController(searchResultsController: nil)
    private let statusLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private var rows: [DiscoverViewModel.RestaurantRow] = []
    private var searchDebounce: DispatchWorkItem?

    init(environment: AppEnvironment) {
        self.viewModel = DiscoverViewModel(environment: environment)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Discover"
        view.backgroundColor = .systemBackground

        configureSearch()
        configureLayout()

        viewModel.onStateChange = { [weak self] state in
            // DiscoverViewModel is @MainActor, so this always arrives on the main thread.
            self?.render(state)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.onAppear()
    }

    // MARK: - Setup

    private func makeTableView() -> UITableView {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 72
        table.keyboardDismissMode = .onDrag
        table.register(RestaurantCell.self, forCellReuseIdentifier: RestaurantCell.reuseID)
        table.dataSource = self
        table.delegate = self
        table.refreshControl = UIRefreshControl()
        table.refreshControl?.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return table
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
        view.addSubview(tableView)
        view.addSubview(statusLabel)
        view.addSubview(activityIndicator)

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.textColor = .secondaryLabel
        statusLabel.font = .preferredFont(forTextStyle: .body)
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.isHidden = true

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    // MARK: - Rendering

    private func render(_ state: DiscoverViewModel.State) {
        switch state {
        case .idle:
            break

        case .loading:
            statusLabel.isHidden = true
            if rows.isEmpty { activityIndicator.startAnimating() }

        case .loaded(let newRows):
            activityIndicator.stopAnimating()
            tableView.refreshControl?.endRefreshing()
            statusLabel.isHidden = true
            rows = newRows
            tableView.reloadData()

        case .empty(let message), .failed(let message):
            activityIndicator.stopAnimating()
            tableView.refreshControl?.endRefreshing()
            rows = []
            tableView.reloadData()
            statusLabel.text = message
            statusLabel.isHidden = false
        }
    }

    // MARK: - Actions

    @objc private func handleRefresh() {
        viewModel.search(query: searchController.searchBar.text ?? "")
    }
}

// MARK: - UITableViewDataSource / Delegate

extension DiscoverViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RestaurantCell.reuseID, for: indexPath)
        guard let restaurantCell = cell as? RestaurantCell else { return cell }

        let row = rows[indexPath.row]
        restaurantCell.configure(with: row)
        restaurantCell.onToggleFavourite = { [weak self] in
            self?.viewModel.toggleFavourite(for: row.restaurant)
        }
        return restaurantCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let restaurant = rows[indexPath.row].restaurant
        let detail = RestaurantDetailViewController(
            restaurant: restaurant,
            favourites: viewModel.favouritesRepository
        )
        navigationController?.pushViewController(detail, animated: true)
    }
}

// MARK: - UISearchResultsUpdating

extension DiscoverViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        // Debounce so we don't fire a MapKit request on every keystroke.
        searchDebounce?.cancel()
        let query = searchController.searchBar.text ?? ""
        let work = DispatchWorkItem { [weak self] in
            self?.viewModel.search(query: query)
        }
        searchDebounce = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }
}
