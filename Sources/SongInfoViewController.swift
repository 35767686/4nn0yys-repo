import UIKit

/// "Şarkı Bilgileri" (kiểu Stats for nerds): codec, bitrate, độ dài thật, nguồn phát, lời…
final class SongInfoViewController: UITableViewController {
    private var sections: [(String, [(String, String)])] = []
    private let song: Song

    init(song: Song) {
        self.song = song
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Şarkı Bilgileri"
        tableView.backgroundColor = Theme.groupedBackground
        tableView.allowsSelection = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
        build()
    }

    @objc private func close() { dismiss(animated: true, completion: nil) }

    private func time(_ seconds: Double) -> String {
        let s = Int(seconds.rounded())
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private func build() {
        let engine = PlayerEngine.shared
        let isCurrent = engine.currentSong == song
        var general: [(String, String)] = [("Ad", song.title), ("Sanatçı", song.artist), ("Video kimliği", song.videoId)]
        if let d = song.duration { general.append(("Süre (YouTube)", d)) }
        sections.append(("Şarkılar", general))

        var stream: [(String, String)] = []
        let downloaded = Library.shared.isDownloaded(song)
        if isCurrent, let info = engine.streamInfo {
            stream.append(("Çalma kaynağı", engine.isLocal ? "İndirilen dosya" : "Çevrimiçi"))
            stream.append(("Codec", info.codecLabel))
            if info.bitrate > 0 { stream.append(("Bitrate", "\(info.bitrate / 1000) kbps")) }
            if info.sampleRate > 0 { stream.append(("Örnekleme hızı", "\(info.sampleRate) Hz")) }
            stream.append(("Client", info.clientName))
            if info.contentLength > 0 { stream.append(("Akış boyutu", ByteCountFormatter.string(fromByteCount: info.contentLength, countStyle: .file))) }
            if info.durationSeconds > 0 { stream.append(("Gerçek süre", time(info.durationSeconds))) }
            stream.append(("Son bayt denetimi", info.unverified ? "Başarısız (kesilmiş olabilir)" : "Başarılı"))
        } else if isCurrent && engine.isLocal {
            stream.append(("Çalma kaynağı", "İndirilen dosya"))
        } else {
            stream.append(("Çalma kaynağı", isCurrent ? "Bilgiler yükleniyor…" : "Şu anda çalınan şarkı değil"))
        }
        if isCurrent && engine.duration > 0 { stream.append(("Oynatıcı süresi", time(engine.duration))) }
        sections.append(("Ses akışı", stream))

        var offline: [(String, String)] = [("İndirilenler", downloaded ? "Var" : "Henüz yok")]
        if downloaded {
            offline.append(("Dosya boyutu", ByteCountFormatter.string(fromByteCount: Library.shared.fileSize(of: song), countStyle: .file)))
            let real = DownloadStore.realDuration(for: song)
            if real > 0 { offline.append(("Kaydedilen süre", time(real))) }
            offline.append(("Eşlik eden şarkı sözleri", DownloadStore.lyrics(song.videoId) != nil ? "Var" : "Yok"))
        }
        sections.append(("Çevrimdışı", offline))

        var lyr: [(String, String)] = []
        if let result = LyricsService.shared.cached(song.videoId) ?? DownloadStore.lyrics(song.videoId) {
            lyr.append(("Şarkı sözü kaynağı", result.source))
            lyr.append(("Tür", result.synced.isEmpty ? "Düz metin" : "\(result.synced.count) satırla eşzamanlandı"))
        } else {
            lyr.append(("Şarkı sözü kaynağı", "İndirilmedi / yok"))
        }
        sections.append(("Şarkı sözleri", lyr))
    }

    override func numberOfSections(in tableView: UITableView) -> Int { return sections.count }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return sections[section].1.count }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { return AppLocalization.text(sections[section].0) }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        let row = sections[indexPath.section].1[indexPath.row]
        cell.backgroundColor = Theme.cellBackground
        cell.textLabel?.text = row.0
        cell.textLabel?.textColor = Theme.primaryText
        cell.textLabel?.font = Theme.regular(15)
        cell.detailTextLabel?.text = row.1
        cell.detailTextLabel?.textColor = Theme.secondaryText
        cell.detailTextLabel?.font = Theme.regular(14)
        cell.detailTextLabel?.numberOfLines = 0
        return cell
    }
}
