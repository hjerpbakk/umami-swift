import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct DeviceInfo: Sendable, Equatable {
    public var appVersion: String
    public var build: String
    public var osName: String
    public var osVersion: String
    public var deviceModel: String
    public var locale: String
    public var screen: String

    public init(appVersion: String, build: String, osName: String,
                osVersion: String, deviceModel: String, locale: String, screen: String) {
        self.appVersion = appVersion
        self.build = build
        self.osName = osName
        self.osVersion = osVersion
        self.deviceModel = deviceModel
        self.locale = locale
        self.screen = screen
    }
}

extension DeviceInfo {
    static func current(bundle: Bundle = .main) -> DeviceInfo {
        let info = bundle.infoDictionary ?? [:]
        let appVersion = info["CFBundleShortVersionString"] as? String ?? "0"
        let build = info["CFBundleVersion"] as? String ?? "0"

        let v = ProcessInfo.processInfo.operatingSystemVersion
        let osVersion = "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
        let locale = Locale.preferredLanguages.first ?? Locale.current.identifier

        #if os(iOS)
        let osName = "iOS"
        #elseif os(macOS)
        let osName = "macOS"
        #elseif os(tvOS)
        let osName = "tvOS"
        #elseif os(watchOS)
        let osName = "watchOS"
        #elseif os(visionOS)
        let osName = "visionOS"
        #else
        let osName = "unknown"
        #endif

        return DeviceInfo(
            appVersion: appVersion, build: build, osName: osName,
            osVersion: osVersion, deviceModel: hardwareModel(),
            locale: locale, screen: screenSize())
    }

    private static func hardwareModel() -> String {
        #if os(macOS)
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var chars = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &chars, &size, nil, 0)
        return String(cString: chars)
        #else
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        return mirror.children.reduce(into: "") { result, element in
            if let value = element.value as? Int8, value != 0 {
                result.append(Character(UnicodeScalar(UInt8(value))))
            }
        }
        #endif
    }

    private static func screenSize() -> String {
        #if canImport(UIKit)
        let b = UIScreen.main.bounds
        let s = UIScreen.main.scale
        return "\(Int(b.width * s))x\(Int(b.height * s))"
        #elseif canImport(AppKit)
        if let f = NSScreen.main?.frame {
            return "\(Int(f.width))x\(Int(f.height))"
        }
        return ""
        #else
        return ""
        #endif
    }
}
