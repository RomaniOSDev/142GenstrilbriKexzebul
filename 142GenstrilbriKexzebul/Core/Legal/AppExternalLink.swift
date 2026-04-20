import Foundation

/// Central place for outbound URLs (privacy, terms). Replace hosts with your production endpoints.
enum AppExternalLink: String, CaseIterable {
    case privacyPolicy
    case termsOfUse

    var url: URL? {
        switch self {
        case .privacyPolicy:
            URL(string: "https://genstrilbrikexzebul142.site/privacy/116")
        case .termsOfUse:
            URL(string: "https://genstrilbrikexzebul142.site/terms/116")
        }
    }

    var title: String {
        switch self {
        case .privacyPolicy:
            "Privacy Policy"
        case .termsOfUse:
            "Terms of Use"
        }
    }
}
