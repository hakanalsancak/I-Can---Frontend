import SwiftUI
import UIKit

/// Telegram/WhatsApp-style full-screen swipe-back for a `NavigationStack`-
/// pushed screen. Drop `.background(InteractiveSwipeBack())` anywhere in
/// the screen's body and a rightward pan from anywhere — not just the
/// left edge — drives the system's interactive pop transition, parallax
/// and all.
///
/// How it works: it walks up to the parent `UINavigationController` and
/// attaches a fresh `UIPanGestureRecognizer` whose `targets` are copied
/// from the controller's existing `interactivePopGestureRecognizer`. The
/// system's transition handlers run on our pan exactly as they do on the
/// edge pan, so the resulting transition is the real Apple one — animation
/// curve, parallax, percent-driven cancellation included.
///
/// `targets` is an undocumented KVC property on `UIGestureRecognizer`. It
/// has been the standard technique in shipping iOS apps (Telegram,
/// Instagram, etc.) for years. If Apple ever renames it the bridge no-ops
/// silently and the screen falls back to the default edge-swipe — no
/// crash, no data loss.
struct InteractiveSwipeBack: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> AttachController {
        AttachController(coordinator: context.coordinator)
    }

    func updateUIViewController(_ uiViewController: AttachController, context: Context) {
        // Re-attach if the screen was popped/pushed and our pan was lost.
        context.coordinator.attachIfNeeded(from: uiViewController)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    /// Empty, transparent host. Lives only so we can read its
    /// `navigationController` and hang our pan off it.
    final class AttachController: UIViewController {
        private weak var coordinator: Coordinator?

        init(coordinator: Coordinator) {
            self.coordinator = coordinator
            super.init(nibName: nil, bundle: nil)
            view.backgroundColor = .clear
            view.isUserInteractionEnabled = false
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            if parent != nil {
                coordinator?.attachIfNeeded(from: self)
            }
        }

        override func willMove(toParent parent: UIViewController?) {
            super.willMove(toParent: parent)
            // Screen is being torn down (chat dismissed). Strip our pan
            // off the nav controller's view so it doesn't outlive its
            // Coordinator delegate. Without this the next chat opens
            // with a dangling-delegate gesture that stops gating
            // recognition correctly and the swipe-back goes dead.
            if parent == nil {
                Coordinator.removeGesture(from: navigationController)
            }
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var attachedNav: UINavigationController?

        func attachIfNeeded(from vc: UIViewController) {
            // Defer to the next runloop tick so the SwiftUI host
            // controller is fully wired into its parent chain by the
            // time we walk it.
            DispatchQueue.main.async { [weak self] in
                self?.attachNow(from: vc)
            }
        }

        private func attachNow(from vc: UIViewController) {
            guard let nav = vc.navigationController,
                  nav.viewControllers.count > 1,
                  let edgePan = nav.interactivePopGestureRecognizer,
                  let targetView = edgePan.view else { return }

            attachedNav = nav

            // Always strip any leftover pan from a prior chat session
            // before installing the fresh one. The recognizer's delegate
            // is a weak ref to whatever Coordinator was alive when it
            // was added; once that Coordinator dies (with the previous
            // SwiftUI view), keeping the recognizer around leaves it
            // with a nil delegate and broken recognition gating.
            Self.removeGesture(from: nav)

            // Read the system's transition targets off the edge pan. If
            // KVC fails (e.g. Apple renamed the property in a future
            // iOS), bail silently — the screen still has the default
            // edge swipe.
            guard let targets = edgePan.value(forKey: Self.targetsKey) else { return }

            let pan = UIPanGestureRecognizer()
            pan.name = Self.gestureName
            pan.delegate = self
            pan.maximumNumberOfTouches = 1
            pan.setValue(targets, forKey: Self.targetsKey)
            targetView.addGestureRecognizer(pan)
        }

        static func removeGesture(from nav: UINavigationController?) {
            guard let targetView = nav?.interactivePopGestureRecognizer?.view else { return }
            for g in targetView.gestureRecognizers ?? [] where g.name == Self.gestureName {
                targetView.removeGestureRecognizer(g)
            }
        }

        // MARK: - UIGestureRecognizerDelegate

        /// Only claim the touch when it's a clear rightward, horizontal-
        /// dominant pan and the stack actually has somewhere to pop to.
        /// Vertical-dominant drags fall through to the message-list scroll
        /// view; small wobble in either direction is ignored.
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
                  let nav = attachedNav,
                  nav.viewControllers.count > 1,
                  nav.transitionCoordinator == nil else { return false }
            let v = pan.velocity(in: pan.view)
            return v.x > 0 && abs(v.x) > abs(v.y)
        }

        /// Run alongside other gestures. The directional filter above
        /// already keeps us out of vertical scrolls; SwiftUI's bubble
        /// swipe-to-reply runs concurrently and is suppressed past the
        /// dismiss threshold inside `MessageBubble`.
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }

        private static let gestureName = "ican.fullScreenSwipeBack"
        // Single use site of the undocumented KVC key — keep grep-able.
        private static let targetsKey = "targets"
    }
}
