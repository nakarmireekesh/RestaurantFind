import UIKit

/// Root of the UI: a two-tab layout for discovering restaurants and browsing saved favourites.
final class RootTabBarController: UITabBarController {

    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        let discover = UINavigationController(
            rootViewController: DiscoverViewController(environment: environment)
        )
        discover.tabBarItem = UITabBarItem(
            title: "Discover",
            image: UIImage(systemName: "fork.knife"),
            selectedImage: UIImage(systemName: "fork.knife")
        )

        let favourites = UINavigationController(
            rootViewController: FavouritesViewController(environment: environment)
        )
        favourites.tabBarItem = UITabBarItem(
            title: "Favourites",
            image: UIImage(systemName: "heart"),
            selectedImage: UIImage(systemName: "heart.fill")
        )

        for nav in [discover, favourites] {
            nav.navigationBar.prefersLargeTitles = true
        }

        viewControllers = [discover, favourites]
    }
}
