# X-OS

**X-OS**, Debian Stable (13 "trixie") tabanlı, kendi **PlasmaX** arayüzüne sahip
yeni nesil bir işletim sistemi projesidir. Yüzde yüz kendi tasarım dilimiz,
kendi ikon setimiz ve açık kaynak lisanslı (GPLv3) bir kod tabanı üzerine kurulur.

> **Liquid Glass** — arayüzün her yüzeyi, optik olarak inandırıcı bir "sıvı
> cam" malzemesinden oluşur: arkadaki duvar kâğıdını bulanıklaştırır, kenar
> ışığı kırar, ince bir spekülar parlaklık taşır. Bu malzeme patentli/özel bir
> buluş değil; doğru uygulandığında güzel duran, sektörde yaygın bir tekniktir.
> X-OS onu tamamen kendi token'ları, kendi shader'ları ve kendi QML bileşen
> setiyle uygular.

## Bileşenler

| Dizin | Ne? |
|---|---|
| `shell/` | **PlasmaX** — Qt6/QML tabanlı Wayland shell'i (TopBar, Dock, Launcher, ControlCenter, LockScreen, Sticker katmanı) + C++ çekirdek servisleri |
| `design/` | Tasarım token'ları (tek doğruluk kaynağı), ikon seti, logo, üretilen CSS |
| `system/` | live-build tabanlı ISO pipeline'ı, oturum dosyaları, marka varlıkları |
| `integrations/` | Harici uygulama kontratları (D-Bus) — örn. X-Defender |
| `tools/` | Token üretici, QML lint, test çalıştırıcı |
| `packaging/` | Debian paketleme iskeleti |
| `docs/` | Mimari, yol haritası, tasarım rehberi |

## Hızlı başlangıç

```bash
# Gereksinimler: cmake ≥ 3.22, Qt 6.4+ (base, declarative, wayland, dbus),
#                 C++17 derleyici, python3
make lint        # token senkronizasyonu + QML yapısal lint
make build       # cmake + derleme → build/plasmex
make test        # tüm test paketi

./build/plasmex --demo             # demo verilerle shell'i başlat
./build/plasmex --preview 1600x900 # sabit boyutlu tasarım önizlemesi
```

ISO üretimi (Debian/Ubuntu üzerinde, `sudo` gerektirir):

```bash
make iso          # → system/build-iso.sh (live-build ile X-OS live image)
```

## Tasarım token'ları

Renk, cam malzemesi, radius, tipografi ve hareket tanımlarının tamamı
`design/tokens/xos.tokens.json` içinde yaşar. Her şey oradan üretilir:

```bash
make tokens   # Theme.qml + tokens.css üretir
```

CI, token dosyası ile üretilen çıktılar arasındaki herhangi bir kaymayı
**hata** olarak yakalar (`make check-tokens`). QML'de sihirli sayı yoktur.

## Ekranlar

| | |
|---|---|
| **TopBar** | Yüzen cam çubuk: launcher, saat, ağ/şarj/X-Defender rozetleri, kontrol merkezi |
| **Dock** | Gauss eğrisiyle büyüyen, altta yüzen uygulama rıhtımı |
| **Launcher** | Meta tuşu ile açılan, aramalı, sticker düzenleme kabiliyetli tam ekran cam kart |
| **ControlCenter** | Tema/parlaklık/ses/ağ/güvenlik kartları |
| **LockScreen** | Aşırı bulanık duvar kâğıdı, dev saat, yaylı PIN alanı |
| **Stickers** | Masaüstünde sürüklenebilir, ızgaraya oturan, JSON olarak kalıcı çıkartmalar |

## Mimari (özet)

```
┌────────────────────────────────────────────────────────┐
│ KWin (Wayland compositor, kwin_wayland)                │
│  ┌──────────────────────────────────────────────────┐  │
│  │ plasmex (Qt6/QML shell — tek pencere)            │  │
│  │  ├─ Wallpaper  (ShaderEffectSource arka planı)   │  │
│  │  ├─ Desktop/Sticker katmanı                      │  │
│  │  ├─ TopBar · Dock · Launcher · CC · Notif · Lock │  │
│  │  └─ xos.api · xos.apps · xos.system · xos.settings│ │
│  │       xos.defender (D-Bus istemcisi, opsiyonel)  │  │
│  └──────────────────────────────────────────────────┘  │
│  uygulamalar (Qt/GTK/Firefox …)                       │
└────────────────────────────────────────────────────────┘
```

Detaylı anlatım: [`docs/architecture.md`](docs/architecture.md),
tasarım dili: [`docs/design/liquid-glass.md`](docs/design/liquid-glass.md),
yol haritası: [`docs/roadmap.md`](docs/roadmap.md).

## Yasal / marka notu

- Lisans: **GPLv3** (bkz. `LICENSE`).
- X-OS hiçbir üçüncü tarafın marka amblemini, logosunu veya uygulama
  arayüzünü kopyalamaz. Arayüz ilhamı alınan tasarım yaklaşımları
  (doğrusal/ferah üretim yazılımı estetiği, mobil işletim sistemi cam
  malzemesi) fikri düzeyde referanstır; hiçbir marka işareti, logotip veya
  telifli varlık depoda tutulmaz. Bkz. [`docs/branding.md`](docs/branding.md).
- İkon seti, logo ve tüm görseller bu depoda **özgün olarak üretilir**.

## Durum

Erken geliştirme (v0.1 — "iskele"). Yol haritası için
[`docs/roadmap.md`](docs/roadmap.md). Katkı için `make lint && make test`
sonucu temiz olmalıdır.
