import Foundation

/// Ana sayfa önerileri: YouTube Music ana akışı, ülke listeleri, yeni müzik ve yerel dinleme geçmişi.
/// Önbellek dil ve bölgeye göre ayrı tutulur.
final class HomeFeed {
    static let shared = HomeFeed()

    private(set) var shelves: [Shelf] = []
    private(set) var isLoading = false
    private(set) var lastError: String?

    private struct Cache: Codable {
        let day: String
        let region: String
        let language: String
        let feedVersion: Int
        let shelves: [Shelf]
    }

    private var regionCode: String { YouTubeMusicLocale.regionCode }
    private var languageCode: String { YouTubeMusicLocale.languageCode }
    private var loadGeneration = 0
    private static let currentFeedVersion = 4

    private init() {
        if let data = try? Data(contentsOf: cacheURL),
           let cache = try? JSONDecoder().decode(Cache.self, from: data),
           cache.region == regionCode,
           cache.language == languageCode,
           cache.feedVersion == Self.currentFeedVersion {
            shelves = cache.shelves
        }
        refreshLocalHistoryShelf()
    }

    private var cacheURL: URL {
        Library.supportDirectory.appendingPathComponent("home-\(languageCode)-\(regionCode)-v4.json")
    }

    private static func dayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }

    private func cachedForToday() -> Bool {
        guard let data = try? Data(contentsOf: cacheURL),
              let cache = try? JSONDecoder().decode(Cache.self, from: data) else { return false }
        return cache.day == Self.dayString()
            && cache.region == regionCode
            && cache.language == languageCode
            && cache.feedVersion == Self.currentFeedVersion
            && !cache.shelves.isEmpty
    }

    private var recentlyPlayedTitle: String {
        switch languageCode {
        case "en": return "Recently played"
        case "es": return "Escuchado recientemente"
        case "fr": return "Écoutés récemment"
        case "de": return "Zuletzt gehört"
        case "it": return "Ascoltati di recente"
        case "pt": return "Ouvidas recentemente"
        default: return "Son dinledikleriniz"
        }
    }

    private var regionalPopularTitle: String {
        switch languageCode {
        case "en": return "Popular in \(AppLocalization.localizedRegionName(regionCode))"
        case "es": return "Popular en \(AppLocalization.localizedRegionName(regionCode))"
        case "fr": return "Populaire en \(AppLocalization.localizedRegionName(regionCode))"
        case "de": return "Beliebt in \(AppLocalization.localizedRegionName(regionCode))"
        case "it": return "Popolari in \(AppLocalization.localizedRegionName(regionCode))"
        case "pt": return "Populares em \(AppLocalization.localizedRegionName(regionCode))"
        default: return "Popüler · \(AppLocalization.localizedRegionName(regionCode))"
        }
    }

    private func becauseYouListenedTitle(_ artist: String) -> String {
        switch languageCode {
        case "en": return "Because you listened to \(artist)"
        case "es": return "Porque escuchaste a \(artist)"
        case "fr": return "Parce que vous avez écouté \(artist)"
        case "de": return "Weil du \(artist) gehört hast"
        case "it": return "Perché hai ascoltato \(artist)"
        case "pt": return "Porque ouviu \(artist)"
        default: return "\(artist) dinlediğiniz için"
        }
    }

    private var recommendedTitle: String {
        switch languageCode {
        case "en": return "Recommended for you"
        case "es": return "Recomendado para ti"
        case "fr": return "Recommandé pour vous"
        case "de": return "Für dich empfohlen"
        case "it": return "Consigliati per te"
        case "pt": return "Recomendado para si"
        default: return "Sizin için önerilenler"
        }
    }

    private func normalizedArtist(_ name: String) -> String {
        return name
            .components(separatedBy: " · ").first?
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
    }

    /// Yerel geçmişi günlük çevrimiçi akıştan bağımsız gösterir.
    func refreshLocalHistoryShelf() {
        shelves.removeAll { $0.title == recentlyPlayedTitle }
        let recent = Library.shared.recentSongs(limit: 16)
        if !recent.isEmpty {
            shelves.append(Shelf(title: recentlyPlayedTitle, songs: recent))
        }
    }

    /// Ana sayfa kapağı için önce ülke listelerinden, sonra diğer önerilerden bir parça seçer.
    func heroSong() -> (song: Song, kicker: String)? {
        let preferred = shelves.first(where: { $0.title == regionalPopularTitle }) ?? shelves.first
        guard let shelf = preferred else { return nil }
        let pool = Array(shelf.songs.prefix(10))
        guard !pool.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return (pool[day % pool.count], "BUGÜNÜN ÖNERİLERİ")
    }

    func resetForLocaleChange() {
        loadGeneration += 1
        isLoading = false
        shelves = []
        lastError = nil
    }

    func load(force: Bool, completion: @escaping () -> Void) {
        if isLoading { return }
        if !force && cachedForToday() {
            refreshLocalHistoryShelf()
            completion()
            return
        }

        isLoading = true
        lastError = nil
        loadGeneration += 1
        let generation = loadGeneration
        let selectedRegion = regionCode
        let selectedLanguage = languageCode
        let year = Calendar.current.component(.year, from: Date())
        let group = DispatchGroup()

        var chartShelves: [Shelf] = []
        var newMusicShelves: [Shelf] = []
        var youtubeHomeShelves: [Shelf] = []
        var artistShelves: [Shelf] = []
        var errors: [String] = []

        // 1. YouTube Music'in kendi ana akışı: kişiselleştirilmiş mix'ler ve öneri rafları.
        group.enter()
        InnerTube.shared.browse("FEmusic_home") { result in
            switch result {
            case .success(let found):
                youtubeHomeShelves = found.filter { $0.songs.count >= 3 }
            case .failure(let error):
                errors.append(error.localizedDescription)
            }
            group.leave()
        }

        // 2. Kullanıcının seçtiği ülke/bölge için gerçek YouTube Music listeleri.
        group.enter()
        InnerTube.shared.browse("FEmusic_charts", formData: ["selectedValues": [selectedRegion]]) { result in
            switch result {
            case .success(let found):
                let valid = found.filter { $0.songs.count >= 3 }
                chartShelves = valid.enumerated().map { index, shelf in
                    Shelf(title: index == 0 ? self.regionalPopularTitle : (shelf.title.isEmpty ? self.recommendedTitle : shelf.title),
                          songs: Array(shelf.songs.prefix(20)))
                }
            case .failure(let error):
                errors.append(error.localizedDescription)
            }
            group.leave()
        }

        // 3. Seçilen arayüz diline göre yeni müzik araması.
        group.enter()
        InnerTube.shared.search(YouTubeMusicLocale.newMusicSearchQuery(year: year)) { result in
            switch result {
            case .success(let songs):
                if !songs.isEmpty {
                    newMusicShelves = [Shelf(title: YouTubeMusicLocale.newMusicShelfTitle, songs: Array(songs.prefix(20)))]
                }
            case .failure(let error):
                errors.append(error.localizedDescription)
            }
            group.leave()
        }

        // 4. Yerel dinleme geçmişindeki en çok dinlenen sanatçılara göre ayrı öneri rafları.
        let recentArtistNames = Library.shared.topArtists(limit: 4)
        let playedVideoIDs = Set(Library.shared.recentSongs(limit: 100).map { $0.videoId })
        for artist in recentArtistNames {
            group.enter()
            InnerTube.shared.search(artist) { result in
                if case .success(let songs) = result {
                    let wantedArtist = self.normalizedArtist(artist)
                    let matches = songs.filter { song in
                        let foundArtist = self.normalizedArtist(song.artist)
                        return !playedVideoIDs.contains(song.videoId)
                            && !foundArtist.isEmpty
                            && (foundArtist == wantedArtist || foundArtist.contains(wantedArtist) || wantedArtist.contains(foundArtist))
                    }
                    if matches.count >= 3 {
                        artistShelves.append(Shelf(title: self.becauseYouListenedTitle(artist), songs: Array(matches.prefix(16))))
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self, self.loadGeneration == generation else { return }
            self.isLoading = false
            guard self.regionCode == selectedRegion && self.languageCode == selectedLanguage else { return }

            var merged: [Shelf] = []
            merged.append(contentsOf: chartShelves)
            merged.append(contentsOf: newMusicShelves)
            merged.append(contentsOf: youtubeHomeShelves)
            merged.append(contentsOf: artistShelves)

            // Aynı başlıkla gelen tekrar eden rafları kaldır; ayrı türdeki şarkı koleksiyonlarını koru.
            var seenTitles = Set<String>()
            merged = merged.filter { shelf in
                let key = shelf.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if key.isEmpty { return !shelf.songs.isEmpty }
                if seenTitles.contains(key) { return false }
                seenTitles.insert(key)
                return shelf.songs.count >= 3
            }

            if merged.isEmpty {
                self.lastError = errors.first ?? "Öneriler yüklenemedi. Yeniden denemek için aşağı çekin."
                self.shelves = []
            } else {
                self.shelves = merged
                let cache = Cache(day: Self.dayString(), region: selectedRegion,
                                  language: selectedLanguage,
                                  feedVersion: Self.currentFeedVersion, shelves: merged)
                if let data = try? JSONEncoder().encode(cache) {
                    try? data.write(to: self.cacheURL, options: .atomic)
                }
            }
            self.refreshLocalHistoryShelf()
            completion()
        }
    }
}
