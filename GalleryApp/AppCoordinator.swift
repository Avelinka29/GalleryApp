import UIKit

@MainActor
final class AppCoordinator {
    private let window: UIWindow
    private let imageLoader = ImageLoader()
    private let detailImageLoader = ImageLoader(maximumPixelSize: 1_600)
    private let favourites = FavouritesStore(repository: FavouritesRepository())

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        let service = UnsplashPhotoService(accessKey: APIConfiguration.accessKey())
        let gallery = makeNavigation(
            viewModel: GalleryViewModel(service: service, favourites: favourites),
            symbol: "photo.on.rectangle"
        )
        let saved = makeNavigation(viewModel: FavouritesViewModel(favourites: favourites), symbol: "heart.fill")
        let tabs = UITabBarController()
        tabs.viewControllers = [gallery, saved]
        window.rootViewController = tabs
        window.makeKeyAndVisible()
        Task { await favourites.load() }
    }

    private func makeNavigation(viewModel: any PhotoGridViewModel, symbol: String) -> UINavigationController {
        let grid = ViewController(viewModel: viewModel, imageLoader: imageLoader)
        let navigation = UINavigationController(rootViewController: grid)
        navigation.tabBarItem = UITabBarItem(title: viewModel.title, image: UIImage(systemName: symbol), tag: 0)
        grid.onOpenAttribution = { url in UIApplication.shared.open(url) }
        grid.onSelectPhoto = { [weak self, weak navigation] photos, index in
            guard let navigation else { return }
            self?.showPhoto(photos: photos, index: index, navigation: navigation)
        }
        return navigation
    }

    private func showPhoto(photos: [Photo], index: Int, navigation: UINavigationController) {
        guard let viewModel = PhotoDetailsViewModel(
            photos: photos, selectedIndex: index, favourites: favourites
        ) else { return }
        let details = PhotoDetailsViewController(viewModel: viewModel, imageLoader: detailImageLoader)
        details.onOpenAttribution = { url in UIApplication.shared.open(url) }
        navigation.pushViewController(details, animated: true)
    }
}
