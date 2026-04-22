//
//  PersistenceManager.swift
//  142GenstrilbriKexzebul
//

import Foundation

final class SessionPreferenceVault {
    static let active = SessionPreferenceVault()

    private let savedUrlKey = GenstrilPayloadDecoder.userDefaultsLastURLKey
    private let hasShownContentViewKey = GenstrilPayloadDecoder.userDefaultsHasShownNativeKey
    private let hasSuccessfulWebViewLoadKey = GenstrilPayloadDecoder.userDefaultsRemoteHydratedKey

    var savedUrl: String? {
        get {
            if let url = LegacyURLDefaultsBridge.lastUrl {
                return url.absoluteString
            }
            return UserDefaults.standard.string(forKey: savedUrlKey)
        }
        set {
            if let urlString = newValue {
                UserDefaults.standard.set(urlString, forKey: savedUrlKey)
                if let url = URL(string: urlString) {
                    LegacyURLDefaultsBridge.lastUrl = url
                }
            } else {
                UserDefaults.standard.removeObject(forKey: savedUrlKey)
                LegacyURLDefaultsBridge.lastUrl = nil
            }
        }
    }

    var hasShownContentView: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasShownContentViewKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasShownContentViewKey)
        }
    }

    var hasSuccessfulWebViewLoad: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasSuccessfulWebViewLoadKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasSuccessfulWebViewLoadKey)
        }
    }

    private init() {}
}
