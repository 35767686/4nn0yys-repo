import UIKit

/// Tab "Ayarlar": cập nhật phần mềm (kiểm tra tự động, kênh Ổn định / Nhà phát triển), thông tin bản dựng, giới thiệu.
final class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIDocumentPickerDelegate {
    private enum Row {
        case theme
        case languageRegion
        case quality
        case reverb
        case videoBackdrop
        case downloadsInfo
        case clearDownloads
        case clearHistory
        case backup
        case restore
        case lastfm
        case accounts
        case mochyAccount
        case advanced
        case importList
        case recap
        case credits
        case version
        case channel
        case autoCheck
        case checkNow
        case updateAvailable
        case info(String, String)
        case link(String, String, String)
    }

    private struct Section {
        let title: String?
        let footer: String?
        let rows: [Row]
    }

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var sections: [Section] = []
    private var documentController: UIDocumentInteractionController?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = AppLocalization.text("Ayarlar")
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = Theme.groupedBackground

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = Theme.groupedBackground
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(updateStateChanged),
                                               name: .updateStateChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateStateChanged),
                                               name: .libraryChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateStateChanged),
                                               name: .reverbChanged, object: nil)
        rebuild()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        rebuild()
        tableView.reloadData()
    }

    @objc private func updateStateChanged() {
        rebuild()
        tableView.reloadData()
    }

    private func rebuild() {
        var updateRows: [Row] = [.version, .channel, .autoCheck, .checkNow]
        if Updater.shared.available != nil {
            updateRows.append(.updateAvailable)
        }
        let channelFooter: String
        if AppSettings.channel == .dev {
            channelFooter = "Geliştirici kanalı, kaynak kodu her güncellendiğinde en yeni derlemeyi alır; hatalar içerebilir. Güncellemeler kurulmadan önce imza ve SHA-256 denetiminden geçirilir."
        } else {
            channelFooter = "Kararlı kanal yalnızca resmî olarak yayımlanan sürümleri alır. Güncellemeler kurulmadan önce imza ve SHA-256 denetiminden geçirilir."
        }
        let installKind = AppInfo.isJailbreakInstall ? "Jailbreak (.deb)" : "Sideload (.ipa)"
        let builtChannel = AppInfo.builtChannel == "dev" ? "Geliştirici" : "Kararlı"
        var accountSections: [Section] = []
        if MochyCloud.shared.isConfigured {
            accountSections = [Section(title: "Hesap", footer: "Beğenilenleri, çalma listelerini, dinleme geçmişini, ayarları ve indirilen şarkıları cihazlar arasında eşitlemek için giriş yapın.", rows: [.mochyAccount])]
        }
        sections = accountSections + [
            Section(title: nil, footer: nil, rows: [.languageRegion]),
            Section(title: AppLocalization.text("Arayüz"), footer: AppLocalization.text("\"Otomatik\", sistemin açık/koyu görünümünü izler (iOS 13 ve üzeri). iOS 12’de otomatik mod koyu görünümü kullanır."),
                    rows: [.theme]),
            Section(title: AppLocalization.text("Ses"), footer: "\"En yüksek\", YouTube Music’in sunduğu en yüksek bit hızına sahip ses akışını seçer (sıkıştırılmış biçimde yaklaşık 256 kbps’ye kadar). YouTube gerçek kayıpsız ses sunmadığı için Mochy bunu Lossless olarak etiketlemez. \"Veri tasarrufu\" en düşük bit hızını seçer. Değişiklik sonraki şarkıdan itibaren uygulanır.",
                    rows: [.quality, .reverb, .videoBackdrop]),
            Section(title: AppLocalization.text("Özellikler"), footer: nil, rows: [.recap, .importList, .advanced]),
            Section(title: AppLocalization.text("Depolama"), footer: nil, rows: [.downloadsInfo, .clearDownloads, .clearHistory]),
            Section(title: AppLocalization.text("Veriler"), footer: "Yedek; beğenilenleri, çalma listelerini, dinleme geçmişini ve ayarları içerir (indirilen müzik dosyaları dâhil değildir). Dosya, Dosyalar ▸ Mochy ▸ MochyBackup konumuna kaydedilir. Geri yükleme mevcut verileri silmez, birleştirir. Uygulama her açılışta ve güncellemeden önce otomatik yedek alır.",
                    rows: [.backup, .restore]),
            Section(title: AppLocalization.text("Yazılım güncellemesi"), footer: channelFooter, rows: updateRows),
            Section(title: AppLocalization.text("Derleme bilgileri"), footer: nil, rows: [
                .info("Derleme kanalı", builtChannel),
                .info("Commit", AppInfo.commit.isEmpty ? "—" : AppInfo.commit),
                .info("Yükleme yöntemi", installKind),
                .info("iOS", AppInfo.osVersion)
            ]),
            Section(title: AppLocalization.text("Hakkında"), footer: nil, rows: [
                .credits,
                .link("Mochy iOS kaynak kodu", "GitHub", UpdateConfig.repoPage)
            ])
        ]
    }

    // MARK: - Bảng

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = sections[section].title else { return nil }
        return M3.headerView(title)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return sections[section].title == nil ? 12 : 40
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footer = sections[section].footer else { return nil }
        return M3.footerView(footer)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let footer = sections[section].footer else { return 8 }
        return M3.footerHeight(footer, width: tableView.bounds.width)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let m3 = cell as? M3Cell else { return }
        let count = sections[indexPath.section].rows.count
        if count == 1 { m3.position = .single }
        else if indexPath.row == 0 { m3.position = .top }
        else if indexPath.row == count - 1 { m3.position = .bottom }
        else { m3.position = .middle }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let updater = Updater.shared
        let cell: UITableViewCell
        switch row {
        case .theme:
            cell = M3Cell(style: .default, reuseIdentifier: nil)
            let control = M3Segmented(items: [ThemeMode.system.title, ThemeMode.light.title, ThemeMode.dark.title], selected: Theme.mode.rawValue)
            control.addTarget(self, action: #selector(themeChanged(_:)), for: .valueChanged)
            cell.accessoryView = control
            cell.textLabel?.text = AppLocalization.text("Görünüm modu")
            cell.selectionStyle = .none

        case .languageRegion:
            cell = M3Cell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = AppLocalization.text("Dil ve Bölge")
            cell.detailTextLabel?.text = YouTubeMusicLocale.languageTitle + " · " + YouTubeMusicLocale.regionTitle
            cell.accessoryType = .disclosureIndicator

        case .quality:
            cell = M3Cell(style: .default, reuseIdentifier: nil)
            let control = M3Segmented(items: [AppLocalization.text("En yüksek"), AppLocalization.text("Veri tasarrufu")], selected: AppSettings.audioQuality == .best ? 0 : 1)
            control.addTarget(self, action: #selector(qualityChanged(_:)), for: .valueChanged)
            cell.accessoryView = control
            cell.textLabel?.text = AppLocalization.text("Kalite")
            cell.selectionStyle = .none

        case .reverb:
            cell = M3Cell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = "Reverb (yankı)"
            cell.detailTextLabel?.text = ReverbSettings.enabled ? "Açık · %\(Int(round(ReverbSettings.amount * 100)))%" : "Kapalı"
            cell.accessoryType = .disclosureIndicator

        case .downloadsInfo:
            cell = M3Cell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = AppLocalization.text("İndirilen şarkılar")
            let size = ByteCountFormatter.string(fromByteCount: Library.shared.totalDownloadBytes(), countStyle: .file)
            cell.detailTextLabel?.text = "\(Library.shared.downloads.count) şarkı · \(size)"
            cell.selectionStyle = .none

        case .clearDownloads:
            cell = M3Cell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = AppLocalization.text("İndirilen tüm şarkıları sil")
            cell.textLabel?.textColor = Theme.accent

        case .clearHistory:
            cell = M3Cell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = AppLocalization.text("Dinleme geçmişini sil")
            cell.textLabel?.textColor = Theme.accent

        case .backup:
            cell = M3Cell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = AppLocalization.text("Şimdi yedekle…")
            cell.textLabel?.textColor = Theme.accent

        case .restore:
            cell = M3Cell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = AppLocalization.text("Yedek dosyasından geri yükle…")
            cell.textLabel?.textColor = Theme.accent

        case .accounts, .mochyAccount, .recap, .importList, .lastfm, .advanced:
            cell = M3Cell(style: .value1, reuseIdentifier: nil)
            switch row {
            case .accounts:
                cell.textLabel?.text = AppLocalization.text("Müzik hesapları (çalma listesi eşitleme)")
                let n = AccountSync.shared.linkedServices.count
                cell.detailTextLabel?.text = n == 0 ? "Bağlı değil" : "\(n) hesap"
            case .mochyAccount:
                cell.textLabel?.text = AppLocalization.text("Mochy hesabı")
                cell.detailTextLabel?.text = MochyCloud.shared.isLoggedIn ? "@" + (MochyCloud.shared.username ?? "") : "Oturum açılmadı"
            case .advanced: cell.textLabel?.text = "Gelişmiş kaynaklar (Canvas, Spicy Lyrics)"
            case .recap: cell.textLabel?.text = "Recap"
            case .importList: cell.textLabel?.text = "Bağlantıdan çalma listesi aktar"
            default:
                cell.textLabel?.text = "Last.fm"
                cell.detailTextLabel?.text = LastFM.shared.isLoggedIn ? LastFM.shared.username : "Oturum açılmadı"
            }
            cell.accessoryType = .disclosureIndicator

        case .credits:
            cell = M3Cell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = "Katkıda Bulunanlar ve Lisans"
            cell.detailTextLabel?.text = "Mochy Music"
            cell.accessoryType = .disclosureIndicator

        case .version:
            cell = M3Cell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = AppLocalization.text("Geçerli sürüm")
            cell.detailTextLabel?.text = "\(AppInfo.version) (build \(AppInfo.build))"
            cell.selectionStyle = .none

        case .channel:
            cell = M3Cell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = AppLocalization.text("Güncelleme kanalı")
            let control = M3Segmented(items: [UpdateChannel.stable.title, UpdateChannel.dev.title], selected: AppSettings.channel == .stable ? 0 : 1)
            control.addTarget(self, action: #selector(channelChanged(_:)), for: .valueChanged)
            cell.accessoryView = control
            cell.selectionStyle = .none

        case .videoBackdrop:
            cell = M3Cell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = AppLocalization.text("Çalma sırasında arka plan videosu (varsa)")
            let toggle = M3Switch()
            toggle.isOn = AppSettings.videoBackdrop
            toggle.addTarget(self, action: #selector(videoBackdropChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            cell.selectionStyle = .none

        case .autoCheck:
            cell = M3Cell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = AppLocalization.text("Güncellemeleri otomatik denetle")
            let toggle = M3Switch()
            toggle.isOn = AppSettings.autoCheck
            toggle.addTarget(self, action: #selector(autoCheckChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            cell.selectionStyle = .none

        case .checkNow:
            cell = M3Cell(style: .subtitle, reuseIdentifier: nil)
            cell.textLabel?.text = AppLocalization.text("Güncellemeleri şimdi denetle")
            cell.textLabel?.textColor = Theme.accent
            cell.detailTextLabel?.numberOfLines = 0
            cell.detailTextLabel?.textColor = Theme.secondaryText
            if updater.isChecking {
                cell.detailTextLabel?.text = "Denetleniyor…"
                let spinner = UIActivityIndicatorView(style: Theme.spinnerStyle())
                spinner.startAnimating()
                cell.accessoryView = spinner
            } else if updater.lastMessage.isEmpty {
                cell.detailTextLabel?.text = nil
            } else {
                cell.detailTextLabel?.text = updater.lastMessage
            }

        case .updateAvailable:
            cell = M3Cell(style: .subtitle, reuseIdentifier: nil)
            if let info = updater.available {
                cell.textLabel?.text = "Yeni sürüm: \(info.version) (derleme \(info.build))"
                let kind = info.channel == "dev" ? "Beta sürüm" : "Kararlı sürüm"
                cell.detailTextLabel?.text = "\(kind) · ayrıntıları görmek ve indirmek için dokunun"
            }
            cell.textLabel?.textColor = Theme.accent
            cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            cell.detailTextLabel?.textColor = Theme.secondaryText
            cell.accessoryType = .disclosureIndicator

        case .info(let title, let value):
            cell = M3Cell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = value
            cell.selectionStyle = .none

        case .link(let title, let value, _):
            cell = M3Cell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = value
            cell.accessoryType = .disclosureIndicator
        }
        let keepColor = cell.textLabel?.textColor
        Theme.style(cell: cell, grouped: true)
        cell.backgroundColor = Theme.cellBackground
        if case .updateAvailable = row {} else { cell.textLabel?.font = Theme.regular(16) }
        cell.detailTextLabel?.font = Theme.regular(14)
        switch row {
        case .checkNow, .updateAvailable, .clearDownloads, .clearHistory, .backup, .restore:
            cell.textLabel?.textColor = keepColor
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = sections[indexPath.section].rows[indexPath.row]
        switch row {
        case .languageRegion:
            navigationController?.pushViewController(LanguageRegionViewController(), animated: true)
        case .accounts:
            AccountsSheetViewController.present(from: self)
        case .mochyAccount:
            navigationController?.pushViewController(MochyAccountViewController(), animated: true)
        case .reverb:
            ReverbPanelViewController.present(from: self)
        case .recap:
            navigationController?.pushViewController(RecapViewController(), animated: true)
        case .importList:
            navigationController?.pushViewController(ImportViewController(), animated: true)
        case .advanced:
            navigationController?.pushViewController(SourcesViewController(), animated: true)
        case .lastfm:
            navigationController?.pushViewController(LastFMViewController(), animated: true)
        case .credits:
            navigationController?.pushViewController(CreditsViewController(), animated: true)
        case .clearDownloads:
            confirm("İndirilen tüm şarkılar silinsin mi?", button: "Sil") { Library.shared.removeAllDownloads() }
        case .clearHistory:
            confirm("Dinleme geçmişinin tamamı silinsin mi?", button: "Sil") { Library.shared.clearHistory() }
        case .backup:
            backupNow()
        case .restore:
            pickBackup()
        case .checkNow:
            Updater.shared.check(manual: true)
        case .updateAvailable:
            presentUpdateSheet()
        case .link(_, _, let urlString):
            open(urlString)
        default:
            break
        }
    }


    // MARK: - Hành động

    @objc private func themeChanged(_ sender: M3Segmented) {
        guard let mode = ThemeMode(rawValue: sender.selectedSegmentIndex) else { return }
        Theme.mode = mode
        NotificationCenter.default.post(name: .themeChanged, object: nil)
    }

    @objc private func qualityChanged(_ sender: M3Segmented) {
        AppSettings.audioQuality = sender.selectedSegmentIndex == 0 ? .best : .saver
    }

    private func confirm(_ message: String, button: String, _ action: @escaping () -> Void) {
        let alert = AppLocalization.alertController(title: message, message: nil, preferredStyle: .alert)
        alert.addAction(AppLocalization.alertAction(title: "İptal", style: .cancel, handler: nil))
        alert.addAction(AppLocalization.alertAction(title: button, style: .destructive) { _ in action() })
        present(alert, animated: true, completion: nil)
    }

    @objc private func channelChanged(_ sender: M3Segmented) {
        AppSettings.channel = sender.selectedSegmentIndex == 0 ? .stable : .dev
        Updater.shared.channelDidChange()
    }

    @objc private func videoBackdropChanged(_ sender: M3Switch) {
        AppSettings.videoBackdrop = sender.isOn
    }

    @objc private func autoCheckChanged(_ sender: M3Switch) {
        AppSettings.autoCheck = sender.isOn
        if sender.isOn {
            Updater.shared.autoCheckIfNeeded()
        }
    }

    private func open(_ string: String) {
        guard let url = URL(string: string), let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "sileo" else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private func sizeText(_ bytes: Int64) -> String {
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func showMessage(_ title: String, _ message: String) {
        let alert = AppLocalization.alertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(AppLocalization.alertAction(title: "Kapat", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func presentUpdateSheet() {
        guard let info = Updater.shared.available else { return }
        var message = "Sürüm \(info.version) (derleme \(info.build))"
        if !info.commit.isEmpty { message += ", commit \(info.commit)" }
        message += "\n"
        message += info.signed ? "Dijital imza: geçerli ✓" : "Dijital imza: yok (yalnızca SHA-256 denetleniyor)"
        if !info.notes.isEmpty {
            message += "\n\n" + String(info.notes.prefix(600))
        }
        message += "\n\n" + AppLocalization.text("İndirmeden önce verileriniz otomatik olarak yedeklenir. .ipa dosyasını imzalarken Bundle ID’yi (\(UpdateConfig.appId)) değiştirmeyin ve verileri korumak için eski sürümün üzerine yükleyin.")
        let alert = AppLocalization.alertController(title: "Güncelleme mevcut", message: message, preferredStyle: .alert)

        // Cả hai nguồn (.ipa để ký bằng ESign…, .deb cho Sileo/Filza) đều hiện ra; nguồn hợp với cách cài của bạn ghi "khuyên dùng".
        let recommended = Updater.shared.preferredFile(for: info)
        var files: [UpdateFile] = []
        if let first = recommended { files.append(first) }
        for other in [info.ipa, info.deb] {
            if let other = other, !files.contains(where: { $0.name == other.name }) { files.append(other) }
        }
        for file in files {
            let kind = file.name.lowercased().hasSuffix(".deb") ? ".deb (Sileo, Filza)" : ".ipa (ESign ile imzala…)"
            let star = file.name == recommended?.name ? " — önerilen" : ""
            alert.addAction(AppLocalization.alertAction(title: "\(kind)\(star) indir · \(sizeText(file.size))", style: .default) { [weak self] _ in
                self?.startDownload(file)
            })
        }
        if AppInfo.isJailbreakInstall && info.channel == "stable" {
            alert.addAction(AppLocalization.alertAction(title: "Sileo’yu aç (repo kaynağı)", style: .default) { [weak self] _ in
                self?.open("sileo://package/\(UpdateConfig.appId)")
            })
        }
        alert.addAction(AppLocalization.alertAction(title: "GitHub’da görüntüle", style: .default) { [weak self] _ in
            self?.open(UpdateConfig.releasesPage)
        })
        alert.addAction(AppLocalization.alertAction(title: "Daha sonra", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func startDownload(_ file: UpdateFile) {
        // Sao lưu dữ liệu trước khi cập nhật, phòng khi bản ký lại dùng Bundle ID khác hoặc phải gỡ app.
        BackupManager.backup(name: "truoc-cap-nhat")
        let alert = AppLocalization.alertController(title: "Yükleniyor", message: "\(file.name)\n0%", preferredStyle: .alert)
        alert.addAction(AppLocalization.alertAction(title: "İptal", style: .cancel) { _ in
            Updater.shared.cancelDownload()
        })
        present(alert, animated: true, completion: nil)

        Updater.shared.download(file, progress: { fraction in
            alert.message = "\(file.name)\n\(Int(fraction * 100))%"
        }, completion: { [weak self] result in
            if case .failure(let error) = result, error.cancelled { return }
            alert.dismiss(animated: true) {
                switch result {
                case .success(let url):
                    self?.presentDownloaded(url, file: file)
                case .failure(let error):
                    self?.showMessage("İndirme başarısız oldu", error.message)
                }
            }
        })
    }

    private func presentDownloaded(_ url: URL, file: UpdateFile) {
        let hint: String
        if file.name.lowercased().hasSuffix(".deb") {
            hint = "Sileo’yu (veya Filza’yı) seçip Yükle’ye dokunun."
        } else {
            hint = "İmzalamak ve yüklemek için ESign / Sideloadly / AltStore’u seçin."
        }
        let alert = AppLocalization.alertController(title: "İndirildi ve doğrulandı",
                                      message: "\(file.name)\nSHA-256 değeri sürümle eşleşiyor.\n\(hint)",
                                      preferredStyle: .alert)
        alert.addAction(AppLocalization.alertAction(title: "Başka bir uygulamayla aç…", style: .default) { [weak self] _ in
            self?.openInOtherApp(url)
        })
        alert.addAction(AppLocalization.alertAction(title: "Paylaş / Dosyalar’a kaydet…", style: .default) { [weak self] _ in
            let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            self?.present(controller, animated: true, completion: nil)
        })
        alert.addAction(AppLocalization.alertAction(title: "Kapat", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func openInOtherApp(_ url: URL) {
        let controller = UIDocumentInteractionController(url: url)
        documentController = controller
        let anchor = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        if !controller.presentOpenInMenu(from: anchor, in: view, animated: true) {
            showMessage("Uygun uygulama bulunamadı",
                        "Bu dosyayı açabilecek bir uygulama bulunamadı. “Paylaş / Dosyalar’a kaydet…” seçeneğini kullanıp dosyayı Sileo, Filza veya ESign ile açın.")
        }
    }

    // MARK: - Sao lưu / khôi phục

    private func backupNow() {
        guard let url = BackupManager.backup(name: BackupManager.timestampName()) else {
            showMessage("Yedekleme başarısız oldu", "Yedek dosyası yazılamadı.")
            return
        }
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let popover = controller.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }
        present(controller, animated: true, completion: nil)
    }

    private func pickBackup() {
        let picker = UIDocumentPickerViewController(documentTypes: ["public.json", "public.data", "public.text"], in: .import)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        switch BackupManager.restore(from: url) {
        case .success(let added):
            showMessage("Geri yüklendi", added == 0 ? "Yeni öğe yok; mevcut veriler zaten güncel." : "Arşive \(added) yeni öğe eklendi.")
        case .failure(let error):
            showMessage("Geri yükleme başarısız oldu", error.message)
        }
    }
}
