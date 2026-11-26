import UIKit

/// Khoá cho các nguồn nâng cao: cookie sp_dc của Spotify (video Canvas) và API key Spicy Lyrics.
final class SourcesViewController: UIViewController {
    private let spdc = UITextField()
    private let spicy = UITextField()
    private let note = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Gelişmiş Kaynaklar"
        view.backgroundColor = Theme.background
        navigationItem.largeTitleDisplayMode = .never
        for (f, p) in [(spdc, "Spotify sp_dc çerezi"), (spicy, "API key Spicy Lyrics (sl_sk_… / sl_pk_…)")] {
            f.placeholder = p
            f.font = Theme.regular(15)
            f.textColor = Theme.primaryText
            f.backgroundColor = Theme.card
            f.layer.cornerRadius = 10
            f.autocapitalizationType = .none
            f.autocorrectionType = .no
            f.clearButtonMode = .whileEditing
            f.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 10))
            f.leftViewMode = .always
            f.heightAnchor.constraint(equalToConstant: 46).isActive = true
        }
        spdc.text = SpotifyCanvas.cookie
        spicy.text = UserDefaults.standard.string(forKey: "spicy.key")
        note.numberOfLines = 0
        note.font = Theme.regular(13)
        note.textColor = Theme.secondaryText
        note.text = AppLocalization.text("""
        • sp_dc: Tarayıcıda open.spotify.com adresine giriş yapın, geliştirici araçlarında ▸ Cookies bölümünü açıp sp_dc değerini kopyalayın. Bu çerez şarkı Canvas videolarını almak için kullanılır; Canvas yoksa uygulama YouTube müzik videosunu, o da yoksa albüm kapağını gösterir. Bu, Spotify’ın resmî olmayan bir API yöntemidir; çalışmayı durdurabilir veya hizmet koşullarını ihlal edebilir. Kullanırken dikkatli olun. Çerez yalnızca bu cihazda saklanır.
        • Spicy Lyrics: developers.spicylyrics.org adresinde bir uygulama oluşturup anahtarı buraya yapıştırın. İstemci anahtarı kullanıyorsanız "Allow requests with no Origin header" seçeneğini etkinleştirin.
        • Diğer kaynaklar (BiniLyrics, Musixmatch, Unison, NetEase, LRCLIB, QQ Music, KuGou, Genius, YouLy+, SimpMusic) anahtar gerektirmez.
        """)
        let save = UIButton(type: .system)
        save.setTitle("Kaydet", for: .normal)
        save.titleLabel?.font = Theme.bold(17)
        save.setTitleColor(.white, for: .normal)
        save.backgroundColor = Theme.accent
        save.layer.cornerRadius = 12
        save.heightAnchor.constraint(equalToConstant: 48).isActive = true
        save.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [spdc, spicy, save, note])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        view.addGestureRecognizer(UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:))))
    }

    @objc private func saveTapped() {
        view.endEditing(true)
        SpotifyCanvas.cookie = spdc.text ?? ""
        UserDefaults.standard.set((spicy.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines), forKey: "spicy.key")
        Toast.show("Kaydedildi")
    }
}
