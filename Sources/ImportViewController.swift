import UIKit

/// Nhập playlist từ link Spotify / Apple Music / Deezer / SoundCloud / YouTube Music, ghép bài trên YouTube Music.
final class ImportViewController: UIViewController {
    private let field = UITextField()
    private let button = UIButton(type: .system)
    private let status = UILabel()
    private let bar = UIProgressView(progressViewStyle: .default)
    private let missedView = UITextView()
    private var busy = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Çalma Listesi İçe Aktar"
        view.backgroundColor = Theme.background
        navigationItem.largeTitleDisplayMode = .never

        let intro = UILabel()
        intro.numberOfLines = 0
        intro.font = Theme.regular(14)
        intro.textColor = Theme.secondaryText
        intro.text = "Spotify, Apple Music, Deezer, SoundCloud veya YouTube Music üzerinden bir çalma listesi, albüm ya da şarkı bağlantısı yapıştırın. Çalma listesi herkese açık olmalıdır. Mochy şarkıları YouTube Music’te eşleştirir. Aynı bağlantıyı yeniden eklemek yalnızca yeni şarkıları eşitler."

        field.placeholder = "https://open.spotify.com/playlist/…"
        field.font = Theme.regular(16)
        field.textColor = Theme.primaryText
        field.backgroundColor = Theme.card
        field.layer.cornerRadius = 12
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.keyboardType = .URL
        field.clearButtonMode = .whileEditing
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 10))
        field.leftViewMode = .always
        field.heightAnchor.constraint(equalToConstant: 48).isActive = true

        button.setTitle("Panodan yapıştır", for: .normal)
        button.titleLabel?.font = Theme.bold(15)
        button.tintColor = Theme.accent
        button.addTarget(self, action: #selector(pasteLink), for: .touchUpInside)

        let go = UIButton(type: .system)
        go.setTitle("İçe Aktar", for: .normal)
        go.titleLabel?.font = Theme.bold(17)
        go.setTitleColor(.white, for: .normal)
        go.backgroundColor = Theme.accent
        go.layer.cornerRadius = 12
        go.heightAnchor.constraint(equalToConstant: 48).isActive = true
        go.addTarget(self, action: #selector(start), for: .touchUpInside)

        status.numberOfLines = 0
        status.font = Theme.regular(15)
        status.textColor = Theme.primaryText
        bar.progressTintColor = Theme.accent
        bar.isHidden = true

        missedView.isEditable = false
        missedView.backgroundColor = Theme.card
        missedView.textColor = Theme.secondaryText
        missedView.font = Theme.regular(13)
        missedView.layer.cornerRadius = 12
        missedView.isHidden = true

        let stack = UIStackView(arrangedSubviews: [intro, field, button, go, bar, status, missedView])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        let g = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: g.topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: g.bottomAnchor, constant: -100),
            missedView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])
        view.addGestureRecognizer(UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:))))
    }

    @objc private func pasteLink() {
        if let text = UIPasteboard.general.string { field.text = text }
    }

    @objc private func start() {
        if busy { return }
        view.endEditing(true)
        guard let url = PlaylistImporter.extractURL(field.text ?? "") else {
            status.text = "Geçerli bağlantı bulunamadı."
            return
        }
        busy = true
        missedView.isHidden = true
        bar.isHidden = false
        bar.progress = 0
        status.text = "Çalma listesi okunuyor…"
        PlaylistImporter.shared.fetch(url) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                self.finish("Hata: \(error.message)")
            case .success(let collection):
                self.run(collection, link: url.absoluteString)
            }
        }
    }

    private func run(_ collection: ImportedCollection, link: String) {
        if !collection.directSongs.isEmpty && collection.tracks.isEmpty {
            save(collection, songs: collection.directSongs, missed: [], link: link)
            return
        }
        status.text = "\(collection.tracks.count) şarkı eşleştiriliyor…"
        PlaylistImporter.shared.match(collection, progress: { [weak self] done, total in
            DispatchQueue.main.async {
                self?.bar.progress = total > 0 ? Float(done) / Float(total) : 0
                self?.status.text = "\(done)/\(total) şarkı eşleştiriliyor…"
            }
        }, completion: { [weak self] result in
            DispatchQueue.main.async {
                self?.save(collection, songs: result.songs, missed: result.missed, link: link)
            }
        })
    }

    private func save(_ collection: ImportedCollection, songs: [Song], missed: [ImportedTrack], link: String) {
        if songs.isEmpty {
            finish("Hiçbir şarkı eşleştirilemedi.")
            return
        }
        let result = Library.shared.importPlaylist(name: collection.name, songs: songs, sourceURL: link)
        var text = "Tamamlandı: “\(result.playlist.name)” çalma listesine \(result.added) şarkı eklendi (kaynak: \(collection.source))."
        if collection.truncated { text += "\nNot: Bu kaynak yalnızca ilk 100 şarkıyı almanıza izin veriyor." }
        if !missed.isEmpty {
            text += "\n\(missed.count) şarkı eşleştirilemedi."
            missedView.text = missed.map { "• \($0.title) – \($0.artist)" }.joined(separator: "\n")
            missedView.isHidden = false
        }
        finish(text)
    }

    private func finish(_ text: String) {
        busy = false
        bar.isHidden = true
        status.text = text
    }
}
