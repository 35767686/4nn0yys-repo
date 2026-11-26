# Mochy iOS — Build 75

Bu kaynak paketi Build 74 üzerine ana sayfa önerilerini genişletir.

## Ana sayfa bölümleri

- YouTube Music ana akışından kişiselleştirilmiş öneri rafları (`FEmusic_home`)
- Seçilen ülke/bölge için YouTube Music listeleri (`FEmusic_charts`)
- Seçilen dilde yeni müzik araması
- Kullanıcının yerel dinleme geçmişindeki sanatçılara göre "Bunu dinlediğiniz için" rafları
- Son dinlenen şarkılar

Öneriler dil/bölge başına ayrı önbelleğe alınır. Dil veya bölge değiştiğinde mevcut locale bildirimi önbelleği sıfırlar ve akışı yeniden yükler.

## Derleme

Windows üzerinde kaynakları GitHub deposunun ana dizinine kopyalayın, commit ve push yapın. GitHub Actions macOS üzerinde `.deb` ve `.ipa` üretir. Bu ZIP içinde önceden derlenmiş iOS paketi bulunmaz.


## Sileo package metadata (Build 76)

- Package display name: `Translated Mochy iOS`
- Package description: `A localized iOS music player with YouTube Music browsing, streaming, background playback, and language and region preferences.`
- Debian package control metadata is defined in `deb/DEBIAN/control` and is embedded in every built `.deb`.
