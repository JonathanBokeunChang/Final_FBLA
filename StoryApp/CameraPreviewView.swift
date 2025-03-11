import SwiftUI

// MARK: - CameraPreviewView
/// The CameraPreviewView is responsible for displaying the camera feed in a SwiftUI view.
/// It uses the `UIViewControllerRepresentable` protocol to integrate UIKit components with SwiftUI.
struct CameraPreviewView: UIViewControllerRepresentable {
    
    // MARK: - Properties
    @ObservedObject var cameraManager: CameraManager  // The camera manager to access the live preview layer
    
    // MARK: - Methods
    
    /// Creates the UIViewController to display the camera preview.
    /// - Parameter context: The context for the SwiftUI view lifecycle.
    /// - Returns: The UIViewController displaying the camera preview.
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        // Add the camera preview layer to the view's layer
        controller.view.layer.addSublayer(cameraManager.previewLayer!)
        return controller
    }

    /// Updates the UIViewController when the SwiftUI view is updated.
    /// - Parameter uiViewController: The current UIViewController to be updated.
    /// - Parameter context: The context for the SwiftUI view lifecycle.
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Adjust the preview layer's frame to match the view's bounds
        cameraManager.previewLayer?.frame = uiViewController.view.bounds
        uiViewController.view.layoutIfNeeded()
    }
}
