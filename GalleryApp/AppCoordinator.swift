import UIKit

@MainActor
final class AppCoordinator {
    private let window: UIWindow
    private let navigationController = UINavigationController()
    private let imageLoader = ImageLoader()

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        let service = UnsplashPhotoService(accessKey: APIConfiguration.accessKey())
        let viewModel = GalleryViewModel(service: service)
        let gallery = ViewController(viewModel: viewModel, imageLoader: imageLoader)
        gallery.onOpenAttribution = { url in UIApplication.shared.open(url) }
        navigationController.setViewControllers([gallery], animated: false)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}
