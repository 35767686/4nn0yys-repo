import Foundation
import UIKit

/// Central localization service for static and interpolated interface text.
/// Unknown content such as song titles, artist names, usernames and original lyrics remains unchanged.
enum AppLocalization {
    /// Creates alert-sheet actions through the shared localizer.
    static func alertAction(title: String?, style: UIAlertAction.Style,
                            localizeTitle: Bool = true,
                            handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
        let resolvedTitle = localizeTitle ? title.map { text($0) } : title
        return UIAlertAction(title: resolvedTitle, style: style, handler: handler)
    }

    static func alertController(title: String?, message: String?,
                                preferredStyle: UIAlertController.Style,
                                localizeTitle: Bool = true,
                                localizeMessage: Bool = true) -> UIAlertController {
        let resolvedTitle = localizeTitle ? title.map { text($0) } : title
        let resolvedMessage = localizeMessage ? message.map { text($0) } : message
        return UIAlertController(title: resolvedTitle,
                                 message: resolvedMessage,
                                 preferredStyle: preferredStyle)
    }

    static func text(_ key: String) -> String {
        let code = YouTubeMusicLocale.languageCode
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return key }
        let leadingCount = key.prefix(while: { $0.isWhitespace || $0.isNewline }).count
        let trailingCount = key.reversed().prefix(while: { $0.isWhitespace || $0.isNewline }).count
        let leading = String(key.prefix(leadingCount))
        let trailing = trailingCount > 0 ? String(key.suffix(trailingCount)) : ""
        let coreEnd = key.index(key.endIndex, offsetBy: -trailingCount)
        let coreStart = key.index(key.startIndex, offsetBy: leadingCount)
        let core = String(key[coreStart..<coreEnd])

        if let value = translatedCore(core, language: code) {
            return leading + value + trailing
        }
        if let value = dynamicText(core, language: code) {
            return leading + value + trailing
        }
        return key
    }

    private static func translatedCore(_ key: String, language: String) -> String? {
        if let value = translations[language]?[key]
            ?? supplemental[language]?[key]
            ?? actionOnly[language]?[key]
            ?? AppFeatureTranslations.exactValue(for: key, language: language)
            ?? AppFeatureTranslationsMore.value(for: key, language: language) {
            return value
        }
        // Turkish is the source language and must remain unchanged when selected.
        guard language != "tr" else { return nil }
        return AppFeatureTranslations.value(for: key, language: "en")
            ?? AppFeatureTranslationsExtra.value(for: key)
    }

    /// Localizes common interpolated UI strings while leaving song and artist names untouched.
    private static func dynamicText(_ value: String, language: String) -> String? {
        // Turkish is the source language. Never translate dynamic values while it is selected.
        guard language != "tr" else { return nil }
        let likelyLocalized = ["şarkı", "hesap", "dakika", "gün", "Hata:", "Oturum açıldı:",
                               "Bağlantısı", "bağlantısı", "eşitleniyor", "eşleştiriliyor", "eşleştirildi",
                               "duracak", "Yeni sürüm:", "Açık · %", "Bulanıklığı:", "Kalınlığı:",
                               "bin örnek", "sonuç bulunamadı", "kullanıcı bulunamadı", "oluşturuldu",
                               "Bu şarkı zaten", "indiriliyor (aynı anda", "SHA-256 değeri", "Mochy iOS",
                               "Arama hatası", "Müzik hesabı", "hiçbir çalma listesi", "şarkı eşleştirildi",
                               "Son eşitleme:", "dinlediklerine göre", "Kalan ", "sanatçısının sayfası",
                               "Dosya kaydedilemedi:", "Sunucu HTTP", "dinleme", "kez", "Kapanma zamanı:",
                               "Tamamlandı:", "eşleştirilemedi", "Arşive ", "Etkin (", "Filtre oluşturulamadı",
                               "Uygulanamadı:", "Denetlenemedi:", "İmza indirilemedi:", "Yeni sürüm mevcut:",
                               "İşlem gerçekleştirilemedi (kod",
                               "eşzamanlandı", "listesine eklendi", "sayfada oturum açın", "sürüm (derleme",
                               "sunucusu HTTP", "dosya boyutu eşleşmiyor", "satırla eşzamanlandı",
                               "bağlantı yarıda kesildi", "arşivden silinecek", "Geçersiz yanıt:"]
        guard likelyLocalized.contains(where: { value.contains($0) }) else { return nil }

        func captures(_ pattern: String) -> [String]? {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)) else { return nil }
            return (1..<match.numberOfRanges).map { index in
                guard let range = Range(match.range(at: index), in: value) else { return "" }
                return String(value[range])
            }
        }
        func countWord(_ unit: String, _ count: String) -> String {
            switch (language, unit) {
            case ("en", "song"): return "\(count) songs"
            case ("es", "song"): return "\(count) canciones"
            case ("fr", "song"): return "\(count) titres"
            case ("de", "song"): return "\(count) Songs"
            case ("it", "song"): return "\(count) brani"
            case ("pt", "song"): return "\(count) músicas"
            case ("en", "minute"): return "\(count) minutes"
            case ("es", "minute"): return "\(count) minutos"
            case ("fr", "minute"): return "\(count) minutes"
            case ("de", "minute"): return "\(count) Minuten"
            case ("it", "minute"): return "\(count) minuti"
            case ("pt", "minute"): return "\(count) minutos"
            case ("en", "day"): return "\(count) days"
            case ("es", "day"): return "\(count) días"
            case ("fr", "day"): return "\(count) jours"
            case ("de", "day"): return "\(count) Tage"
            case ("it", "day"): return "\(count) giorni"
            case ("pt", "day"): return "\(count) dias"
            case ("en", "account"): return "\(count) accounts"
            case ("es", "account"): return "\(count) cuentas"
            case ("fr", "account"): return "\(count) comptes"
            case ("de", "account"): return "\(count) Konten"
            case ("it", "account"): return "\(count) account"
            case ("pt", "account"): return "\(count) contas"
            default: return value
            }
        }

        if let c = captures(#"^(\d+) şarkı$"#) { return countWord("song", c[0]) }
        if let c = captures(#"^(\d+) dakika$"#) { return countWord("minute", c[0]) }
        if let c = captures(#"^(\d+) gün$"#) { return countWord("day", c[0]) }
        if let c = captures(#"^(\d+) hesap$"#) { return countWord("account", c[0]) }
        if let c = captures(#"^(\d+) şarkı · (.+)$"#) {
            return countWord("song", c[0]) + " · " + c[1]
        }
        if let c = captures(#"^(\d+)/\s*(\d+) şarkı eşleştiriliyor…$"#) {
            switch language {
            case "es": return "Emparejando \(c[0]) de \(c[1]) canciones…"
            case "fr": return "Association de \(c[0]) sur \(c[1]) titres…"
            case "de": return "Ordne \(c[0]) von \(c[1]) Songs zu…"
            case "it": return "Abbinamento di \(c[0]) su \(c[1]) brani…"
            case "pt": return "A corresponder \(c[0]) de \(c[1]) músicas…"
            default: return "Matching \(c[0]) of \(c[1]) songs…"
            }
        }
        if let c = captures(#"^(\d+) şarkı eşleştiriliyor…$"#) {
            switch language {
            case "es": return "Emparejando \(c[0]) canciones…"
            case "fr": return "Association de \(c[0]) titres…"
            case "de": return "Ordne \(c[0]) Songs zu…"
            case "it": return "Abbinamento di \(c[0]) brani…"
            case "pt": return "A corresponder \(c[0]) músicas…"
            default: return "Matching \(c[0]) songs…"
            }
        }
        if let c = captures(#"^“(.+)” için sonuç bulunamadı\.$"#) {
            switch language {
            case "es": return "No se encontraron resultados para “\(c[0])”."
            case "fr": return "Aucun résultat pour « \(c[0]) »."
            case "de": return "Keine Ergebnisse für „\(c[0])“."
            case "it": return "Nessun risultato per “\(c[0])”."
            case "pt": return "Não foram encontrados resultados para “\(c[0])”."
            default: return "No results found for “\(c[0])”."
            }
        }
        if let c = captures(#"^“(.+)” ile başlayan bir kullanıcı bulunamadı\.$"#) {
            switch language {
            case "es": return "No se encontró ningún usuario que empiece por “\(c[0])”."
            case "fr": return "Aucun utilisateur commençant par « \(c[0]) » n’a été trouvé."
            case "de": return "Kein Benutzer gefunden, dessen Name mit „\(c[0])“ beginnt."
            case "it": return "Nessun utente trovato il cui nome inizi con “\(c[0])”."
            case "pt": return "Não foi encontrado nenhum utilizador cujo nome comece por “\(c[0])”."
            default: return "No user found beginning with “\(c[0])”."
            }
        }
        if let c = captures(#"^“(.+)” sanatçısının sayfası bulunamadı\.$"#) {
            switch language {
            case "es": return "No se encontró la página del artista “\(c[0])”."
            case "fr": return "La page de l’artiste « \(c[0]) » est introuvable."
            case "de": return "Die Künstlerseite von „\(c[0])“ wurde nicht gefunden."
            case "it": return "La pagina dell’artista “\(c[0])” non è stata trovata."
            case "pt": return "A página do artista “\(c[0])” não foi encontrada."
            default: return "The artist page for “\(c[0])” could not be found."
            }
        }
        if let c = captures(#"^Oturum açıldı: (.+)$"#) {
            switch language {
            case "es": return "Sesión iniciada: \(c[0])"
            case "fr": return "Session ouverte : \(c[0])"
            case "de": return "Angemeldet: \(c[0])"
            case "it": return "Accesso effettuato: \(c[0])"
            case "pt": return "Sessão iniciada: \(c[0])"
            default: return "Signed in: \(c[0])"
            }
        }
        if let c = captures(#"^Hata: (.+)$"#) {
            let prefix: String
            switch language {
            case "es": prefix = "Error: "
            case "fr": prefix = "Erreur : "
            case "de": prefix = "Fehler: "
            case "it": prefix = "Errore: "
            case "pt": prefix = "Erro: "
            default: prefix = "Error: "
            }
            return prefix + c[0]
        }
        if let c = captures(#"^İşlem gerçekleştirilemedi \(kod (.+)\)\.$"#) {
            switch language {
            case "es": return "No se pudo completar la operación (código \(c[0]))."
            case "fr": return "Impossible d’effectuer l’opération (code \(c[0]))."
            case "de": return "Vorgang fehlgeschlagen (Code \(c[0]))."
            case "it": return "Impossibile completare l’operazione (codice \(c[0]))."
            case "pt": return "Não foi possível concluir a operação (código \(c[0]))."
            default: return "The operation failed (code \(c[0]))."
            }
        }
        if let c = captures(#"^(.+) bağlantısı kesildi\.$"#) {
            switch language {
            case "es": return "Se ha desconectado \(c[0])."
            case "fr": return "\(c[0]) a été déconnecté."
            case "de": return "\(c[0]) wurde getrennt."
            case "it": return "\(c[0]) è stato disconnesso."
            case "pt": return "\(c[0]) foi desligado."
            default: return "\(c[0]) disconnected."
            }
        }
        if let c = captures(#"^(.+) hesabına giriş yap$"#) {
            switch language {
            case "es": return "Inicia sesión en \(c[0])"
            case "fr": return "Se connecter à \(c[0])"
            case "de": return "Bei \(c[0]) anmelden"
            case "it": return "Accedi a \(c[0])"
            case "pt": return "Iniciar sessão em \(c[0])"
            default: return "Sign in to \(c[0])"
            }
        }
        if let c = captures(#"^(.+) Bağlantısı$"#) {
            switch language {
            case "es": return "Conexión de \(c[0])"
            case "fr": return "Connexion à \(c[0])"
            case "de": return "\(c[0])-Verbindung"
            case "it": return "Connessione a \(c[0])"
            case "pt": return "Ligação de \(c[0])"
            default: return "\(c[0]) Connection"
            }
        }
        if let c = captures(#"^“(.+)” oluşturuldu$"#) {
            switch language {
            case "es": return "Se ha creado “\(c[0])”"
            case "fr": return "« \(c[0]) » a été créée"
            case "de": return "„\(c[0])“ wurde erstellt"
            case "it": return "“\(c[0])” è stata creata"
            case "pt": return "“\(c[0])” foi criada"
            default: return "“\(c[0])” was created"
            }
        }
        if let c = captures(#"^Bu şarkı zaten “(.+)” listesinde$"#) {
            switch language {
            case "es": return "Esta canción ya está en “\(c[0])”"
            case "fr": return "Ce titre figure déjà dans « \(c[0]) »"
            case "de": return "Dieser Song ist bereits in „\(c[0])“"
            case "it": return "Questo brano è già in “\(c[0])”"
            case "pt": return "Esta música já está em “\(c[0])”"
            default: return "This song is already in “\(c[0])”"
            }
        }
        if let c = captures(#"^Müzik (\d+) dakika sonra duracak$"#) {
            switch language {
            case "es": return "La música se detendrá en \(c[0]) minutos"
            case "fr": return "La musique s’arrêtera dans \(c[0]) minutes"
            case "de": return "Die Musik stoppt in \(c[0]) Minuten"
            case "it": return "La musica si fermerà tra \(c[0]) minuti"
            case "pt": return "A música para dentro de \(c[0]) minutos"
            default: return "Music will stop in \(c[0]) minutes"
            }
        }
        if let c = captures(#"^Açık · %(\d+)%$"#) {
            switch language {
            case "es": return "Activado · %\(c[0])%"
            case "fr": return "Activé · %\(c[0])%"
            case "de": return "Ein · %\(c[0])%"
            case "it": return "Attivo · %\(c[0])%"
            case "pt": return "Ativado · %\(c[0])%"
            default: return "On · %\(c[0])%"
            }
        }
        if let c = captures(#"^Yeni sürüm: (.+) \(derleme (\d+)\)$"#) {
            switch language {
            case "es": return "Nueva versión: \(c[0]) (compilación \(c[1]))"
            case "fr": return "Nouvelle version : \(c[0]) (build \(c[1]))"
            case "de": return "Neue Version: \(c[0]) (Build \(c[1]))"
            case "it": return "Nuova versione: \(c[0]) (build \(c[1]))"
            case "pt": return "Nova versão: \(c[0]) (compilação \(c[1]))"
            default: return "New version: \(c[0]) (build \(c[1]))"
            }
        }
        if let c = captures(#"^(.+) eşitleniyor…$"#) {
            switch language {
            case "es": return "Sincronizando \(c[0])…"
            case "fr": return "Synchronisation de \(c[0])…"
            case "de": return "\(c[0]) wird synchronisiert…"
            case "it": return "Sincronizzazione di \(c[0])…"
            case "pt": return "A sincronizar \(c[0])…"
            default: return "Syncing \(c[0])…"
            }
        }
        if let c = captures(#"^Reverb \(açık\)…$"#) {
            switch language {
            case "es": return "Reverb (activado)…"
            case "fr": return "Réverbération (activée)…"
            case "de": return "Reverb (ein)…"
            case "it": return "Riverbero (attivo)…"
            case "pt": return "Reverberação (ativada)…"
            default: return "Reverb (on)…"
            }
        }
        if let c = captures(#"^Şarkı Sözü Kalınlığı: (.+)…$"#) {
            switch language {
            case "es": return "Grosor de letra: \(c[0])…"
            case "fr": return "Épaisseur des paroles : \(c[0])…"
            case "de": return "Schriftstärke der Songtexte: \(c[0])…"
            case "it": return "Spessore del testo: \(c[0])…"
            case "pt": return "Espessura das letras: \(c[0])…"
            default: return "Lyrics Font Weight: \(c[0])…"
            }
        }
        if let c = captures(#"^Arka plan bulanıklığı: (.+)…$"#) {
            switch language {
            case "es": return "Desenfoque de fondo: \(c[0])…"
            case "fr": return "Flou d’arrière-plan : \(c[0])…"
            case "de": return "Hintergrundunschärfe: \(c[0])…"
            case "it": return "Sfocatura sfondo: \(c[0])…"
            case "pt": return "Desfoque do fundo: \(c[0])…"
            default: return "Background Blur: \(c[0])…"
            }
        }
        if let c = captures(#"^Müzik (\d+) dakika sonra duracak$"#) {
            switch language {
            case "es": return "La música se detendrá en \(c[0]) minutos"
            case "fr": return "La musique s’arrêtera dans \(c[0]) minutes"
            case "de": return "Die Musik stoppt in \(c[0]) Minuten"
            case "it": return "La musica si fermerà tra \(c[0]) minuti"
            case "pt": return "A música para dentro de \(c[0]) minutos"
            default: return "Music will stop in \(c[0]) minutes"
            }
        }
        if let c = captures(#"^(.+) · ayrıntıları görmek ve indirmek için dokunun$"#) {
            switch language {
            case "es": return "\(c[0]) · toca para ver detalles y descargar"
            case "fr": return "\(c[0]) · touchez pour afficher les détails et télécharger"
            case "de": return "\(c[0]) · tippen, um Details zu sehen und herunterzuladen"
            case "it": return "\(c[0]) · tocca per vedere i dettagli e scaricare"
            case "pt": return "\(c[0]) · toque para ver detalhes e transferir"
            default: return "\(c[0]) · tap to view details and download"
            }
        }
        if let c = captures(#"^(.+)\nSHA-256 değeri sürümle eşleşiyor\.\n(.+)$"#) {
            let status: String
            switch language {
            case "es": status = "SHA-256 coincide con la versión."
            case "fr": status = "La somme SHA-256 correspond à la version."
            case "de": status = "SHA-256 stimmt mit der Version überein."
            case "it": status = "SHA-256 corrisponde alla versione."
            case "pt": status = "O SHA-256 corresponde à versão."
            default: status = "SHA-256 matches the release."
            }
            return "\(c[0])\n\(status)\n\(c[1])"
        }
        if let c = captures(#"^“(.+)” çalma listesi silinsin mi\?$"#) {
            switch language {
            case "es": return "¿Eliminar la lista “\(c[0])”?"
            case "fr": return "Supprimer la playlist « \(c[0]) » ?"
            case "de": return "Playlist „\(c[0])“ löschen?"
            case "it": return "Eliminare la playlist “\(c[0])”?"
            case "pt": return "Eliminar a lista “\(c[0])”?"
            default: return "Delete the playlist “\(c[0])”?"
            }
        }
        if let c = captures(#"^(\d+) şarkı indiriliyor \(aynı anda (\d+) şarkı\)…$"#) {
            switch language {
            case "es": return "Descargando \(c[0]) canciones (\(c[1]) a la vez)…"
            case "fr": return "Téléchargement de \(c[0]) titres (\(c[1]) à la fois)…"
            case "de": return "\(c[0]) Songs werden heruntergeladen (\(c[1]) gleichzeitig)…"
            case "it": return "Download di \(c[0]) brani (\(c[1]) alla volta)…"
            case "pt": return "A transferir \(c[0]) músicas (\(c[1]) de cada vez)…"
            default: return "Downloading \(c[0]) songs (\(c[1]) at a time)…"
            }
        }
        if let c = captures(#"^· (\d+) şarkı$"#) {
            return "· \(countWord("song", c[0]))"
        }
        if let c = captures(#"^(\d+) öne çıkan şarkı$"#) {
            switch language {
            case "es": return "\(c[0]) canciones destacadas"
            case "fr": return "\(c[0]) titres à la une"
            case "de": return "\(c[0]) empfohlene Songs"
            case "it": return "\(c[0]) brani in evidenza"
            case "pt": return "\(c[0]) músicas em destaque"
            default: return "\(c[0]) featured songs"
            }
        }
        if let c = captures(#"^· (\d+) bin örnek işlendi$"#) {
            switch language {
            case "es": return "· \(c[0]) mil muestras procesadas"
            case "fr": return "· \(c[0]) mille échantillons traités"
            case "de": return "· \(c[0]) Tausend Samples verarbeitet"
            case "it": return "· \(c[0]) mila campioni elaborati"
            case "pt": return "· \(c[0]) mil amostras processadas"
            default: return "· \(c[0]) thousand samples processed"
            }
        }
        if let c = captures(#"^Mochy iOS (.+) \(derleme (\d+)\) kullanıma hazır\.$"#) {
            switch language {
            case "es": return "Mochy iOS \(c[0]) (compilación \(c[1])) está listo para usar."
            case "fr": return "Mochy iOS \(c[0]) (build \(c[1])) est prêt à l’emploi."
            case "de": return "Mochy iOS \(c[0]) (Build \(c[1])) ist einsatzbereit."
            case "it": return "Mochy iOS \(c[0]) (build \(c[1])) è pronto all’uso."
            case "pt": return "Mochy iOS \(c[0]) (compilação \(c[1])) está pronto para usar."
            default: return "Mochy iOS \(c[0]) (build \(c[1])) is ready to use."
            }
        }
        if let c = captures(#"^Arama hatası:\n([\s\S]+)$"#) {
            switch language {
            case "es": return "Error de búsqueda:\n\(c[0])"
            case "fr": return "Erreur de recherche :\n\(c[0])"
            case "de": return "Suchfehler:\n\(c[0])"
            case "it": return "Errore di ricerca:\n\(c[0])"
            case "pt": return "Erro de pesquisa:\n\(c[0])"
            default: return "Search error:\n\(c[0])"
            }
        }
        if let c = captures(#"^(.+): hiçbir çalma listesi okunamadı \(herkese açık olduğunu ve internet bağlantısını kontrol edin\)\.$"#) {
            switch language {
            case "es": return "No se pudieron leer las listas de reproducción de \(c[0]) (comprueba que sean públicas y que tengas conexión a Internet)."
            case "fr": return "Impossible de lire les playlists de \(c[0]) (vérifiez qu’elles sont publiques et que la connexion Internet fonctionne)."
            case "de": return "Die Playlists von \(c[0]) konnten nicht gelesen werden (bitte Öffentlichkeit und Internetverbindung prüfen)."
            case "it": return "Impossibile leggere le playlist di \(c[0]) (controlla che siano pubbliche e la connessione Internet)."
            case "pt": return "Não foi possível ler as listas de \(c[0]) (verifique se são públicas e se há ligação à Internet)."
            default: return "Could not read \(c[0]) playlists (check that they are public and that you have an internet connection)."
            }
        }
        if let c = captures(#"^(.+): (\d+)/(\d+) şarkı eşleştirildi…$"#) {
            switch language {
            case "es": return "\(c[0]): \(c[1]) de \(c[2]) canciones encontradas…"
            case "fr": return "\(c[0]) : \(c[1]) titres sur \(c[2]) associés…"
            case "de": return "\(c[0]): \(c[1]) von \(c[2]) Songs zugeordnet…"
            case "it": return "\(c[0]): abbinati \(c[1]) brani su \(c[2])…"
            case "pt": return "\(c[0]): \(c[1]) de \(c[2]) músicas correspondidas…"
            default: return "\(c[0]): matched \(c[1]) of \(c[2]) songs…"
            }
        }
        if let c = captures(#"^(.+) eşitlendi: (\d+) çalma listesi, (\d+) şarkı\.$"#) {
            switch language {
            case "es": return "\(c[0]) sincronizado: \(c[1]) listas y \(c[2]) canciones."
            case "fr": return "\(c[0]) synchronisé : \(c[1]) playlists, \(c[2]) titres."
            case "de": return "\(c[0]) synchronisiert: \(c[1]) Playlists, \(c[2]) Songs."
            case "it": return "\(c[0]) sincronizzato: \(c[1]) playlist, \(c[2]) brani."
            case "pt": return "\(c[0]) sincronizado: \(c[1]) listas, \(c[2]) músicas."
            default: return "\(c[0]) synced: \(c[1]) playlists, \(c[2]) songs."
            }
        }
        if let c = captures(#"^Son eşitleme: (.+)$"#) {
            switch language {
            case "es": return "Última sincronización: \(c[0])"
            case "fr": return "Dernière synchronisation : \(c[0])"
            case "de": return "Letzte Synchronisierung: \(c[0])"
            case "it": return "Ultima sincronizzazione: \(c[0])"
            case "pt": return "Última sincronização: \(c[0])"
            default: return "Last sync: \(c[0])"
            }
        }
        if let c = captures(#"^Kalan (\d+) şarkı sonraki eşitlemede eşleştirilecek\.$"#) {
            switch language {
            case "es": return "Las \(c[0]) canciones restantes se buscarán en la próxima sincronización."
            case "fr": return "Les \(c[0]) titres restants seront associés lors de la prochaine synchronisation."
            case "de": return "Die übrigen \(c[0]) Songs werden beim nächsten Abgleich zugeordnet."
            case "it": return "I restanti \(c[0]) brani verranno abbinati alla prossima sincronizzazione."
            case "pt": return "As \(c[0]) músicas restantes serão correspondidas na próxima sincronização."
            default: return "The remaining \(c[0]) songs will be matched during the next sync."
            }
        }
        if let c = captures(#"^Kapanma zamanı: (.+)$"#) {
            switch language {
            case "es": return "Hora de apagado: \(c[0])"
            case "fr": return "Heure d’arrêt : \(c[0])"
            case "de": return "Abschaltzeit: \(c[0])"
            case "it": return "Ora di spegnimento: \(c[0])"
            case "pt": return "Hora de desligamento: \(c[0])"
            default: return "Stop time: \(c[0])"
            }
        }
        if let c = captures(#"^(\d+) dinleme$"#) {
            switch language {
            case "es": return "\(c[0]) reproducciones"
            case "fr": return "\(c[0]) écoutes"
            case "de": return "\(c[0]) Wiedergaben"
            case "it": return "\(c[0]) riproduzioni"
            case "pt": return "\(c[0]) reproduções"
            default: return "\(c[0]) plays"
            }
        }
        if let c = captures(#"^(\d+) kez$"#) {
            switch language {
            case "es": return "\(c[0]) veces"
            case "fr": return "\(c[0]) fois"
            case "de": return "\(c[0]) Mal"
            case "it": return "\(c[0]) volte"
            case "pt": return "\(c[0]) vezes"
            default: return "\(c[0]) times"
            }
        }
        if let c = captures(#"^(\d+) dinleme · (\d+) şarkı · (\d+) sanatçı$"#) {
            switch language {
            case "es": return "\(c[0]) reproducciones · \(c[1]) canciones · \(c[2]) artistas"
            case "fr": return "\(c[0]) écoutes · \(c[1]) titres · \(c[2]) artistes"
            case "de": return "\(c[0]) Wiedergaben · \(c[1]) Songs · \(c[2]) Künstler"
            case "it": return "\(c[0]) riproduzioni · \(c[1]) brani · \(c[2]) artisti"
            case "pt": return "\(c[0]) reproduções · \(c[1]) músicas · \(c[2]) artistas"
            default: return "\(c[0]) plays · \(c[1]) songs · \(c[2]) artists"
            }
        }
        if let c = captures(#"^Arşive (\d+) yeni öğe eklendi\.$"#) {
            switch language {
            case "es": return "Se añadieron \(c[0]) elementos nuevos al archivo."
            case "fr": return "\(c[0]) nouveaux éléments ont été ajoutés à l’archive."
            case "de": return "\(c[0]) neue Elemente wurden zum Archiv hinzugefügt."
            case "it": return "Aggiunti \(c[0]) nuovi elementi all’archivio."
            case "pt": return "Foram adicionados \(c[0]) novos itens ao arquivo."
            default: return "Added \(c[0]) new items to the archive."
            }
        }
        if let c = captures(#"^Geçersiz yanıt: ([\s\S]+)$"#) {
            switch language {
            case "es": return "Respuesta no válida: \(c[0])"
            case "fr": return "Réponse invalide : \(c[0])"
            case "de": return "Ungültige Antwort: \(c[0])"
            case "it": return "Risposta non valida: \(c[0])"
            case "pt": return "Resposta inválida: \(c[0])"
            default: return "Invalid response: \(c[0])"
            }
        }
        if let c = captures(#"^Dosya kaydedilemedi: (.+)$"#) {
            let prefix: String
            switch language {
            case "es": prefix = "No se pudo guardar el archivo: "
            case "fr": prefix = "Impossible d’enregistrer le fichier : "
            case "de": prefix = "Datei konnte nicht gespeichert werden: "
            case "it": prefix = "Impossibile salvare il file: "
            case "pt": prefix = "Não foi possível guardar o ficheiro: "
            default: prefix = "Could not save file: "
            }
            return prefix + c[0]
        }
        if let c = captures(#"^Sunucu HTTP (\d+) yanıtı? verdi\.?$"#) {
            switch language {
            case "es": return "El servidor respondió con HTTP \(c[0])."
            case "fr": return "Le serveur a répondu HTTP \(c[0])."
            case "de": return "Der Server antwortete mit HTTP \(c[0])."
            case "it": return "Il server ha risposto con HTTP \(c[0])."
            case "pt": return "O servidor respondeu com HTTP \(c[0])."
            default: return "Server returned HTTP \(c[0])."
            }
        }
        if let c = captures(#"^İndirilen dosya eksik \((\d+) / (\d+) bayt\)\. Yeniden indirmeyi deneyin\.$"#) {
            switch language {
            case "es": return "El archivo descargado está incompleto (\(c[0]) / \(c[1]) bytes). Intenta descargarlo de nuevo."
            case "fr": return "Le fichier téléchargé est incomplet (\(c[0]) / \(c[1]) octets). Réessayez le téléchargement."
            case "de": return "Die heruntergeladene Datei ist unvollständig (\(c[0]) / \(c[1]) Bytes). Bitte erneut herunterladen."
            case "it": return "Il file scaricato è incompleto (\(c[0]) / \(c[1]) byte). Prova a scaricarlo di nuovo."
            case "pt": return "O ficheiro transferido está incompleto (\(c[0]) / \(c[1]) bytes). Tente transferi-lo novamente."
            default: return "The downloaded file is incomplete (\(c[0]) / \(c[1]) bytes). Try downloading it again."
            }
        }
        if let c = captures(#"^“(.+)” listesine eklendi$"#) {
            switch language {
            case "es": return "Añadida a la lista “\(c[0])”"
            case "fr": return "Ajouté à la playlist « \(c[0]) »"
            case "de": return "Zu „\(c[0])“ hinzugefügt"
            case "it": return "Aggiunto a “\(c[0])”"
            case "pt": return "Adicionada a “\(c[0])”"
            default: return "Added to “\(c[0])”"
            }
        }
        if let c = captures(#"^Tamamlandı: “(.+)” çalma listesine (\d+) şarkı eklendi \(kaynak: (.+)\)\.$"#) {
            switch language {
            case "es": return "Completado: se añadieron \(c[1]) canciones a “\(c[0])” (fuente: \(c[2]))."
            case "fr": return "Terminé : \(c[1]) titres ajoutés à « \(c[0]) » (source : \(c[2]))."
            case "de": return "Abgeschlossen: \(c[1]) Songs zu „\(c[0])“ hinzugefügt (Quelle: \(c[2]))."
            case "it": return "Completato: aggiunti \(c[1]) brani a “\(c[0])” (fonte: \(c[2]))."
            case "pt": return "Concluído: \(c[1]) músicas adicionadas a “\(c[0])” (origem: \(c[2]))."
            default: return "Complete: added \(c[1]) songs to “\(c[0])” (source: \(c[2]))."
            }
        }
        if let c = captures(#"^\n(\d+) şarkı eşleştirilemedi\.$"#) {
            switch language {
            case "es": return "\nNo se pudieron encontrar \(c[0]) canciones."
            case "fr": return "\n\(c[0]) titres n’ont pas pu être associés."
            case "de": return "\n\(c[0]) Songs konnten nicht zugeordnet werden."
            case "it": return "\nImpossibile abbinare \(c[0]) brani."
            case "pt": return "\nNão foi possível encontrar correspondência para \(c[0]) músicas."
            default: return "\nCould not match \(c[0]) songs."
            }
        }
        if let c = captures(#"^“(.+)” çalma listesi arşivden silinecek\. Bu işlem geri alınamaz\.$"#) {
            switch language {
            case "es": return "La lista “\(c[0])” se eliminará del archivo. Esta acción no se puede deshacer."
            case "fr": return "La playlist « \(c[0]) » sera supprimée de l’archive. Cette action est irréversible."
            case "de": return "Die Playlist „\(c[0])“ wird aus dem Archiv gelöscht. Dieser Vorgang kann nicht rückgängig gemacht werden."
            case "it": return "La playlist “\(c[0])” verrà eliminata dall’archivio. Questa operazione è irreversibile."
            case "pt": return "A lista “\(c[0])” será removida do arquivo. Esta ação não pode ser desfeita."
            default: return "The playlist “\(c[0])” will be removed from the archive. This cannot be undone."
            }
        }
        if let c = captures(#"^Sürüm (.+) \(derleme (\d+)\)$"#) {
            switch language {
            case "es": return "Versión \(c[0]) (compilación \(c[1]))"
            case "fr": return "Version \(c[0]) (build \(c[1]))"
            case "de": return "Version \(c[0]) (Build \(c[1]))"
            case "it": return "Versione \(c[0]) (build \(c[1]))"
            case "pt": return "Versão \(c[0]) (compilação \(c[1]))"
            default: return "Version \(c[0]) (build \(c[1]))"
            }
        }
        if let c = captures(#"^Denetlenemedi: (.+)$"#) {
            switch language {
            case "es": return "No se pudo comprobar: \(c[0])"
            case "fr": return "Vérification impossible : \(c[0])"
            case "de": return "Prüfung fehlgeschlagen: \(c[0])"
            case "it": return "Impossibile verificare: \(c[0])"
            case "pt": return "Não foi possível verificar: \(c[0])"
            default: return "Could not check: \(c[0])"
            }
        }
        if let c = captures(#"^Yeni sürüm mevcut: (.+) \(derleme (\d+)\)$"#) {
            switch language {
            case "es": return "Nueva versión disponible: \(c[0]) (compilación \(c[1]))"
            case "fr": return "Nouvelle version disponible : \(c[0]) (build \(c[1]))"
            case "de": return "Neue Version verfügbar: \(c[0]) (Build \(c[1]))"
            case "it": return "Nuova versione disponibile: \(c[0]) (build \(c[1]))"
            case "pt": return "Nova versão disponível: \(c[0]) (compilação \(c[1]))"
            default: return "New version available: \(c[0]) (build \(c[1]))"
            }
        }
        if let c = captures(#"^İmza indirilemedi: (.+)$"#) {
            let prefix: String
            switch language {
            case "es": prefix = "No se pudo descargar la firma: "
            case "fr": prefix = "Impossible de télécharger la signature : "
            case "de": prefix = "Signatur konnte nicht heruntergeladen werden: "
            case "it": prefix = "Impossibile scaricare la firma: "
            case "pt": prefix = "Não foi possível transferir a assinatura: "
            default: prefix = "Could not download signature: "
            }
            return prefix + c[0]
        }
        if let c = captures(#"^Etkin \((\d+) Hz, (\d+) kanal\)$"#) {
            switch language {
            case "es": return "Activo (\(c[0]) Hz, \(c[1]) canales)"
            case "fr": return "Activé (\(c[0]) Hz, \(c[1]) canaux)"
            case "de": return "Aktiv (\(c[0]) Hz, \(c[1]) Kanäle)"
            case "it": return "Attivo (\(c[0]) Hz, \(c[1]) canali)"
            case "pt": return "Ativo (\(c[0]) Hz, \(c[1]) canais)"
            default: return "Active (\(c[0]) Hz, \(c[1]) channels)"
            }
        }
        if let c = captures(#"^Uygulanamadı: (\d+)-bit ses biçimi desteklenmiyor$"#) {
            switch language {
            case "es": return "No se pudo aplicar: el formato de audio de \(c[0]) bits no es compatible."
            case "fr": return "Impossible d’appliquer : le format audio \(c[0]) bits n’est pas pris en charge."
            case "de": return "Nicht anwendbar: Das \(c[0])-Bit-Audioformat wird nicht unterstützt."
            case "it": return "Impossibile applicare: il formato audio a \(c[0]) bit non è supportato."
            case "pt": return "Não foi possível aplicar: o formato de áudio de \(c[0]) bits não é suportado."
            default: return "Could not apply: the \(c[0])-bit audio format is unsupported."
            }
        }
        if let c = captures(#"^Uygulanamadı: (\d+) kanal$"#) {
            switch language {
            case "es": return "No se pudo aplicar: \(c[0]) canales."
            case "fr": return "Impossible d’appliquer : \(c[0]) canaux."
            case "de": return "Nicht anwendbar: \(c[0]) Kanäle."
            case "it": return "Impossibile applicare: \(c[0]) canali."
            case "pt": return "Não foi possível aplicar: \(c[0]) canais."
            default: return "Could not apply: \(c[0]) channels."
            }
        }
        if let c = captures(#"^Filtre oluşturulamadı \(kod (.+)\)$"#) {
            switch language {
            case "es": return "No se pudo crear el filtro (código \(c[0]))"
            case "fr": return "Impossible de créer le filtre (code \(c[0]))"
            case "de": return "Filter konnte nicht erstellt werden (Code \(c[0]))"
            case "it": return "Impossibile creare il filtro (codice \(c[0]))"
            case "pt": return "Não foi possível criar o filtro (código \(c[0]))"
            default: return "Could not create filter (code \(c[0]))"
            }
        }
        if let c = captures(#"^Bu sayfada oturum açın \(zaten giriş yaptıysanız (.+) ana sayfasını bir kez açın\), ardından yeniden Bitti’ye dokunun\.$"#) {
            switch language {
            case "es": return "Inicia sesión en esta página (si ya has iniciado sesión, abre una vez la página principal de \(c[0])) y vuelve a tocar Hecho."
            case "fr": return "Connectez-vous sur cette page (si vous l’êtes déjà, ouvrez une fois la page d’accueil de \(c[0])), puis touchez à nouveau Terminé."
            case "de": return "Melde dich auf dieser Seite an (wenn du bereits angemeldet bist, öffne einmal die Startseite von \(c[0])) und tippe erneut auf Fertig."
            case "it": return "Accedi a questa pagina (se hai già effettuato l’accesso, apri una volta la home di \(c[0])) e tocca di nuovo Fine."
            case "pt": return "Inicie sessão nesta página (se já tiver sessão iniciada, abra uma vez a página inicial de \(c[0])) e toque novamente em Concluído."
            default: return "Sign in on this page (if you are already signed in, open the \(c[0]) home page once), then tap Done again."
            }
        }
        if let c = captures(#"^(.+) · (\d+) şarkı$"#) {
            switch language {
            case "es": return "\(c[0]) · \(c[1]) canciones"
            case "fr": return "\(c[0]) · \(c[1]) titres"
            case "de": return "\(c[0]) · \(c[1]) Songs"
            case "it": return "\(c[0]) · \(c[1]) brani"
            case "pt": return "\(c[0]) · \(c[1]) músicas"
            default: return "\(c[0]) · \(c[1]) songs"
            }
        }
        if let c = captures(#"^(.+) sunucusu HTTP (\d+) yanıtı verdi\n([\s\S]*)$"#) {
            switch language {
            case "es": return "Servidor \(c[0]) respondió con HTTP \(c[1])\n\(c[2])"
            case "fr": return "Le serveur \(c[0]) a répondu HTTP \(c[1])\n\(c[2])"
            case "de": return "Server \(c[0]) antwortete mit HTTP \(c[1])\n\(c[2])"
            case "it": return "Il server \(c[0]) ha risposto con HTTP \(c[1])\n\(c[2])"
            case "pt": return "O servidor \(c[0]) respondeu com HTTP \(c[1])\n\(c[2])"
            default: return "Server \(c[0]) returned HTTP \(c[1])\n\(c[2])"
            }
        }
        if let c = captures(#"^(.+) sunucusu HTTP (\d+) yanıtı verdi$"#) {
            switch language {
            case "es": return "El servidor \(c[0]) respondió con HTTP \(c[1])."
            case "fr": return "Le serveur \(c[0]) a répondu HTTP \(c[1])."
            case "de": return "Server \(c[0]) antwortete mit HTTP \(c[1])."
            case "it": return "Il server \(c[0]) ha risposto con HTTP \(c[1])."
            case "pt": return "O servidor \(c[0]) respondeu com HTTP \(c[1])."
            default: return "Server \(c[0]) returned HTTP \(c[1])."
            }
        }
        if let c = captures(#"^Dosya boyutu eşleşmiyor \(alınan (.+), beklenen (.+)\)$"#) {
            switch language {
            case "es": return "El tamaño del archivo no coincide (recibido \(c[0]), esperado \(c[1]))"
            case "fr": return "La taille du fichier ne correspond pas (reçu : \(c[0]), attendu : \(c[1]))"
            case "de": return "Dateigröße stimmt nicht überein (erhalten: \(c[0]), erwartet: \(c[1]))"
            case "it": return "La dimensione del file non corrisponde (ricevuta \(c[0]), prevista \(c[1]))"
            case "pt": return "O tamanho do ficheiro não corresponde (recebido \(c[0]), esperado: \(c[1]))"
            default: return "File size mismatch (received \(c[0]), expected \(c[1]))"
            }
        }
        if let c = captures(#"^(\d+) satırla eşzamanlandı$"#) {
            switch language {
            case "es": return "Sincronizado con \(c[0]) líneas"
            case "fr": return "Synchronisé avec \(c[0]) lignes"
            case "de": return "Mit \(c[0]) Zeilen synchronisiert"
            case "it": return "Sincronizzato con \(c[0]) righe"
            case "pt": return "Sincronizado com \(c[0]) linhas"
            default: return "Synced with \(c[0]) lines"
            }
        }
        if let c = captures(#"^• (.+): bağlantı yarıda kesildi$"#) {
            switch language {
            case "es": return "• \(c[0]): conexión interrumpida"
            case "fr": return "• \(c[0]) : connexion interrompue"
            case "de": return "• \(c[0]): Verbindung unterbrochen"
            case "it": return "• \(c[0]): connessione interrotta"
            case "pt": return "• \(c[0]): ligação interrompida"
            default: return "• \(c[0]): connection interrupted"
            }
        }
        if let c = captures(#"^“(.+)” çalma listesi arşivden silinecek\. Beğenilen ve indirilen şarkılar korunacak\.( Eşitlenen bu çalma listesi yeniden oluşturulmayacak\.)? Bu işlem geri alınamaz\.$"#) {
            let extra: String
            if c[1].isEmpty { extra = "" }
            else {
                switch language {
                case "es": extra = " La lista sincronizada no se volverá a crear."
                case "fr": extra = " Cette playlist synchronisée ne sera pas recréée."
                case "de": extra = " Diese synchronisierte Playlist wird nicht erneut erstellt."
                case "it": extra = " Questa playlist sincronizzata non verrà ricreata."
                case "pt": extra = " Esta lista sincronizada não será recriada."
                default: extra = " This synced playlist will not be recreated."
                }
            }
            switch language {
            case "es": return "La lista “\(c[0])” se eliminará del archivo. Las canciones favoritas y descargadas se conservarán.\(extra) Esta acción no se puede deshacer."
            case "fr": return "La playlist « \(c[0]) » sera supprimée de l’archive. Les titres aimés et téléchargés seront conservés.\(extra) Cette action est irréversible."
            case "de": return "Die Playlist „\(c[0])“ wird aus dem Archiv gelöscht. Favorisierte und heruntergeladene Songs bleiben erhalten.\(extra) Dieser Vorgang kann nicht rückgängig gemacht werden."
            case "it": return "La playlist “\(c[0])” verrà eliminata dall’archivio. I brani preferiti e scaricati verranno conservati.\(extra) Questa operazione è irreversibile."
            case "pt": return "A lista “\(c[0])” será removida do arquivo. As músicas favoritas e transferidas serão mantidas.\(extra) Esta ação não pode ser desfeita."
            default: return "The playlist “\(c[0])” will be removed from the archive. Liked and downloaded songs will be kept.\(extra) This cannot be undone."
            }
        }
        if let c = captures(#"^İndirmeden önce verileriniz otomatik olarak yedeklenir\. \.ipa dosyasını imzalarken Bundle ID’yi \((.+)\) değiştirmeyin ve verileri korumak için eski sürümün üzerine yükleyin\.$"#) {
            switch language {
            case "es": return "Tus datos se respaldarán automáticamente antes de descargar. No cambies el Bundle ID (\(c[0])) al firmar el archivo .ipa e instala sobre la versión anterior para conservar los datos."
            case "fr": return "Vos données seront sauvegardées automatiquement avant le téléchargement. Ne modifiez pas le Bundle ID (\(c[0])) lors de la signature du fichier .ipa et installez par-dessus l’ancienne version pour conserver vos données."
            case "de": return "Deine Daten werden vor dem Download automatisch gesichert. Ändere die Bundle-ID (\(c[0]) beim Signieren der .ipa-Datei nicht und installiere über die vorherige Version, um Daten zu behalten."
            case "it": return "I dati verranno salvati automaticamente prima del download. Non modificare il Bundle ID (\(c[0])) quando firmi il file .ipa e installa sopra la versione precedente per conservare i dati."
            case "pt": return "Os dados serão guardados automaticamente antes da transferência. Não altere o Bundle ID (\(c[0])) ao assinar o ficheiro .ipa e instale sobre a versão anterior para manter os dados."
            default: return "Your data will be backed up automatically before downloading. Do not change the Bundle ID (\(c[0])) when signing the .ipa file, and install over the previous version to preserve your data."
            }
        }
        return nil
    }

    static func localizedRegionName(_ code: String) -> String {
        let locale = Locale(identifier: YouTubeMusicLocale.languageCode)
        return locale.localizedString(forRegionCode: code) ?? code
    }

    private static let translations: [String: [String: String]] = [

        "en": [
            "Ana Sayfa": "Home",
            "Ara": "Search",
            "Kütüphane": "Library",
            "Ayarlar": "Settings",
            "Dil ve Bölge": "Language & Region",
            "Dil": "Language",
            "Bölge": "Region",
            "Cihaz dili": "Device language",
            "Otomatik": "Automatic",
            "Görünüm": "Appearance",
            "Arayüz": "Interface",
            "Görünüm modu": "Appearance mode",
            "Ses": "Audio",
            "Kalite": "Quality",
            "Özellikler": "Features",
            "Depolama": "Storage",
            "Veriler": "Data",
            "Yazılım güncellemesi": "Software update",
            "Derleme bilgileri": "Build information",
            "Hakkında": "About",
            "İptal": "Cancel",
            "Kaydet": "Save",
            "İndirilen şarkılar": "Downloaded songs",
            "İndirilen tüm şarkıları sil": "Delete all downloads",
            "Dinleme geçmişini sil": "Clear listening history",
            "Şimdi yedekle…": "Back up now…",
            "Yedek dosyasından geri yükle…": "Restore from backup…",
            "Güncellemeleri otomatik denetle": "Check for updates automatically",
            "Güncellemeleri şimdi denetle": "Check for updates now",
            "En yüksek": "Highest",
            "Veri tasarrufu": "Data saver",
            "Çalma sırasında arka plan videosu (varsa)": "Video background during playback (if available)",
            "Müzik hesapları (çalma listesi eşitleme)": "Music accounts (playlist sync)",
            "Bağlı değil": "Not connected",
            "Mochy hesabı": "Mochy account",
            "Geçerli sürüm": "Current version",
            "Güncelleme kanalı": "Update channel",
            "Oturum açılmadı": "Not signed in",
            "Uygulama dili": "App language",
            "YouTube Music bölgesi": "YouTube Music region",
            "Cihaz bölgesi (Otomatik)": "Device region (Automatic)",
            "Bu değişiklik arayüz dilini ve YouTube Music istek dilini birlikte değiştirir.": "This changes the interface language and YouTube Music request language together.",
            "Ülke/bölge YouTube Music listelerini ve önerilerini etkiler. Konum izni kullanılmaz.": "The country/region affects YouTube Music charts and recommendations. Location permission is not used.",
            "Uygulama dilinin tamamının uygulanması için Mochy yeniden açılır.": "Reopen Mochy to apply the selected interface language.",
        ],
        "es": [
            "Ana Sayfa": "Inicio",
            "Ara": "Buscar",
            "Kütüphane": "Biblioteca",
            "Ayarlar": "Ajustes",
            "Dil ve Bölge": "Idioma y región",
            "Dil": "Idioma",
            "Bölge": "Región",
            "Cihaz dili": "Idioma del dispositivo",
            "Otomatik": "Automático",
            "Görünüm": "Apariencia",
            "Arayüz": "Interfaz",
            "Görünüm modu": "Modo de apariencia",
            "Ses": "Audio",
            "Kalite": "Calidad",
            "Özellikler": "Funciones",
            "Depolama": "Almacenamiento",
            "Veriler": "Datos",
            "Yazılım güncellemesi": "Actualización de software",
            "Derleme bilgileri": "Información de compilación",
            "Hakkında": "Acerca de",
            "İptal": "Cancelar",
            "Kaydet": "Guardar",
            "İndirilen şarkılar": "Canciones descargadas",
            "İndirilen tüm şarkıları sil": "Eliminar todas las descargas",
            "Dinleme geçmişini sil": "Borrar historial de escucha",
            "Şimdi yedekle…": "Crear copia ahora…",
            "Yedek dosyasından geri yükle…": "Restaurar copia…",
            "Güncellemeleri otomatik denetle": "Buscar actualizaciones automáticamente",
            "Güncellemeleri şimdi denetle": "Buscar actualizaciones ahora",
            "En yüksek": "Máxima",
            "Veri tasarrufu": "Ahorro de datos",
            "Çalma sırasında arka plan videosu (varsa)": "Vídeo de fondo durante la reproducción",
            "Müzik hesapları (çalma listesi eşitleme)": "Cuentas de música (sincronización)",
            "Bağlı değil": "Desconectado",
            "Mochy hesabı": "Cuenta de Mochy",
            "Geçerli sürüm": "Versión actual",
            "Güncelleme kanalı": "Canal de actualización",
            "Oturum açılmadı": "No has iniciado sesión",
            "Uygulama dili": "Idioma de la aplicación",
            "YouTube Music bölgesi": "Región de YouTube Music",
            "Cihaz bölgesi (Otomatik)": "Región del dispositivo (automática)",
            "Bu değişiklik arayüz dilini ve YouTube Music istek dilini birlikte değiştirir.": "Esto cambia el idioma de la interfaz y de las solicitudes de YouTube Music.",
            "Ülke/bölge YouTube Music listelerini ve önerilerini etkiler. Konum izni kullanılmaz.": "El país o región afecta a las listas y recomendaciones de YouTube Music. No se usa la ubicación.",
            "Uygulama dilinin tamamının uygulanması için Mochy yeniden açılır.": "Reabre Mochy para aplicar el idioma de la interfaz.",
        ],
        "fr": [
            "Ana Sayfa": "Accueil",
            "Ara": "Rechercher",
            "Kütüphane": "Bibliothèque",
            "Ayarlar": "Réglages",
            "Dil ve Bölge": "Langue et région",
            "Dil": "Langue",
            "Bölge": "Région",
            "Cihaz dili": "Langue de l’appareil",
            "Otomatik": "Automatique",
            "Görünüm": "Apparence",
            "Arayüz": "Interface",
            "Görünüm modu": "Mode d’apparence",
            "Ses": "Audio",
            "Kalite": "Qualité",
            "Özellikler": "Fonctionnalités",
            "Depolama": "Stockage",
            "Veriler": "Données",
            "Yazılım güncellemesi": "Mise à jour logicielle",
            "Derleme bilgileri": "Informations de compilation",
            "Hakkında": "À propos",
            "İptal": "Annuler",
            "Kaydet": "Enregistrer",
            "İndirilen şarkılar": "Titres téléchargés",
            "İndirilen tüm şarkıları sil": "Supprimer tous les téléchargements",
            "Dinleme geçmişini sil": "Effacer l’historique d’écoute",
            "Şimdi yedekle…": "Sauvegarder maintenant…",
            "Yedek dosyasından geri yükle…": "Restaurer une sauvegarde…",
            "Güncellemeleri otomatik denetle": "Rechercher automatiquement les mises à jour",
            "Güncellemeleri şimdi denetle": "Rechercher les mises à jour",
            "En yüksek": "Maximum",
            "Veri tasarrufu": "Économie de données",
            "Çalma sırasında arka plan videosu (varsa)": "Vidéo d’arrière-plan pendant la lecture",
            "Müzik hesapları (çalma listesi eşitleme)": "Comptes musicaux (synchronisation)",
            "Bağlı değil": "Non connecté",
            "Mochy hesabı": "Compte Mochy",
            "Geçerli sürüm": "Version actuelle",
            "Güncelleme kanalı": "Canal de mise à jour",
            "Oturum açılmadı": "Non connecté",
            "Uygulama dili": "Langue de l’application",
            "YouTube Music bölgesi": "Région YouTube Music",
            "Cihaz bölgesi (Otomatik)": "Région de l’appareil (automatique)",
            "Bu değişiklik arayüz dilini ve YouTube Music istek dilini birlikte değiştirir.": "Cela modifie la langue de l’interface et des requêtes YouTube Music.",
            "Ülke/bölge YouTube Music listelerini ve önerilerini etkiler. Konum izni kullanılmaz.": "Le pays ou la région influence les classements et recommandations YouTube Music. Aucune autorisation de localisation.",
            "Uygulama dilinin tamamının uygulanması için Mochy yeniden açılır.": "Rouvrez Mochy pour appliquer la langue de l’interface.",
        ],
        "de": [
            "Ana Sayfa": "Startseite",
            "Ara": "Suchen",
            "Kütüphane": "Mediathek",
            "Ayarlar": "Einstellungen",
            "Dil ve Bölge": "Sprache & Region",
            "Dil": "Sprache",
            "Bölge": "Region",
            "Cihaz dili": "Gerätesprache",
            "Otomatik": "Automatisch",
            "Görünüm": "Darstellung",
            "Arayüz": "Oberfläche",
            "Görünüm modu": "Darstellungsmodus",
            "Ses": "Audio",
            "Kalite": "Qualität",
            "Özellikler": "Funktionen",
            "Depolama": "Speicher",
            "Veriler": "Daten",
            "Yazılım güncellemesi": "Softwareupdate",
            "Derleme bilgileri": "Build-Informationen",
            "Hakkında": "Über",
            "İptal": "Abbrechen",
            "Kaydet": "Sichern",
            "İndirilen şarkılar": "Heruntergeladene Titel",
            "İndirilen tüm şarkıları sil": "Alle Downloads löschen",
            "Dinleme geçmişini sil": "Wiedergabeverlauf löschen",
            "Şimdi yedekle…": "Jetzt sichern…",
            "Yedek dosyasından geri yükle…": "Aus Backup wiederherstellen…",
            "Güncellemeleri otomatik denetle": "Automatisch nach Updates suchen",
            "Güncellemeleri şimdi denetle": "Jetzt nach Updates suchen",
            "En yüksek": "Höchste",
            "Veri tasarrufu": "Datensparmodus",
            "Çalma sırasında arka plan videosu (varsa)": "Hintergrundvideo während der Wiedergabe",
            "Müzik hesapları (çalma listesi eşitleme)": "Musikkonten (Playlist-Synchronisierung)",
            "Bağlı değil": "Nicht verbunden",
            "Mochy hesabı": "Mochy-Konto",
            "Geçerli sürüm": "Aktuelle Version",
            "Güncelleme kanalı": "Update-Kanal",
            "Oturum açılmadı": "Nicht angemeldet",
            "Uygulama dili": "App-Sprache",
            "YouTube Music bölgesi": "YouTube-Music-Region",
            "Cihaz bölgesi (Otomatik)": "Geräteregion (automatisch)",
            "Bu değişiklik arayüz dilini ve YouTube Music istek dilini birlikte değiştirir.": "Dies ändert die Oberflächensprache und die Sprache der YouTube-Music-Anfragen.",
            "Ülke/bölge YouTube Music listelerini ve önerilerini etkiler. Konum izni kullanılmaz.": "Land/Region beeinflusst YouTube-Music-Charts und Empfehlungen. Es wird kein Standortzugriff verwendet.",
            "Uygulama dilinin tamamının uygulanması için Mochy yeniden açılır.": "Mochy neu öffnen, um die Oberflächensprache anzuwenden.",
        ],
        "pt": [
            "Ana Sayfa": "Início",
            "Ara": "Pesquisar",
            "Kütüphane": "Biblioteca",
            "Ayarlar": "Definições",
            "Dil ve Bölge": "Idioma e região",
            "Dil": "Idioma",
            "Bölge": "Região",
            "Cihaz dili": "Idioma do dispositivo",
            "Otomatik": "Automático",
            "Görünüm": "Aspeto",
            "Arayüz": "Interface",
            "Görünüm modu": "Modo de apresentação",
            "Ses": "Áudio",
            "Kalite": "Qualidade",
            "Özellikler": "Funcionalidades",
            "Depolama": "Armazenamento",
            "Veriler": "Dados",
            "Yazılım güncellemesi": "Atualização de software",
            "Derleme bilgileri": "Informações da compilação",
            "Hakkında": "Sobre",
            "İptal": "Cancelar",
            "Kaydet": "Guardar",
            "İndirilen şarkılar": "Músicas transferidas",
            "İndirilen tüm şarkıları sil": "Apagar todas as transferências",
            "Dinleme geçmişini sil": "Limpar histórico de reprodução",
            "Şimdi yedekle…": "Criar cópia agora…",
            "Yedek dosyasından geri yükle…": "Restaurar cópia…",
            "Güncellemeleri otomatik denetle": "Procurar atualizações automaticamente",
            "Güncellemeleri şimdi denetle": "Procurar atualizações agora",
            "En yüksek": "Máxima",
            "Veri tasarrufu": "Poupança de dados",
            "Çalma sırasında arka plan videosu (varsa)": "Vídeo de fundo durante a reprodução",
            "Müzik hesapları (çalma listesi eşitleme)": "Contas de música (sincronização)",
            "Bağlı değil": "Não ligado",
            "Mochy hesabı": "Conta Mochy",
            "Geçerli sürüm": "Versão atual",
            "Güncelleme kanalı": "Canal de atualização",
            "Oturum açılmadı": "Sessão não iniciada",
            "Uygulama dili": "Idioma da aplicação",
            "YouTube Music bölgesi": "Região do YouTube Music",
            "Cihaz bölgesi (Otomatik)": "Região do dispositivo (automática)",
            "Bu değişiklik arayüz dilini ve YouTube Music istek dilini birlikte değiştirir.": "Isto altera o idioma da interface e dos pedidos do YouTube Music.",
            "Ülke/bölge YouTube Music listelerini ve önerilerini etkiler. Konum izni kullanılmaz.": "O país/região afeta as tabelas e recomendações do YouTube Music. Não é usada a localização.",
            "Uygulama dilinin tamamının uygulanması için Mochy yeniden açılır.": "Reabra o Mochy para aplicar o idioma da interface.",
        ],
        "it": [
            "Ana Sayfa": "Home",
            "Ara": "Cerca",
            "Kütüphane": "Libreria",
            "Ayarlar": "Impostazioni",
            "Dil ve Bölge": "Lingua e regione",
            "Dil": "Lingua",
            "Bölge": "Regione",
            "Cihaz dili": "Lingua del dispositivo",
            "Otomatik": "Automatico",
            "Görünüm": "Aspetto",
            "Arayüz": "Interfaccia",
            "Görünüm modu": "Modalità aspetto",
            "Ses": "Audio",
            "Kalite": "Qualità",
            "Özellikler": "Funzioni",
            "Depolama": "Archiviazione",
            "Veriler": "Dati",
            "Yazılım güncellemesi": "Aggiornamento software",
            "Derleme bilgileri": "Informazioni build",
            "Hakkında": "Informazioni",
            "İptal": "Annulla",
            "Kaydet": "Salva",
            "İndirilen şarkılar": "Brani scaricati",
            "İndirilen tüm şarkıları sil": "Elimina tutti i download",
            "Dinleme geçmişini sil": "Cancella cronologia ascolti",
            "Şimdi yedekle…": "Esegui backup…",
            "Yedek dosyasından geri yükle…": "Ripristina backup…",
            "Güncellemeleri otomatik denetle": "Controlla automaticamente gli aggiornamenti",
            "Güncellemeleri şimdi denetle": "Controlla aggiornamenti",
            "En yüksek": "Massima",
            "Veri tasarrufu": "Risparmio dati",
            "Çalma sırasında arka plan videosu (varsa)": "Video di sfondo durante la riproduzione",
            "Müzik hesapları (çalma listesi eşitleme)": "Account musicali (sincronizzazione playlist)",
            "Bağlı değil": "Non connesso",
            "Mochy hesabı": "Account Mochy",
            "Geçerli sürüm": "Versione attuale",
            "Güncelleme kanalı": "Canale aggiornamenti",
            "Oturum açılmadı": "Non hai effettuato l’accesso",
            "Uygulama dili": "Lingua dell’app",
            "YouTube Music bölgesi": "Regione YouTube Music",
            "Cihaz bölgesi (Otomatik)": "Regione dispositivo (automatica)",
            "Bu değişiklik arayüz dilini ve YouTube Music istek dilini birlikte değiştirir.": "Modifica la lingua dell’interfaccia e delle richieste YouTube Music.",
            "Ülke/bölge YouTube Music listelerini ve önerilerini etkiler. Konum izni kullanılmaz.": "Il paese/regione influisce su classifiche e consigli di YouTube Music. Non viene usata la posizione.",
            "Uygulama dilinin tamamının uygulanması için Mochy yeniden açılır.": "Riapri Mochy per applicare la lingua dell’interfaccia.",
        ],
        "vi": [
            "Ana Sayfa": "Trang chủ",
            "Ara": "Tìm kiếm",
            "Kütüphane": "Thư viện",
            "Ayarlar": "Cài đặt",
            "Dil ve Bölge": "Ngôn ngữ & Khu vực",
            "Dil": "Ngôn ngữ",
            "Bölge": "Khu vực",
            "Cihaz dili": "Ngôn ngữ thiết bị",
            "Otomatik": "Tự động",
            "Görünüm": "Giao diện",
            "Arayüz": "Giao diện",
            "Görünüm modu": "Chế độ giao diện",
            "Ses": "Âm thanh",
            "Kalite": "Chất lượng",
            "Özellikler": "Tính năng",
            "Depolama": "Bộ nhớ",
            "Veriler": "Dữ liệu",
            "Yazılım güncellemesi": "Cập nhật phần mềm",
            "Derleme bilgileri": "Thông tin bản dựng",
            "Hakkında": "Giới thiệu",
            "İptal": "Hủy",
            "Kaydet": "Lưu",
            "İndirilen şarkılar": "Bài hát đã tải",
            "İndirilen tüm şarkıları sil": "Xóa tất cả bài hát đã tải",
            "Dinleme geçmişini sil": "Xóa lịch sử nghe",
            "Şimdi yedekle…": "Sao lưu ngay…",
            "Yedek dosyasından geri yükle…": "Khôi phục từ bản sao lưu…",
            "Güncellemeleri otomatik denetle": "Tự động kiểm tra cập nhật",
            "Güncellemeleri şimdi denetle": "Kiểm tra cập nhật ngay",
            "En yüksek": "Cao nhất",
            "Veri tasarrufu": "Tiết kiệm dữ liệu",
            "Çalma sırasında arka plan videosu (varsa)": "Video nền khi phát nhạc",
            "Müzik hesapları (çalma listesi eşitleme)": "Tài khoản nhạc (đồng bộ danh sách phát)",
            "Bağlı değil": "Chưa kết nối",
            "Mochy hesabı": "Tài khoản Mochy",
            "Geçerli sürüm": "Phiên bản hiện tại",
            "Güncelleme kanalı": "Kênh cập nhật",
            "Oturum açılmadı": "Chưa đăng nhập",
            "Uygulama dili": "Ngôn ngữ ứng dụng",
            "YouTube Music bölgesi": "Khu vực YouTube Music",
            "Cihaz bölgesi (Otomatik)": "Khu vực thiết bị (tự động)",
            "Bu değişiklik arayüz dilini ve YouTube Music istek dilini birlikte değiştirir.": "Thay đổi này áp dụng đồng thời cho ngôn ngữ giao diện và yêu cầu YouTube Music.",
            "Ülke/bölge YouTube Music listelerini ve önerilerini etkiler. Konum izni kullanılmaz.": "Quốc gia/khu vực ảnh hưởng đến bảng xếp hạng và đề xuất YouTube Music. Không dùng quyền vị trí.",
            "Uygulama dilinin tamamının uygulanması için Mochy yeniden açılır.": "Mở lại Mochy để áp dụng ngôn ngữ giao diện.",
        ],
        "ja": [
            "Ana Sayfa": "ホーム",
            "Ara": "検索",
            "Kütüphane": "ライブラリ",
            "Ayarlar": "設定",
            "Dil ve Bölge": "言語と地域",
            "Dil": "言語",
            "Bölge": "地域",
            "Cihaz dili": "デバイスの言語",
            "Otomatik": "自動",
            "Görünüm": "外観",
            "Arayüz": "インターフェース",
            "Görünüm modu": "外観モード",
            "Ses": "オーディオ",
            "Kalite": "音質",
            "Özellikler": "機能",
            "Depolama": "ストレージ",
            "Veriler": "データ",
            "Yazılım güncellemesi": "ソフトウェアアップデート",
            "Derleme bilgileri": "ビルド情報",
            "Hakkında": "情報",
            "İptal": "キャンセル",
            "Kaydet": "保存",
            "İndirilen şarkılar": "ダウンロード済みの曲",
            "İndirilen tüm şarkıları sil": "すべてのダウンロードを削除",
            "Dinleme geçmişini sil": "再生履歴を消去",
            "Şimdi yedekle…": "今すぐバックアップ…",
            "Yedek dosyasından geri yükle…": "バックアップから復元…",
            "Güncellemeleri otomatik denetle": "アップデートを自動確認",
            "Güncellemeleri şimdi denetle": "アップデートを確認",
            "En yüksek": "最高",
            "Veri tasarrufu": "データ節約",
            "Çalma sırasında arka plan videosu (varsa)": "再生中の背景動画",
            "Müzik hesapları (çalma listesi eşitleme)": "音楽アカウント（プレイリスト同期）",
            "Bağlı değil": "未接続",
            "Mochy hesabı": "Mochyアカウント",
            "Geçerli sürüm": "現在のバージョン",
            "Güncelleme kanalı": "アップデートチャンネル",
            "Oturum açılmadı": "未ログイン",
            "Uygulama dili": "アプリの言語",
            "YouTube Music bölgesi": "YouTube Musicの地域",
            "Cihaz bölgesi (Otomatik)": "デバイスの地域（自動）",
            "Bu değişiklik arayüz dilini ve YouTube Music istek dilini birlikte değiştirir.": "アプリの表示言語とYouTube Musicのリクエスト言語を同時に変更します。",
            "Ülke/bölge YouTube Music listelerini ve önerilerini etkiler. Konum izni kullanılmaz.": "国/地域はYouTube Musicのチャートとおすすめに影響します。位置情報の許可は不要です。",
            "Uygulama dilinin tamamının uygulanması için Mochy yeniden açılır.": "表示言語を適用するにはMochyを再起動してください。",
        ],
        "ko": [
            "Ana Sayfa": "홈",
            "Ara": "검색",
            "Kütüphane": "라이브러리",
            "Ayarlar": "설정",
            "Dil ve Bölge": "언어 및 지역",
            "Dil": "언어",
            "Bölge": "지역",
            "Cihaz dili": "기기 언어",
            "Otomatik": "자동",
            "Görünüm": "모양",
            "Arayüz": "인터페이스",
            "Görünüm modu": "모양 모드",
            "Ses": "오디오",
            "Kalite": "품질",
            "Özellikler": "기능",
            "Depolama": "저장 공간",
            "Veriler": "데이터",
            "Yazılım güncellemesi": "소프트웨어 업데이트",
            "Derleme bilgileri": "빌드 정보",
            "Hakkında": "정보",
            "İptal": "취소",
            "Kaydet": "저장",
            "İndirilen şarkılar": "다운로드한 노래",
            "İndirilen tüm şarkıları sil": "모든 다운로드 삭제",
            "Dinleme geçmişini sil": "청취 기록 지우기",
            "Şimdi yedekle…": "지금 백업…",
            "Yedek dosyasından geri yükle…": "백업에서 복원…",
            "Güncellemeleri otomatik denetle": "업데이트 자동 확인",
            "Güncellemeleri şimdi denetle": "업데이트 확인",
            "En yüksek": "최고",
            "Veri tasarrufu": "데이터 절약",
            "Çalma sırasında arka plan videosu (varsa)": "재생 중 배경 동영상",
            "Müzik hesapları (çalma listesi eşitleme)": "음악 계정(재생목록 동기화)",
            "Bağlı değil": "연결 안 됨",
            "Mochy hesabı": "Mochy 계정",
            "Geçerli sürüm": "현재 버전",
            "Güncelleme kanalı": "업데이트 채널",
            "Oturum açılmadı": "로그인되지 않음",
            "Uygulama dili": "앱 언어",
            "YouTube Music bölgesi": "YouTube Music 지역",
            "Cihaz bölgesi (Otomatik)": "기기 지역(자동)",
            "Bu değişiklik arayüz dilini ve YouTube Music istek dilini birlikte değiştirir.": "앱 인터페이스와 YouTube Music 요청 언어를 함께 변경합니다.",
            "Ülke/bölge YouTube Music listelerini ve önerilerini etkiler. Konum izni kullanılmaz.": "국가/지역은 YouTube Music 차트와 추천에 영향을 줍니다. 위치 권한은 사용하지 않습니다.",
            "Uygulama dilinin tamamının uygulanması için Mochy yeniden açılır.": "인터페이스 언어를 적용하려면 Mochy를 다시 여세요.",
        ],
        "ar": [
            "Ana Sayfa": "الرئيسية",
            "Ara": "بحث",
            "Kütüphane": "المكتبة",
            "Ayarlar": "الإعدادات",
            "Dil ve Bölge": "اللغة والمنطقة",
            "Dil": "اللغة",
            "Bölge": "المنطقة",
            "Cihaz dili": "لغة الجهاز",
            "Otomatik": "تلقائي",
            "Görünüm": "المظهر",
            "Arayüz": "الواجهة",
            "Görünüm modu": "وضع المظهر",
            "Ses": "الصوت",
            "Kalite": "الجودة",
            "Özellikler": "الميزات",
            "Depolama": "التخزين",
            "Veriler": "البيانات",
            "Yazılım güncellemesi": "تحديث البرنامج",
            "Derleme bilgileri": "معلومات الإصدار",
            "Hakkında": "حول",
            "İptal": "إلغاء",
            "Kaydet": "حفظ",
            "İndirilen şarkılar": "الأغاني التي تم تنزيلها",
            "İndirilen tüm şarkıları sil": "حذف جميع التنزيلات",
            "Dinleme geçmişini sil": "مسح سجل الاستماع",
            "Şimdi yedekle…": "نسخ احتياطي الآن…",
            "Yedek dosyasından geri yükle…": "استعادة من نسخة احتياطية…",
            "Güncellemeleri otomatik denetle": "التحقق تلقائيًا من التحديثات",
            "Güncellemeleri şimdi denetle": "التحقق من التحديثات الآن",
            "En yüksek": "الأعلى",
            "Veri tasarrufu": "توفير البيانات",
            "Çalma sırasında arka plan videosu (varsa)": "فيديو الخلفية أثناء التشغيل",
            "Müzik hesapları (çalma listesi eşitleme)": "حسابات الموسيقى (مزامنة قوائم التشغيل)",
            "Bağlı değil": "غير متصل",
            "Mochy hesabı": "حساب Mochy",
            "Geçerli sürüm": "الإصدار الحالي",
            "Güncelleme kanalı": "قناة التحديث",
            "Oturum açılmadı": "لم يتم تسجيل الدخول",
            "Uygulama dili": "لغة التطبيق",
            "YouTube Music bölgesi": "منطقة YouTube Music",
            "Cihaz bölgesi (Otomatik)": "منطقة الجهاز (تلقائي)",
            "Bu değişiklik arayüz dilini ve YouTube Music istek dilini birlikte değiştirir.": "يغيّر هذا لغة الواجهة ولغة طلبات YouTube Music معًا.",
            "Ülke/bölge YouTube Music listelerini ve önerilerini etkiler. Konum izni kullanılmaz.": "تؤثر الدولة/المنطقة في قوائم YouTube Music وتوصياته. لا يُستخدم إذن الموقع.",
            "Uygulama dilinin tamamının uygulanması için Mochy yeniden açılır.": "أعد فتح Mochy لتطبيق لغة الواجهة.",
        ],
        "hi": [
            "Ana Sayfa": "होम",
            "Ara": "खोजें",
            "Kütüphane": "लाइब्रेरी",
            "Ayarlar": "सेटिंग्स",
            "Dil ve Bölge": "भाषा और क्षेत्र",
            "Dil": "भाषा",
            "Bölge": "क्षेत्र",
            "Cihaz dili": "डिवाइस की भाषा",
            "Otomatik": "स्वचालित",
            "Görünüm": "रूप",
            "Arayüz": "इंटरफ़ेस",
            "Görünüm modu": "रूप मोड",
            "Ses": "ऑडियो",
            "Kalite": "गुणवत्ता",
            "Özellikler": "सुविधाएँ",
            "Depolama": "स्टोरेज",
            "Veriler": "डेटा",
            "Yazılım güncellemesi": "सॉफ़्टवेयर अपडेट",
            "Derleme bilgileri": "बिल्ड जानकारी",
            "Hakkında": "जानकारी",
            "İptal": "रद्द करें",
            "Kaydet": "सहेजें",
            "İndirilen şarkılar": "डाउनलोड किए गए गाने",
            "İndirilen tüm şarkıları sil": "सभी डाउनलोड हटाएँ",
            "Dinleme geçmişini sil": "सुनने का इतिहास मिटाएँ",
            "Şimdi yedekle…": "अभी बैकअप लें…",
            "Yedek dosyasından geri yükle…": "बैकअप से पुनर्स्थापित करें…",
            "Güncellemeleri otomatik denetle": "अपडेट अपने आप जाँचें",
            "Güncellemeleri şimdi denetle": "अपडेट अभी जाँचें",
            "En yüksek": "सबसे अधिक",
            "Veri tasarrufu": "डेटा बचत",
            "Çalma sırasında arka plan videosu (varsa)": "प्लेबैक के दौरान बैकग्राउंड वीडियो",
            "Müzik hesapları (çalma listesi eşitleme)": "म्यूज़िक खाते (प्लेलिस्ट सिंक)",
            "Bağlı değil": "कनेक्ट नहीं है",
            "Mochy hesabı": "Mochy खाता",
            "Geçerli sürüm": "वर्तमान संस्करण",
            "Güncelleme kanalı": "अपडेट चैनल",
            "Oturum açılmadı": "साइन इन नहीं है",
            "Uygulama dili": "ऐप की भाषा",
            "YouTube Music bölgesi": "YouTube Music क्षेत्र",
            "Cihaz bölgesi (Otomatik)": "डिवाइस क्षेत्र (स्वचालित)",
            "Bu değişiklik arayüz dilini ve YouTube Music istek dilini birlikte değiştirir.": "यह इंटरफ़ेस और YouTube Music अनुरोधों की भाषा एक साथ बदलता है।",
            "Ülke/bölge YouTube Music listelerini ve önerilerini etkiler. Konum izni kullanılmaz.": "देश/क्षेत्र YouTube Music चार्ट और सुझावों को प्रभावित करता है। लोकेशन अनुमति का उपयोग नहीं होता।",
            "Uygulama dilinin tamamının uygulanması için Mochy yeniden açılır.": "इंटरफ़ेस भाषा लागू करने के लिए Mochy फिर खोलें।",
        ],
        "id": [
            "Ana Sayfa": "Beranda",
            "Ara": "Cari",
            "Kütüphane": "Koleksi",
            "Ayarlar": "Pengaturan",
            "Dil ve Bölge": "Bahasa & Wilayah",
            "Dil": "Bahasa",
            "Bölge": "Wilayah",
            "Cihaz dili": "Bahasa perangkat",
            "Otomatik": "Otomatis",
            "Görünüm": "Tampilan",
            "Arayüz": "Antarmuka",
            "Görünüm modu": "Mode tampilan",
            "Ses": "Audio",
            "Kalite": "Kualitas",
            "Özellikler": "Fitur",
            "Depolama": "Penyimpanan",
            "Veriler": "Data",
            "Yazılım güncellemesi": "Pembaruan perangkat lunak",
            "Derleme bilgileri": "Informasi build",
            "Hakkında": "Tentang",
            "İptal": "Batal",
            "Kaydet": "Simpan",
            "İndirilen şarkılar": "Lagu yang diunduh",
            "İndirilen tüm şarkıları sil": "Hapus semua unduhan",
            "Dinleme geçmişini sil": "Hapus riwayat dengar",
            "Şimdi yedekle…": "Cadangkan sekarang…",
            "Yedek dosyasından geri yükle…": "Pulihkan dari cadangan…",
            "Güncellemeleri otomatik denetle": "Periksa pembaruan otomatis",
            "Güncellemeleri şimdi denetle": "Periksa pembaruan sekarang",
            "En yüksek": "Tertinggi",
            "Veri tasarrufu": "Hemat data",
            "Çalma sırasında arka plan videosu (varsa)": "Video latar saat memutar",
            "Müzik hesapları (çalma listesi eşitleme)": "Akun musik (sinkronisasi playlist)",
            "Bağlı değil": "Tidak terhubung",
            "Mochy hesabı": "Akun Mochy",
            "Geçerli sürüm": "Versi saat ini",
            "Güncelleme kanalı": "Saluran pembaruan",
            "Oturum açılmadı": "Belum masuk",
            "Uygulama dili": "Bahasa aplikasi",
            "YouTube Music bölgesi": "Wilayah YouTube Music",
            "Cihaz bölgesi (Otomatik)": "Wilayah perangkat (otomatis)",
            "Bu değişiklik arayüz dilini ve YouTube Music istek dilini birlikte değiştirir.": "Ini mengubah bahasa antarmuka dan permintaan YouTube Music sekaligus.",
            "Ülke/bölge YouTube Music listelerini ve önerilerini etkiler. Konum izni kullanılmaz.": "Negara/wilayah memengaruhi tangga lagu dan rekomendasi YouTube Music. Izin lokasi tidak digunakan.",
            "Uygulama dilinin tamamının uygulanması için Mochy yeniden açılır.": "Buka ulang Mochy untuk menerapkan bahasa antarmuka.",
        ],
        "zh-Hans": [
            "Ana Sayfa": "首页",
            "Ara": "搜索",
            "Kütüphane": "资料库",
            "Ayarlar": "设置",
            "Dil ve Bölge": "语言与地区",
            "Dil": "语言",
            "Bölge": "地区",
            "Cihaz dili": "设备语言",
            "Otomatik": "自动",
            "Görünüm": "外观",
            "Arayüz": "界面",
            "Görünüm modu": "外观模式",
            "Ses": "音频",
            "Kalite": "音质",
            "Özellikler": "功能",
            "Depolama": "存储",
            "Veriler": "数据",
            "Yazılım güncellemesi": "软件更新",
            "Derleme bilgileri": "构建信息",
            "Hakkında": "关于",
            "İptal": "取消",
            "Kaydet": "保存",
            "İndirilen şarkılar": "已下载歌曲",
            "İndirilen tüm şarkıları sil": "删除所有下载",
            "Dinleme geçmişini sil": "清除收听记录",
            "Şimdi yedekle…": "立即备份…",
            "Yedek dosyasından geri yükle…": "从备份恢复…",
            "Güncellemeleri otomatik denetle": "自动检查更新",
            "Güncellemeleri şimdi denetle": "立即检查更新",
            "En yüksek": "最高",
            "Veri tasarrufu": "节省流量",
            "Çalma sırasında arka plan videosu (varsa)": "播放时显示背景视频",
            "Müzik hesapları (çalma listesi eşitleme)": "音乐账号（播放列表同步）",
            "Bağlı değil": "未连接",
            "Mochy hesabı": "Mochy 账号",
            "Geçerli sürüm": "当前版本",
            "Güncelleme kanalı": "更新渠道",
            "Oturum açılmadı": "未登录",
            "Uygulama dili": "应用语言",
            "YouTube Music bölgesi": "YouTube Music 地区",
            "Cihaz bölgesi (Otomatik)": "设备地区（自动）",
            "Bu değişiklik arayüz dilini ve YouTube Music istek dilini birlikte değiştirir.": "此设置会同时更改界面语言和 YouTube Music 请求语言。",
            "Ülke/bölge YouTube Music listelerini ve önerilerini etkiler. Konum izni kullanılmaz.": "国家/地区会影响 YouTube Music 榜单和推荐。不会使用位置权限。",
            "Uygulama dilinin tamamının uygulanması için Mochy yeniden açılır.": "重新打开 Mochy 以应用界面语言。",
        ],
    ]


    private static let supplemental: [String: [String: String]] = [
        "en": ["Açık": "Light", "Koyu": "Dark", "Kararlı": "Stable", "Geliştirici": "Developer", "Sil": "Delete", "Kapat": "Close", "Oturum açılmadı": "Not signed in"],
        "es": ["Açık": "Claro", "Koyu": "Oscuro", "Kararlı": "Estable", "Geliştirici": "Desarrollador", "Sil": "Eliminar", "Kapat": "Cerrar", "Oturum açılmadı": "No has iniciado sesión"],
        "fr": ["Açık": "Clair", "Koyu": "Sombre", "Kararlı": "Stable", "Geliştirici": "Développeur", "Sil": "Supprimer", "Kapat": "Fermer", "Oturum açılmadı": "Non connecté"],
        "de": ["Açık": "Hell", "Koyu": "Dunkel", "Kararlı": "Stabil", "Geliştirici": "Entwickler", "Sil": "Löschen", "Kapat": "Schließen", "Oturum açılmadı": "Nicht angemeldet"],
        "pt": ["Açık": "Claro", "Koyu": "Escuro", "Kararlı": "Estável", "Geliştirici": "Programador", "Sil": "Apagar", "Kapat": "Fechar", "Oturum açılmadı": "Sessão não iniciada"],
        "it": ["Açık": "Chiaro", "Koyu": "Scuro", "Kararlı": "Stabile", "Geliştirici": "Sviluppatore", "Sil": "Elimina", "Kapat": "Chiudi", "Oturum açılmadı": "Non hai effettuato l’accesso"],
        "vi": ["Açık": "Sáng", "Koyu": "Tối", "Kararlı": "Ổn định", "Geliştirici": "Nhà phát triển", "Sil": "Xóa", "Kapat": "Đóng", "Oturum açılmadı": "Chưa đăng nhập"],
        "ja": ["Açık": "ライト", "Koyu": "ダーク", "Kararlı": "安定版", "Geliştirici": "開発者", "Sil": "削除", "Kapat": "閉じる", "Oturum açılmadı": "未ログイン"],
        "ko": ["Açık": "라이트", "Koyu": "다크", "Kararlı": "안정 버전", "Geliştirici": "개발자", "Sil": "삭제", "Kapat": "닫기", "Oturum açılmadı": "로그인되지 않음"],
        "ar": ["Açık": "فاتح", "Koyu": "داكن", "Kararlı": "مستقر", "Geliştirici": "للمطورين", "Sil": "حذف", "Kapat": "إغلاق", "Oturum açılmadı": "لم يتم تسجيل الدخول"],
        "hi": ["Açık": "लाइट", "Koyu": "डार्क", "Kararlı": "स्थिर", "Geliştirici": "डेवलपर", "Sil": "हटाएँ", "Kapat": "बंद करें", "Oturum açılmadı": "साइन इन नहीं है"],
        "id": ["Açık": "Terang", "Koyu": "Gelap", "Kararlı": "Stabil", "Geliştirici": "Pengembang", "Sil": "Hapus", "Kapat": "Tutup", "Oturum açılmadı": "Belum masuk"],
        "zh-Hans": ["Açık": "浅色", "Koyu": "深色", "Kararlı": "稳定版", "Geliştirici": "开发者", "Sil": "删除", "Kapat": "关闭", "Oturum açılmadı": "未登录"]
    ]

    private static let actionOnly: [String: [String: String]] = [
        "en": ["Çal": "Play"],
        "es": ["Çal": "Reproducir"],
        "fr": ["Çal": "Lire"],
        "de": ["Çal": "Abspielen"],
        "pt": ["Çal": "Reproduzir"],
        "it": ["Çal": "Riproduci"],
        "vi": ["Çal": "Phát"],
        "ja": ["Çal": "再生"],
        "ko": ["Çal": "재생"],
        "ar": ["Çal": "تشغيل"],
        "hi": ["Çal": "चलाएँ"],
        "id": ["Çal": "Putar"],
        "zh-Hans": ["Çal": "播放"]
    ]
}
