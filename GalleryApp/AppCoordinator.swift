import UIKit

@MainActor
final class AppCoordinator {
    private let window: UIWindow
    private let navigationController = UINavigationController()

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        let viewModel = GalleryViewModel(photos: LocalPhoto.samples)
        let gallery = ViewController(viewModel: viewModel)
        navigationController.setViewControllers([gallery], animated: false)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}
