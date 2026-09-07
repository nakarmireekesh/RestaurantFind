import MapKit
import UIKit

/// Detail screen: a map, the restaurant's category, and tappable rows for
/// address (opens Maps), phone (starts a call) and website (opens Safari).
/// The nav-bar heart saves/removes the restaurant.
final class RestaurantDetailViewController: UIViewController {

    private let viewModel: RestaurantDetailViewModel

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let mapView = MKMapView()

    init(restaurant: Restaurant, favourites: FavouritesRepository) {
        self.viewModel = RestaurantDetailViewModel(restaurant: restaurant, favourites: favourites)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = viewModel.restaurant.name
        navigationItem.largeTitleDisplayMode = .never

        viewModel.onFavouriteChange = { [weak self] _ in
            self?.updateFavouriteButton()
        }

        configureLayout()
        configureMap()
        populate()
        updateFavouriteButton()
    }

    // MARK: - Setup

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.directionalLayoutMargins = .init(top: 16, leading: 20, bottom: 32, trailing: 20)

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.layer.cornerRadius = 12
        mapView.clipsToBounds = true
        mapView.isUserInteractionEnabled = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            mapView.heightAnchor.constraint(equalToConstant: 200),
        ])
    }

    private func configureMap() {
        let coordinate = viewModel.restaurant.coordinate
        mapView.setRegion(
            MKCoordinateRegion(center: coordinate, latitudinalMeters: 600, longitudinalMeters: 600),
            animated: false
        )
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = viewModel.restaurant.name
        mapView.addAnnotation(annotation)
    }

    private func populate() {
        let restaurant = viewModel.restaurant

        contentStack.addArrangedSubview(mapView)
        contentStack.addArrangedSubview(makeHeader())

        if let address = restaurant.shortAddress.nilIfEmpty {
            contentStack.addArrangedSubview(
                makeActionRow(icon: "map", text: address, action: #selector(openInMaps))
            )
        }
        if let phone = restaurant.phoneNumber?.nilIfEmpty {
            contentStack.addArrangedSubview(
                makeActionRow(icon: "phone", text: phone, action: #selector(callRestaurant))
            )
        }
        if let website = restaurant.website {
            contentStack.addArrangedSubview(
                makeActionRow(icon: "safari", text: website.absoluteString, action: #selector(openWebsite))
            )
        }
    }

    private func makeHeader() -> UIView {
        let name = UILabel()
        name.font = .preferredFont(forTextStyle: .title1)
        name.adjustsFontForContentSizeCategory = true
        name.numberOfLines = 0
        name.text = viewModel.restaurant.name

        let category = UILabel()
        category.font = .preferredFont(forTextStyle: .subheadline)
        category.adjustsFontForContentSizeCategory = true
        category.textColor = .secondaryLabel
        category.text = viewModel.restaurant.category
        category.isHidden = viewModel.restaurant.category == nil

        let stack = UIStackView(arrangedSubviews: [name, category])
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }

    private func makeActionRow(icon: String, text: String, action: Selector) -> UIView {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: icon)
        config.title = text
        config.imagePadding = 12
        config.contentInsets = .init(top: 12, leading: 0, bottom: 12, trailing: 0)

        let button = UIButton(configuration: config)
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.numberOfLines = 0
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func updateFavouriteButton() {
        let isFavourite = viewModel.isFavourite
        let item = UIBarButtonItem(
            image: UIImage(systemName: isFavourite ? "heart.fill" : "heart"),
            style: .plain,
            target: self,
            action: #selector(toggleFavourite)
        )
        item.accessibilityLabel = isFavourite ? "Remove from favourites" : "Add to favourites"
        navigationItem.rightBarButtonItem = item
    }

    // MARK: - Actions

    @objc private func toggleFavourite() {
        viewModel.toggleFavourite()
    }

    @objc private func openInMaps() {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: viewModel.restaurant.coordinate))
        mapItem.name = viewModel.restaurant.name
        mapItem.openInMaps()
    }

    @objc private func callRestaurant() {
        guard let phone = viewModel.restaurant.phoneNumber else { return }
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        guard let url = URL(string: "tel://\(digits)"), UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    @objc private func openWebsite() {
        guard let website = viewModel.restaurant.website else { return }
        UIApplication.shared.open(website)
    }
}
