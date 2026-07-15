import Foundation
#if os(watchOS)
import WatchKit
#elseif canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct DeviceInfo: Sendable, Equatable {
    let appVersion: String
    let build: String
    let osName: String
    let osVersion: String
    let deviceModel: String
    let locale: String
    let screen: String

    init(appVersion: String, build: String, osName: String,
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
        #if os(watchOS)
        // watchOS has no UIScreen; WKInterfaceDevice is the only screen API.
        let d = WKInterfaceDevice.current()
        let b = d.screenBounds
        let s = d.screenScale
        return "\(Int(b.width * s))x\(Int(b.height * s))"
        #elseif canImport(UIKit)
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
