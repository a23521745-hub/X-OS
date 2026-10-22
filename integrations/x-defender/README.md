# X-Defender ↔ X-OS entegrasyon kontratı

**Durum:** kontrat sabitlendi; X-Defender kodu henüz bu depoda değil.
PlasmaX bunu **opsiyonel** tüketir: servis yoksa arayüz hiçbir şey kaybetmez.

## D-Bus kimliği

| Alan | Değer |
|---|---|
| Servis | `io.xos.XDefender` |
| Nesne | `/io/xos/XDefender` |
| Arayüz | `io.xos.XDefender` |
| Oturum | session bus |

## Zorunlu API (v1)

```
method  Status() → (s label)
        // örn. "Güvenli", "3 tehdit bulundu", "Tarama sürüyor…"
        // Çevrimdışı değilse C++ tarafı bu metni doğrudan gösterir.

signal  ThreatsChanged(u threats)
        // tehdit sayısı değişince yayınlanır; shell rozeti günceller.

method  QuickScan() → ()
        // ControlCenter'daki "Tara" düğmesi bunu çağırır.

signal  StateChanged(s state)
        // "idle" | "scanning" | "threats" | "updating"
```

## Örnek implementasyon iskeleti (tarafımızca kabul testi)

```python
# X-Defender servisi (dbus-python / sdbusii — dilediğinle)
bus = SessionBus()
bus.request_name("io.xos.XDefender")

class XDefender(ServiceObject):
    @method()
    def Status(self) -> "s":
        return "Güvenli" if self.threats == 0 else f"{self.threats} tehdit"

    @method()
    def QuickScan(self) -> "":
        threading.Thread(target=self._scan, daemon=True).start()

    @signal()
    def ThreatsChanged(self, n: "u"):
        pass
```

## Shell tarafı

`shell/src/xdefender.{h,cpp}` sınıfı:

- servis **varsa** `Status()` okur, `ControlCenter` içindeki X-Defender kartını
  gösterir;
- servis **yoksa** kart gizlenir, TopBar rozeti "Bağlı değil" (v0.1) → hiç
  göstermez (v0.2 planı);
- servis sonradan başlar/kapanır: `NameOwnerChanged` dinlenir, canlı geçiş.

## Uyumluluk kuralı

Kontratı **geriye dönük genişletilebilir** tut: yeni sinyal/metot ekle,
mevcut asla imzayı değiştirme. Kırılan değişiklik için `v2` arayüzü ayrı
adla yayınlanır (`io.xos.XDefender2`).
