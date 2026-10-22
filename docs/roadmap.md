# X-OS Yol Haritası

Sürüm adayları Debian Stable döngüsüne bağlanır; hedef her aşamada
`make lint && make test` + yeşil CI.

## v0.1 "İskele" — şu an

- [x] Token hattı (JSON → QML/CSS, CI drift koruması)
- [x] Liquid Glass malzemesi (`GlassSurface`) + bileşen seti
- [x] Shell yüzeyleri: TopBar, Dock (büyüme efektli), Launcher (arama +
      sticker düzenleme), ControlCenter, NotificationCenter, LockScreen
- [x] C++ çekirdek: `xos.api` / `xos.apps` / `xos.system` / `xos.settings`
- [x] X-Defender D-Bus köprüsü (opsiyonel, yoksa gizli)
- [x] live-build ISO altyapısı + `xos-session` + SDDM
- [x] CI: lint + test + Qt6 derleme (Debian trixie container)
- [ ] ISO pipeline CI'da actual artifact olarak dönüyor *(bir sonraki adım)*

## v0.2 "Masaüstü"

- [ ] Masaüstü ikonları (`.desktop` sürükle-bırak, ızgara snap)
- [ ] KWin scripti: aktif pencere adı, tam ekran takibi
- [ ] Duvar kâğıdı seçici (jetonlanmış: aurora / ember / light / görsel)
- [ ] Sticker paleti genişlemesi (yazı sticker'ı, saatin sticker'ı)
- [ ] Bildirim daemon köprüsü (`org.freedesktop.Notifications` sahiplenme)
- [ ] Tema geçişi animasyonlu (metin/arka plan lerp)

## v0.3 "Kurulum"

- [ ] Calamares kurulum programı (X-OS bölümü, kullanıcı, gruplar)
- [ ] `live-build` bootstrap köprüsü → GitHub Actions artifact ISO
- [ ] İlk boot sihirbazı (dil, klavye, kullanıcı, güncelleme denetimi)
- [ ] OTA güncelleme denetleyicisi (apt + xos-release kanalları)

## v0.4 "Sağlam ses"

- [ ] Ekran kilidi için `pam_xos` (demo → gerçek PAM)
- [ ] PipeWire ses mikseri paneli (cihaz seçici, uygulama akışları)
- [ ] Ağaç: Wi-Fi seçici NM köprüsü (şimdilik etiket var)
- [ ] Erişilebilirlik geçişi: okuma sırası, kontrast çifti, hareket azaltma

## v0.5 "Vitrin"

- [ ] KWin Liquid Glass efekt plugin'i (pencere bulanıklığı, köşe kırılması)
- [ ] Animasyon kütüphanesi: spring easing yardımcıları, sekme geçişleri
- [ ] Uygulama vitrini: X-Defender entegrasyonu (tehdit bildirimleri)
- [ ] Performans: shader bütçesi, 60/120 Hz ölçüm süiti

## Açık kaynak / topluluk

- [ ] CONTRIBUTING.md (lint/test kapısı, token kuralları)
- [ ] Issue şablonları (bug / tasarım / ISO)
- [ ] İlk dış katkıcı denemesi: `design/preview` üzerinden tasarım incelemesi
