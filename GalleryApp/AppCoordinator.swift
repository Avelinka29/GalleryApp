import UIKit

@MainActor
final class AppCoordinator {
    private let window: UIWindow
    private let navigationController = UINavigationController()
    private let imageLoader = ImageLoader()
    private let detailImageLoader = ImageLoader(maximumPixelSize: 1_600)

    init(window: UIWindow) {
        self.window = window
    }

    private func showPhoto(photos: [Photo], index: Int) {
        guard let viewModel = PhotoDetailsViewModel(photos: photos, selectedIndex: index) else { return }
        let details = PhotoDetailsViewController(viewModel: viewModel, imageLoader: detailImageLoader)
        details.onOpenAttribution = { url in UIApplication.shared.open(url) }
        navigationController.pushViewController(details, animated: true)
    }

    func start() {
        let service = UnsplashPhotoService(accessKey: APIConfiguration.accessKey())
        let viewModel = GalleryViewModel(service: service)
        let gallery = ViewController(viewModel: viewModel, imageLoader: imageLoader)
        gallery.onOpenAttribution = { url in UIApplication.shared.open(url) }
        gallery.onSelectPhoto = { [weak self] photos, index in
            self?.showPhoto(photos: photos, index: index)
        }
        navigationController.setViewControllers([gallery], animated: false)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}
