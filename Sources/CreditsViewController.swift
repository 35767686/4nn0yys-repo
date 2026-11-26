import UIKit

/// Trang "Katkıda Bulunanlar ve Lisans": gom mọi ghi công tác giả gốc (Mochy Music và các dự án nó dựa trên), giấy phép GPL-3.0, mã nguồn.
final class CreditsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private struct Item {
        let title: String
        let detail: String
        let url: String?
    }

    private struct Block {
        let title: String
        let footer: String?
        let items: [Item]
    }

    private let blocks: [Block] = [
        Block(title: "Orijinal proje",
              footer: "Mochy iOS, Mochy Music’in fikirlerinden, YouTube Music isteklerinden, istemci yapılandırmasından ve arayüz tasarımından yararlanılarak iOS 12 ve üzeri için Swift/UIKit ile yeniden yazılmış bir sürümdür. Mochy Music’ten uyarlanmıştır.",
              items: [Item(title: "Mochy Music", detail: "realidkroo", url: "https://github.com/realidkroo/mochy-music")]),
        Block(title: "Mochy Music’in temeli",
              footer: "Mochy Music, ViviMusic’ten geliştirilmiş ve Metrolist üzerine kurulmuştur. Katkı sahiplerinin atıfları korunmuştur.",
              items: [Item(title: "ViviMusic", detail: "vivizzz007Z", url: nil),
                      Item(title: "Metrolist", detail: "Mostafa Alagamy", url: nil),
                      Item(title: "InnerTube (RiMusic)", detail: "fast4x", url: nil)]),
        Block(title: "Kullanılan hizmetler",
              footer: "Her hizmet kendi geliştiricisine aittir.",
              items: [Item(title: "LRCLIB", detail: "tranxuanthang", url: nil),
                      Item(title: "SimpMusic", detail: "maxrave-dev", url: nil),
                      Item(title: "LyricsPlus", detail: "Ibra Al Tabian", url: nil),
                      Item(title: "Better Lyrics API", detail: "Boidushya", url: nil),
                      Item(title: "AutoEq", detail: "AutoEq", url: nil)]),
        Block(title: "Lisans ve kaynak kodu",
              footer: "Mochy iOS, GPL-3.0 lisansını kullanır. Değiştirilmiş bir sürüm yayımlarsanız bu atıfları koruyun ve kaynak kodunu açık tutun.",
              items: [Item(title: "GPL-3.0", detail: "Lisansın tam metni", url: "https://www.gnu.org/licenses/gpl-3.0.html"),
                      Item(title: "Mochy iOS kaynak kodu", detail: "GitHub", url: UpdateConfig.repoPage)]),
        Block(title: "Not",
              footer: "Mochy iOS resmî olmayan bir projedir; YouTube, Google, Apple veya bağlandığı diğer hizmetlerle bağlantısı yoktur. Uygulama müzik depolamaz veya dağıtmaz.",
              items: [])
    ]

    private let tableView = UITableView(frame: .zero, style: .grouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Katkıda Bulunanlar ve Lisans"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = Theme.groupedBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = Theme.groupedBackground
        tableView.separatorColor = Theme.separator
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return blocks.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blocks[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return AppLocalization.text(blocks[section].title)
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return blocks[section].footer.map { AppLocalization.text($0) }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        (view as? UITableViewHeaderFooterView)?.textLabel?.textColor = Theme.secondaryText
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        (view as? UITableViewHeaderFooterView)?.textLabel?.textColor = Theme.secondaryText
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = blocks[indexPath.section].items[indexPath.row]
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.detail
        cell.accessoryType = item.url != nil ? .disclosureIndicator : .none
        cell.selectionStyle = item.url != nil ? .default : .none
        Theme.style(cell: cell, grouped: true)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = blocks[indexPath.section].items[indexPath.row]
        guard let string = item.url, let url = URL(string: string), url.scheme?.lowercased() == "https" else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
