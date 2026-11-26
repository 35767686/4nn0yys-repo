import UIKit

/// Tek bir Ayarlar girdisinin içinde arayüz/YouTube Music dili ve YouTube Music ülke-bölgesi seçilir.
final class LanguageRegionViewController: UITableViewController {
    private enum Section: Int, CaseIterable { case language, region }

    init() { super.init(style: .grouped) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = AppLocalization.text("Dil ve Bölge")
        navigationItem.largeTitleDisplayMode = .never
        tableView.backgroundColor = Theme.groupedBackground
        tableView.separatorStyle = .none
    }

    override func numberOfSections(in tableView: UITableView) -> Int { return Section.allCases.count }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return 1 }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let kind = Section(rawValue: section) else { return nil }
        return AppLocalization.text(kind == .language ? "Dil" : "Bölge")
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let kind = Section(rawValue: section) else { return nil }
        if kind == .language {
            return AppLocalization.text("Bu değişiklik arayüz dilini ve YouTube Music istek dilini birlikte değiştirir.")
        }
        return AppLocalization.text("Ülke/bölge YouTube Music listelerini ve önerilerini etkiler. Konum izni kullanılmaz.")
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = M3Cell(style: .value1, reuseIdentifier: nil)
        if indexPath.section == Section.language.rawValue {
            cell.textLabel?.text = AppLocalization.text("Uygulama dili")
            cell.detailTextLabel?.text = YouTubeMusicLocale.languageTitle
        } else {
            cell.textLabel?.text = AppLocalization.text("YouTube Music bölgesi")
            cell.detailTextLabel?.text = YouTubeMusicLocale.regionTitle
        }
        cell.accessoryType = .disclosureIndicator
        Theme.style(cell: cell, grouped: true)
        cell.backgroundColor = Theme.cellBackground
        cell.textLabel?.font = Theme.regular(16)
        cell.detailTextLabel?.font = Theme.regular(14)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == Section.language.rawValue { showLanguagePicker(from: indexPath) }
        else { showRegionPicker(from: indexPath) }
    }

    private func showLanguagePicker(from indexPath: IndexPath) {
        let alert = AppLocalization.alertController(title: AppLocalization.text("Dil"),
                                      message: AppLocalization.text("Bu değişiklik arayüz dilini ve YouTube Music istek dilini birlikte değiştirir."),
                                      preferredStyle: .actionSheet)
        let current = AppSettings.language
        let deviceTitle = AppLocalization.text("Cihaz dili")
        alert.addAction(AppLocalization.alertAction(title: deviceTitle + (current == "system" ? " ✓" : ""), style: .default) { [weak self] _ in
            self?.applyLanguage("system")
        })
        for option in YouTubeMusicLocale.languageOptions {
            let checked = current == option.code ? " ✓" : ""
            alert.addAction(AppLocalization.alertAction(title: option.title + checked, style: .default) { [weak self] _ in
                self?.applyLanguage(option.code)
            })
        }
        alert.addAction(AppLocalization.alertAction(title: AppLocalization.text("İptal"), style: .cancel, handler: nil))
        configurePopover(alert, from: indexPath)
        present(alert, animated: true, completion: nil)
    }

    private func showRegionPicker(from indexPath: IndexPath) {
        let alert = AppLocalization.alertController(title: AppLocalization.text("Bölge"),
                                      message: AppLocalization.text("Ülke/bölge YouTube Music listelerini ve önerilerini etkiler. Konum izni kullanılmaz."),
                                      preferredStyle: .actionSheet)
        for option in YouTubeMusicLocale.regionOptions {
            let name = option.code == "auto" ? AppLocalization.text("Otomatik") : AppLocalization.localizedRegionName(option.code)
            let checked = AppSettings.region == option.code ? " ✓" : ""
            alert.addAction(AppLocalization.alertAction(title: name + checked, style: .default) { [weak self] _ in
                self?.applyRegion(option.code)
            })
        }
        alert.addAction(AppLocalization.alertAction(title: AppLocalization.text("İptal"), style: .cancel, handler: nil))
        configurePopover(alert, from: indexPath)
        present(alert, animated: true, completion: nil)
    }

    private func configurePopover(_ alert: UIAlertController, from indexPath: IndexPath) {
        if let popover = alert.popoverPresentationController,
           let cell = tableView.cellForRow(at: indexPath) {
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
            popover.permittedArrowDirections = [.up, .down]
        }
    }

    private func applyLanguage(_ code: String) {
        guard AppSettings.language != code else { return }
        AppSettings.language = code
        notifyPreferencesChanged(languageChanged: true)
    }

    private func applyRegion(_ code: String) {
        guard AppSettings.region != code else { return }
        AppSettings.region = code
        notifyPreferencesChanged(languageChanged: false)
    }

    private func notifyPreferencesChanged(languageChanged: Bool) {
        NotificationCenter.default.post(name: .musicLocaleChanged, object: nil)
        tableView.reloadData()
        if languageChanged {
            NotificationCenter.default.post(name: .appLanguageChanged, object: nil)
        }
    }
}
