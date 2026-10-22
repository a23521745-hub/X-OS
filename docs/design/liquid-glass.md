# Liquid Glass — X-OS Tasarım Dili

Bu belge, PlasmaX arayüzünün **görsel sözleşmesidir**. Kod bunu
`design/tokens/xos.tokens.json` üzerinden uygular; tasarım değişikliği önce
token'a, sonra QML'e akar.

## 1. Malzeme: "sıvı cam"

Her yüzen yüzey (TopBar, Dock, Launcher kartı, bildirimler, PIN alanı)
aynı malzemeden yapılır — `GlassSurface.qml`:

| Katman | Amaç | Token |
|---|---|---|
| backdrop bulanıklığı | Arkadaki duvar kâğıdını 1/3 çözünürlükte gaussian ile erit | `glass.blurRadius` (48/42 px) |
| doygunluk | Bulanık bölgede renk yoğunluğu koru | `glass.saturation` (1.45 / 1.25) |
| tint | Metin okunabilirliği için cam tonu | `glass.tint` + `tintOpacity` |
| rim | 1 px ışık halkası; sol-üst daha parlak (ana ışık yönü) | `glass.rim` |
| sheen | Üst üçte birde spekülar parlaklık | `glass.fillStrong → fill` gradyanı |
| refraksiyon | Köşede ince ışık kırılması dilimi | `glass.refraction` |
| shadow | Yüzey havalandırır | `elevation.low/mid/high` |
| grain | Bantlanma önleyici dithering | `glass.grain` |

**Kurallar**

1. Cam hiçbir zaman tam saydam değildir: `tintOpacity < 1` ama asla `0`.
2. Cam üstünde metin her zaman `ink` token'ıdır; `inkMuted` yalnızca ikincil
   bilgi, `inkFaint` yalnızca ipucu metnidir.
3. Aynı anda en fazla **iki** cam derinliği üst üste biner (Dock → tooltip).
4. Küçük yüzeyler (< 60 px) `compact: true` — blur pass yok, rim + sheen var.

## 2. Hareket — "tatlı nokta"

Amaç: **optimizedema, gösterişli değil** — 60 Hz'de düşmeyen, 120 Hz'de
kaygan hisseden geçişler.

| Amaç | Süre | Easing |
|---|---|---|
| anlık geri bildirim (basma) | 90 ms | OutCubic |
| hover / toggle | 150 ms | OutCubic |
| panel açılışı (varsayılan) | 240 ms | `standard` bezier (0.2,0,0,1) |
| büyük yüzey (Launcher) | 380 ms | OutBack, overshoot 0.35 |
| otomatik gizlenme | 560 ms | InOutQuad |

- Büyüme/dock: Gauss sarkaç + `OutBack` — fizik simülasyonu yok, maliyeti ucuz.
- Yaylar: `motion.spring` (stiffness 380 / damping 34) — sticker yerine oturuşu.
- `reducedMotionScale = 0`: `prefers-reduced-motion`/erişilebilirlikte tüm
  animasyonlar bu katsayıya vurulur (tamamen kapanabilir).

## 3. Renk & tema

- Varsayılan **dark**: mürekkep `#F4F6FB` üzerine derin `#07080C` canvas,
  mor `#7C5CFF` vurgu + camgöbeği `#38D9E8` ikincil ışık.
- **light**: `#EDEFF6` canvas, beyaz cam (`tintOpacity` 0.42 — daha sütli),
  vurgu `#6244E8`.
- Tone geçişleri `ColorAnimation` ile `motion.slow` sürer (göz kamaşması yok).
- Duygular için token renkleri: `mint` (güvenli), `amber` (uyarı),
  `danger` (tehdit), `success`.

## 4. Tipografi

- Aile: Inter (yoksa Noto Sans → DejaVu Sans).
- Ölçek: caption 11 / label 13 / body 14 / heading 16 / title 20 / display 32.
- Ağırlık disiplini: 400 normal, 500 vurgu, 600 başlık. 700+ kullanılmaz —
  cam yüzeylerde kalın metin titrer.
- Rakamlar/saat: tabular hizalama (sütunlar zıplamasın).

## 5. Şekil & boşluk

- Radius: 6 / 10 / 14 / 20 / 28 / 36 / pill(999). Paneller **pill**,
  kartlar 28–36, satır içi öğeler 10–14.
- Izgara: 4 px taban; öğe aralıkları 8/12/18/24/36.
- Yüzen paneller ekran kenarından `topBarInset=10`, `dockInset=14` kadar
  içeridir — asla kenara yapışmaz (hava boşluğu = "yüzer" his).

## 6. İkonografi

- Kendi setimiz: `design/branding/icons.svg`, 24 px ızgara, 1.5 px kontur,
  yuvarlak uç. Sprite sırası `IconGlyph.names` ile senkron (test korur).
- Dolgu ikon yok; ağırlık 1.5 px'te sabit. Renk = `ink` veya `accent`.
- Üçüncü taraf ikon seti (icône, Feather, vb.) **kullanılmaz** — lisans ve
  telif riski olmadan tamamen özgün çizim.

## 7. Marka disiplini

- Logo: `design/branding/logo.svg` — kendi "X" ligatürümüz (bkz. `docs/branding.md`).
- Hiçbir üçüncü taraf logosu, amblemi veya uygulama ekran görüntüsü depoya
  girmez; test bunu otomatik denetler.
- Üretim yazılımı estetiğinden **ilham** alınır; hiçbir markanın arayüzü
  taklit edilmez.

## 8. Önizleme

`design/preview/index.html` token CSS'ini kullanan hızlı bir görsel
referanstır (tarayıcıda açılır, gerçek QML'deki malzemenin birebir değil
**yaklaşık** görünümüdür — kaynak kabul testi değil, tasarım incelemesi içindir).
