import UIKit

/// The Favourites tab: a simple editable list of saved restaurants.
final class FavouritesViewController: UIViewController {

    private let viewModel: FavouritesViewModel
    private lazy var tableView = makeTableView()
    private let emptyLabel = UILabel()

    init(environment: AppEnvironment) {
        self.viewModel = FavouritesViewModel(environment: environment)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Favourites"
        view.backgroundColor = .systemBackground

        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.text = "Restaurants you favourite will show up here."
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.font = .preferredFont(forTextStyle: .body)
        emptyLabel.adjustsFontForContentSizeCategory = true

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
        ])

        viewModel.onChange = { [weak self] in
            self?.render()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reload()
    }

    // MARK: - Setup

    private func makeTableView() -> UITableView {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 64
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        table.dataSource = self
        table.delegate = self
        return table
    }

    private func render() {
        emptyLabel.isHidden = !viewModel.isEmpty
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource / Delegate

extension FavouritesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.restaurants.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let restaurant = viewModel.restaurants[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = restaurant.name
        config.secondaryText = [restaurant.category, restaurant.shortAddress.nilIfEmpty]
            .compactMap { $0 }
            .joined(separator: " · ")
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let restaurant = viewModel.restaurants[indexPath.row]
        let detail = RestaurantDetailViewController(
            restaurant: restaurant,
            favourites: viewModel.favouritesRepository
        )
        navigationController?.pushViewController(detail, animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        guard editingStyle == .delete else { return }
        viewModel.removeRestaurant(at: indexPath.row)
    }
}
