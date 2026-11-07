import UIKit

final class PhotoDetailsViewController: UIViewController {
    private let viewModel: PhotoDetailsViewModel
    private let imageLoader: any ImageLoading
    private let pager = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    var onOpenAttribution: ((URL) -> Void)?

    init(viewModel: PhotoDetailsViewModel, imageLoader: any ImageLoading) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { return nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.title
        view.backgroundColor = .systemBackground
        view.accessibilityIdentifier = "photoDetails"
        pager.dataSource = self
        pager.delegate = self
        addChild(pager)
        pager.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pager.view)
        NSLayoutConstraint.activate([
            pager.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pager.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            pager.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            pager.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        pager.didMove(toParent: self)
        if let page = makePage(at: viewModel.selectedIndex) {
            pager.setViewControllers([page], direction: .forward, animated: false)
        }
    }

    private func makePage(at index: Int) -> PhotoPageViewController? {
        guard let photo = viewModel.photo(at: index) else { return nil }
        let page = PhotoPageViewController(photo: photo, index: index, imageLoader: imageLoader)
        page.onOpenAttribution = { [weak self] url in self?.onOpenAttribution?(url) }
        return page
    }
}

extension PhotoDetailsViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let page = viewController as? PhotoPageViewController else { return nil }
        return makePage(at: page.index - 1)
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let page = viewController as? PhotoPageViewController else { return nil }
        return makePage(at: page.index + 1)
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        // A cancelled swipe must not change the selected photo.
        guard completed,
              let page = pageViewController.viewControllers?.first as? PhotoPageViewController else { return }
        viewModel.selectPhoto(at: page.index)
        title = viewModel.title
    }
}
