import UIKit

/// Menu thao tác cho một bài hát (phát tiếp, hàng đợi, yêu thích, playlist, tải xuống).
enum SongActions {
    static func present(for song: Song, from vc: UIViewController, sourceView: UIView? = nil,
                        removeTitle: String? = nil, onRemove: (() -> Void)? = nil) {
        let sheet = AppLocalization.alertController(title: song.title, message: song.artist, preferredStyle: .actionSheet, localizeTitle: false, localizeMessage: false)
        let player = PlayerEngine.shared
        let library = Library.shared

        sheet.addAction(AppLocalization.alertAction(title: "Sıradaki şarkı olarak çal", style: .default) { _ in
            player.playNext(song)
            Toast.show("Sıradaki olarak çalınacak")
        })
        sheet.addAction(AppLocalization.alertAction(title: "Sıraya ekle", style: .default) { _ in
            player.addToQueue(song)
            Toast.show("Çalma sırasına eklendi")
        })
        let liked = library.isLiked(song)
        sheet.addAction(AppLocalization.alertAction(title: liked ? "Beğenmekten vazgeç" : "Beğenilenlere ekle", style: .default) { _ in
            let nowLiked = library.toggleLike(song)
            LastFM.shared.love(song, loved: nowLiked)
            Toast.show(nowLiked ? "Beğenilenlere eklendi" : "Beğenilenlerden kaldırıldı")
        })
        if let artistId = song.artistId, !artistId.isEmpty {
            sheet.addAction(AppLocalization.alertAction(title: "Sanatçıyı Gör", style: .default) { _ in
                MusicPageViewController.present(artist: song.artist, id: artistId, from: vc)
            })
        }
        sheet.addAction(AppLocalization.alertAction(title: "Çalma listesine ekle…", style: .default) { _ in
            presentPlaylistPicker(for: song, from: vc, sourceView: sourceView)
        })

        let manager = DownloadManager.shared
        if library.isDownloaded(song) {
            sheet.addAction(AppLocalization.alertAction(title: "İndirilen dosyayı sil", style: .destructive) { _ in
                library.removeDownload(song)
                Toast.show("İndirilen dosya silindi")
            })
        } else if manager.isActive(song.videoId) {
            sheet.addAction(AppLocalization.alertAction(title: "İndirmeyi İptal Et", style: .destructive) { _ in
                manager.cancel(song.videoId)
            })
        } else {
            sheet.addAction(AppLocalization.alertAction(title: "Çevrimdışı dinlemek için indir", style: .default) { _ in
                manager.start(song)
                Toast.show("İndiriliyor…")
            })
        }
        if let removeTitle = removeTitle, let onRemove = onRemove {
            sheet.addAction(AppLocalization.alertAction(title: removeTitle, style: .destructive) { _ in onRemove() })
        }
        sheet.addAction(AppLocalization.alertAction(title: "Kapat", style: .cancel, handler: nil))
        anchor(sheet, in: vc, sourceView: sourceView)
        vc.present(sheet, animated: true, completion: nil)
    }

    static func presentPlaylistPicker(for song: Song, from vc: UIViewController, sourceView: UIView? = nil) {
        let sheet = AppLocalization.alertController(title: "Çalma listesine ekle", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(AppLocalization.alertAction(title: "Yeni çalma listesi…", style: .default) { _ in
            promptNewPlaylist(from: vc) { name in
                let list = Library.shared.createPlaylist(name: name, with: song)
                Toast.show("“\(list.name)” oluşturuldu")
            }
        })
        for list in Library.shared.playlists {
            sheet.addAction(AppLocalization.alertAction(title: list.name, style: .default, localizeTitle: false) { _ in
                if Library.shared.add(song, toPlaylist: list.id) {
                    Toast.show("“\(list.name)” listesine eklendi")
                } else {
                    Toast.show("Bu şarkı zaten “\(list.name)” listesinde")
                }
            })
        }
        sheet.addAction(AppLocalization.alertAction(title: "Kapat", style: .cancel, handler: nil))
        anchor(sheet, in: vc, sourceView: sourceView)
        vc.present(sheet, animated: true, completion: nil)
    }

    static func promptNewPlaylist(from vc: UIViewController, initial: String = "", title: String = "Yeni Çalma Listesi",
                                  confirm: String = "Oluştur", _ done: @escaping (String) -> Void) {
        let alert = AppLocalization.alertController(title: title, message: "Çalma listesine ad ver", preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "Çalma listesi adı"
            field.text = initial
            field.autocapitalizationType = .sentences
        }
        alert.addAction(AppLocalization.alertAction(title: "İptal", style: .cancel, handler: nil))
        alert.addAction(AppLocalization.alertAction(title: confirm, style: .default) { _ in
            done(alert.textFields?.first?.text ?? "")
        })
        vc.present(alert, animated: true, completion: nil)
    }

    private static func anchor(_ sheet: UIAlertController, in vc: UIViewController, sourceView: UIView?) {
        if let popover = sheet.popoverPresentationController {
            let source = sourceView ?? vc.view!
            popover.sourceView = source
            popover.sourceRect = sourceView == nil
                ? CGRect(x: source.bounds.midX, y: source.bounds.midY, width: 1, height: 1)
                : source.bounds
        }
    }
}
