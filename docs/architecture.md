# X-OS Mimari

## 1. Katmanlar

```
┌─────────────────────────────────────────────────────────────┐
│ 4. Uygulamalar        Qt6 / GTK4 / Firefox / X-Defender …  │
├─────────────────────────────────────────────────────────────┤
│ 3. PlasmaX shell      QML yüzeyler + C++ servis köprüleri   │
│     plasmex           (tek pencere: wallpaper→panels)       │
├─────────────────────────────────────────────────────────────┤
│ 2. Compositor         KWin (kwin_wayland, XWayland dahil)   │
├─────────────────────────────────────────────────────────────┤
│ 1. Temel              Debian 13 trixie (systemd, sddm,      │
│                       NetworkManager, PipeWire, fwupd)     │
└─────────────────────────────────────────────────────────────┘
```

**Karar: KWin + kendi QML shell'imiz.**
Sebepleri: Debian stable'da tam paketli olması, olgun efekt/bulanıklaştırma
altyapısı, XWayland köprüsü ve hazır oturum/ekran kilidi ekosistemi. Kendi
compositor'umuzu sıfırdan yazmak yerine yüzeye (shell) yatırım yapıyoruz —
kullanıcıya görünen şey orası.

## 2. plasmex (shell) süreç modeli

`xos-session` (display manager tarafından başlatılır):

1. `kwin_wayland --xwayland` — compositor (plasmashell **çalışmaz**;
   panel/dock/launcher görevlerini plasmex üstlenir).
2. `plasmex` — Qt Quick tek penceresi:
   - **Wallpaper** — ShaderEffectSource ile arka plan; cam yüzeyler bunu
     bulanıklaştırıp kırar (pencere dışı yakalama yok).
   - **DesktopLayer + StickerLayer** — masaüstü ikonları (v0.2) ve JSON
     kalıcı çıkartmalar.
   - **Paneller** — TopBar, Dock, Launcher, ControlCenter, NotificationCenter,
     LockScreen; hepsi `GlassSurface` malzemesi üzerinde.
3. PipeWire/WirePlumber (ses) — varsa.

Tek pencere yaklaşımı bilinçli: cam efekti kendi sahnemizi referans aldığı
için hem daha ucuz hem de compositor'un arka plan yakalama iznine bağlı değil.
Gelecekte paneller `LayerShellQt` ile ayrı layer-shell pencerelerine
taşınabilir (kod zaten `XOS_WITH_LAYERSHELL` ile derlenir).

## 3. C++ ↔ QML kontratı (context properties)

| Nesne | Kaynak | Rol |
|---|---|---|
| `xos.api` | `XosApi` | tema modu, oturum komutları (kilit/uyku/kapama), pencere durumu, imleç parallax'ı |
| `xos.apps` | `DesktopApps` | `.desktop` modeli, başlatma, sticker ekleme |
| `xos.system` | `SystemStatus` | CPU/RAM, ağ, batarya, parlaklık, ses (2 sn /sys//proc taraması) |
| `xos.settings` | `SettingsStore` | sticker/list, duvar kâğıdı, ölçek (QSettings) |
| `xos.defender` | `XDefenderClient` | opsiyonel D-Bus köprüsü (`io.xos.XDefender`); yoksa sessizce gizlenir |

## 4. Tasarım token hattı

`design/tokens/xos.tokens.json` → `tools/gen-tokens.py` →
`shell/qml/PlasmaX/Theme.qml` + `design/generated/tokens.css`.

QML hiçbir yerde sabit renk/ölçü tutmaz; `Theme.*` üzerinden okur. CI
`--check` ile drift'i reddeder. Yeni bir token önce JSON'a eklenir, sonra
`make tokens`.

## 5. Liquid Glass malzemesi (`GlassSurface.qml`)

Sıra (içten dışa):

1. `ShaderEffectSource` — wallpaper'ın bu yüzeydeki bölgesi (1/3 çözünürlükte)
2. `MultiEffect` — down-sampled gaussian blur + doygunluk artışı
3. tint — cam tonu (dark/light token)
4. rim — 1 px ışık halkası (sol-üst daha parlak → ana ışık yönü)
5. sheen — üst üçte birde spekülar gradyan
6. shadow — `elevation` token'ından düşme gölgesi
7. köşe refraksiyon dilimi (tam lens pass'ın ekonomik yerine geçici okuması)

Derleme zamanı opsiyonel: LayerShellQt/ShaderTools bulunmazsa bileşenler
`compact`/`backdrop: null` moduna düşerek çalışır.

## 6. Oturum & ISO

- `system/live-build/` — live-build config; `make iso` → `system/build-iso.sh`.
- `includes.chroot/usr/share/wayland-sessions/plasmax.desktop` → `xos-session`.
- Paket listeleri: `config/package-lists/xos.list.chroot`.
- Kurulum hedefi (v0.2): calamares entegrasyonu.

## 7. Güvenlik duruşu (v0.1)

- Ekran kilidi akışı **demo**: PAM entegrasyonu yok (milestone: "Secure lock").
  `XosApi::tryUnlock` yalnızca doluluk kontrolü yapar — üretim öncesi
  `pam_xos` modülüyle değiştirilecek.
- `xos-session` root değil, display manager'ın oturum kullanıcısıyla çalışır.
- Tüm oturum komutları `loginctl`/`systemctl` üzerinden; shell içinde
  ayrıcalık yükseltme yok.

## 8. Genişletme noktaları

- **X-Defender**: D-Bus servisi `io.xos.XDefender` sunarsa ControlCenter kartı
  otomatik görünür (`integrations/x-defender/README.md`).
- **Diğer kendi uygulamaları**: aynı desen — D-Bus kontratı `integrations/`,
  kabuk tarafı opsiyonel köprü.
- **Masaüstü ikonları**: `DesktopLayer` zaten hazır, `.desktop` modeli
  `xos.apps` üzerinde (milestone v0.2).
- **KWin scripti**: aktif pencere adı/estate takibi için KWin D-Bus scripti
  (milestone v0.2; şimdilik oturum adı fallback).
