import UIKit

/// Thông tin bản dựng đang chạy (đọc từ Info.plist do build.sh ghi vào).
enum AppInfo {
    private static func string(_ key: String) -> String? {
        return Bundle.main.object(forInfoDictionaryKey: key) as? String
    }

    static var version: String { return string("CFBundleShortVersionString") ?? "?" }
    static var build: Int { return Int(string("CFBundleVersion") ?? "") ?? 0 }
    static var commit: String { return string("MochyBuildCommit") ?? "" }
    /// Kênh mà bản dựng này được phát hành ("stable" hoặc "dev").
    static var builtChannel: String { return string("MochyChannel") ?? "stable" }
    /// Cài bằng .deb (jailbreak) thì app nằm trong /Applications.
    static var isJailbreakInstall: Bool { return Bundle.main.bundlePath.hasPrefix("/Applications/") }
    static var osVersion: String { return UIDevice.current.systemVersion }
}

enum UpdateChannel: String {
    case stable
    case dev

    var title: String {
        return self == .stable ? AppLocalization.text("Kararlı") : AppLocalization.text("Geliştirici")
    }
}

enum AudioQuality: Int {
    case best = 0
    case saver = 1
}

/// Cài đặt người dùng, lưu trong UserDefaults.
enum PlayerBlur: Int {
    case auto = 0, light, dark
    var title: String {
        switch self {
        case .auto: return "Albüm kapağına göre otomatik"
        case .light: return "Açık"
        case .dark: return "Koyu"
        }
    }
}

enum AppSettings {
    private static let defaults = UserDefaults.standard

    static var autoCheck: Bool {
        get {
            if defaults.object(forKey: "update.auto") == nil { return true }
            return defaults.bool(forKey: "update.auto")
        }
        set { defaults.set(newValue, forKey: "update.auto") }
    }

    static var channel: UpdateChannel {
        get {
            if let raw = defaults.string(forKey: "update.channel"), let value = UpdateChannel(rawValue: raw) {
                return value
            }
            return AppInfo.builtChannel == "dev" ? .dev : .stable
        }
        set { defaults.set(newValue.rawValue, forKey: "update.channel") }
    }

    static var audioQuality: AudioQuality {
        get { return AudioQuality(rawValue: defaults.integer(forKey: "audio.quality")) ?? .best }
        set { defaults.set(newValue.rawValue, forKey: "audio.quality") }
    }

    /// One language preference shared by the Mochy interface and YouTube Music requests.
    /// Reads the previous YouTube-only key to preserve existing user preferences after upgrading.
    static var language: String {
        get {
            return defaults.string(forKey: "app.language")
                ?? defaults.string(forKey: "youtube.language")
                ?? "tr"
        }
        set {
            defaults.set(newValue, forKey: "app.language")
            defaults.set(newValue, forKey: "youtube.language") // backwards compatibility
        }
    }

    /// One region preference shared with YouTube Music (ISO 3166-1 alpha-2 or "auto").
    static var region: String {
        get {
            return defaults.string(forKey: "app.region")
                ?? defaults.string(forKey: "youtube.region")
                ?? "auto"
        }
        set {
            defaults.set(newValue, forKey: "app.region")
            defaults.set(newValue, forKey: "youtube.region") // backwards compatibility
        }
    }

    // Compatibility aliases for existing playback and feed code.
    static var musicLanguage: String {
        get { return language }
        set { language = newValue }
    }
    static var musicRegion: String {
        get { return region }
        set { region = newValue }
    }

    /// Dùng video MV làm nền màn hình đang phát (nếu bài có).
    static var videoBackdrop: Bool {
        get {
            if defaults.object(forKey: "player.video") == nil { return true }
            return defaults.bool(forKey: "player.video")
        }
        set { defaults.set(newValue, forKey: "player.video") }
    }

    /// Kiểu làm mờ phía dưới màn hình đang phát khi chưa bật lời.
    static var playerBlur: PlayerBlur {
        get { return PlayerBlur(rawValue: defaults.integer(forKey: "player.blur")) ?? .auto }
        set { defaults.set(newValue.rawValue, forKey: "player.blur") }
    }

    /// Độ đậm của lời bài hát: 0 (Light) ... 6 (Black).
    static var lyricWeight: Int {
        get {
            if defaults.object(forKey: "lyrics.weight") == nil { return RoundedFont.defaultLyricIndex }
            return min(max(defaults.integer(forKey: "lyrics.weight"), 0), 6)
        }
        set { defaults.set(min(max(newValue, 0), 6), forKey: "lyrics.weight") }
    }

    static var recentSearches: [String] {
        get { return defaults.stringArray(forKey: "search.recent") ?? [] }
        set { defaults.set(Array(newValue.prefix(12)), forKey: "search.recent") }
    }

    /// Build đã được báo bằng hộp thoại, để không làm phiền lặp lại.
    static var lastNotifiedBuild: Int {
        get { return defaults.integer(forKey: "update.notified") }
        set { defaults.set(newValue, forKey: "update.notified") }
    }
}

/// So sánh phiên bản dạng "12.5.8": true nếu `current` >= `required`.
func versionAtLeast(_ current: String, _ required: String) -> Bool {
    let a = current.split(separator: ".").map { Int($0) ?? 0 }
    let b = required.split(separator: ".").map { Int($0) ?? 0 }
    let count = max(a.count, b.count)
    for i in 0..<count {
        let x = i < a.count ? a[i] : 0
        let y = i < b.count ? b[i] : 0
        if x != y { return x > y }
    }
    return true
}


/// Language and country preferences sent to YouTube Music's InnerTube API.
/// Region detection uses the iOS locale setting and does not request location access.
enum YouTubeMusicLocale {
    static let languageOptions: [(code: String, title: String)] = [
        ("tr", "Türkçe"),
        ("en", "English"),
        ("es", "Español"),
        ("fr", "Français"),
        ("de", "Deutsch"),
        ("it", "Italiano"),
        ("pt", "Português")
    ]

    static let regionOptions: [(code: String, title: String)] = [
        ("auto", "Cihaz bölgesi (Otomatik)"),
        ("TR", "Türkiye"),
        ("US", "Amerika Birleşik Devletleri"),
        ("GB", "Birleşik Krallık"),
        ("CA", "Kanada"),
        ("AU", "Avustralya"),
        ("DE", "Almanya"),
        ("FR", "Fransa"),
        ("ES", "İspanya"),
        ("BR", "Brezilya"),
        ("PT", "Portekiz"),
        ("IT", "İtalya"),
        ("JP", "Japonya"),
        ("KR", "Güney Kore"),
        ("VN", "Vietnam"),
        ("IN", "Hindistan"),
        ("ID", "Endonezya"),
        ("MX", "Meksika"),
        ("SA", "Suudi Arabistan"),
        ("AE", "Birleşik Arap Emirlikleri")
    ]

    static var languageCode: String {
        let value = AppSettings.language
        if value == "system" {
            let preferred = Locale.preferredLanguages.first ?? "tr"
            let rawCode = Locale(identifier: preferred).languageCode ?? "tr"
            let code = rawCode == "zh" ? "zh-Hans" : rawCode
            return languageOptions.contains(where: { $0.code == code }) ? code : "tr"
        }
        return languageOptions.contains(where: { $0.code == value }) ? value : "tr"
    }

    static var languageTitle: String {
        return languageOptions.first(where: { $0.code == AppSettings.language })?.title
            ?? (AppSettings.language == "system" ? AppLocalization.text("Cihaz dili") : "Türkçe")
    }

    static var regionCode: String {
        let selected = AppSettings.region
        if selected != "auto", regionOptions.contains(where: { $0.code == selected }) { return selected }
        let deviceRegion = Locale.current.regionCode?.uppercased() ?? "TR"
        return deviceRegion.count == 2 ? deviceRegion : "TR"
    }

    static var regionTitle: String {
        if AppSettings.region == "auto" {
            return AppLocalization.text("Otomatik") + " · " + AppLocalization.localizedRegionName(regionCode)
        }
        return AppLocalization.localizedRegionName(regionCode)
    }

    static var acceptLanguage: String {
        let code = languageCode
        // Send a language tag that matches the selected country where possible.
        let languageTag = code == "zh-Hans" ? code : "\(code)-\(regionCode)"
        return "\(languageTag),\(code);q=0.9,en;q=0.7"
    }

    static func newMusicSearchQuery(year: Int) -> String {
        switch languageCode {
        case "en": return "new popular songs \(year)"
        case "es": return "nuevas canciones populares \(year)"
        case "fr": return "nouvelles chansons populaires \(year)"
        case "de": return "neue beliebte Songs \(year)"
        case "pt": return "novas músicas populares \(year)"
        case "it": return "nuove canzoni popolari \(year)"
        case "vi": return "bài hát mới phổ biến \(year)"
        case "ja": return "人気の新曲 \(year)"
        case "ko": return "인기 신곡 \(year)"
        case "ar": return "أغاني جديدة مشهورة \(year)"
        case "hi": return "नए लोकप्रिय गाने \(year)"
        case "id": return "lagu populer terbaru \(year)"
        case "zh-Hans": return "\(year) 年热门新歌"
        default: return "yeni Türkçe şarkılar \(year)"
        }
    }

    static var popularShelfTitle: String {
        switch languageCode {
        case "en": return "Popular"
        case "es": return "Populares"
        case "fr": return "Populaire"
        case "de": return "Beliebt"
        case "pt": return "Populares"
        case "it": return "Popolari"
        case "vi": return "Phổ biến"
        case "ja": return "人気"
        case "ko": return "인기"
        case "ar": return "الأكثر رواجًا"
        case "hi": return "लोकप्रिय"
        case "id": return "Populer"
        case "zh-Hans": return "热门"
        default: return "Popüler"
        }
    }

    static var newMusicShelfTitle: String {
        switch languageCode {
        case "en": return "New songs"
        case "es": return "Canciones nuevas"
        case "fr": return "Nouveautés"
        case "de": return "Neue Songs"
        case "pt": return "Músicas novas"
        case "it": return "Nuove canzoni"
        case "vi": return "Bài hát mới"
        case "ja": return "新曲"
        case "ko": return "신곡"
        case "ar": return "أغانٍ جديدة"
        case "hi": return "नए गाने"
        case "id": return "Lagu terbaru"
        case "zh-Hans": return "新歌"
        default: return "Yeni şarkılar"
        }
    }
}

extension Notification.Name {
    static let musicLocaleChanged = Notification.Name("MochyMusicLocaleChanged")
    static let appLanguageChanged = Notification.Name("MochyAppLanguageChanged")
}
