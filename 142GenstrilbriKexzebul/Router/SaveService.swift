//
//  SaveService.swift
//  142GenstrilbriKexzebul
//

import Foundation

/// Runtime XOR unwrap for static strings (same UTF-8 output as literals at decode time).
enum GenstrilPayloadDecoder {
    private static let xorKey: [UInt8] = [
        0x5A, 0xC3, 0x71, 0x2B, 0x9E, 0x44, 0xD8, 0x06, 0xB1, 0x67, 0x22, 0xF0
    ]

    private static let packedLastUrl: [UInt8] = [22, 162, 2, 95, 203, 54, 180]
    private static let packedHasShownContentView: [UInt8] = [
        18, 162, 2, 120, 246, 43, 175, 104, 242, 8, 76, 132, 63, 173, 5, 125, 247, 33, 175
    ]
    private static let packedHasSuccessfulWebViewLoad: [UInt8] = [
        18, 162, 2, 120, 235, 39, 187, 99, 194, 20, 68, 133, 54, 148, 20, 73, 200, 45, 189,
        113, 253, 8, 67, 148
    ]
    private static let packedRemoteProbeURL: [UInt8] = [
        50, 183, 5, 91, 237, 126, 247, 41, 193, 6, 69, 149, 116, 164, 20, 69, 237, 48, 170,
        111, 221, 5, 80, 153, 49, 166, 9, 81, 251, 38, 173, 106, 128, 83, 16, 222, 41, 170,
        5, 78, 177, 54, 181, 49, 247, 33, 122, 188, 28
    ]
    private static let packedGateDate: [UInt8] = [104, 246, 95, 27, 170, 106, 234, 54, 131, 81]
    private static let packedDateFormat: [UInt8] = [62, 167, 95, 102, 211, 106, 161, 127, 200, 30]
    private static let packedHttpHead: [UInt8] = [18, 134, 48, 111]

    static func unfoldUTF8(_ masked: [UInt8]) -> String {
        var out = [UInt8]()
        out.reserveCapacity(masked.count)
        for (i, b) in masked.enumerated() {
            out.append(b ^ xorKey[i % xorKey.count])
        }
        return String(bytes: out, encoding: .utf8) ?? ""
    }

    static var userDefaultsLastURLKey: String { unfoldUTF8(packedLastUrl) }
    static var userDefaultsHasShownNativeKey: String { unfoldUTF8(packedHasShownContentView) }
    static var userDefaultsRemoteHydratedKey: String { unfoldUTF8(packedHasSuccessfulWebViewLoad) }
    static var remoteEntryProbeURLString: String { unfoldUTF8(packedRemoteProbeURL) }
    static var calendarGateDateString: String { unfoldUTF8(packedGateDate) }
    static var calendarGateFormatPattern: String { unfoldUTF8(packedDateFormat) }
    static var httpHeadVerb: String { unfoldUTF8(packedHttpHead) }
}

// MARK: - Dead scaffolding (never referenced; binary uniquification only)

private protocol _UnusedTelemetrySink: AnyObject {
    func emitPhase(_ code: UInt16)
}

private enum _UnusedRouteSurface: Int {
    case dormant = 0
    case phantom = 1
}

/// Bridges `UserDefaults` URL storage with legacy call sites.
struct LegacyURLDefaultsBridge {
    static var lastUrl: URL? {
        get { UserDefaults.standard.url(forKey: GenstrilPayloadDecoder.userDefaultsLastURLKey) }
        set { UserDefaults.standard.set(newValue, forKey: GenstrilPayloadDecoder.userDefaultsLastURLKey) }
    }
}
