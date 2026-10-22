# X-OS D-Bus kontratları

X-OS bileşenleri (shell, servisler, üçüncü taraf uygulamalar) oturum
`session bus` üzerinde konuşur. Bu dizin, **sabitlenmiş** arayüzlerin tek
kaynağıdır.

| Servis | Nesne | Arayüz | Durum |
|---|---|---|---|
| `io.xos.XDefender` | `/io/xos/XDefender` | `io.xos.XDefender` | kontrat hazır, uygulama depoda değil |
| `io.xos.Notifications` | `/io/xos/Notifications` | `org.freedesktop.Notifications` | v0.2 (shell sahiplenecek) |
| `io.xos.shell` | `/io/xos/Shell` | `io.xos.Shell` | v0.3 (CLI ↔ shell köprüsü) |

## Kurallar

1. Her yeni entegrasyon önce bu dizinde kontrat + örnek yayınlar,
   sonra kod eklenir.
2. Servis **opsiyoneldir**: kabuk tarafı, servis bulunamadığında sessizce
   çalışır (kart gizler, rozeti kaldırır) — hata bildirmez, gürültü çıkarmaz.
3. İsim çatışmalarından kaçın: `io.xos.*` alan adı yalnızca bu projeye ait.
4. İmza değişiklikleri kırıcıdır; yeni arayüz ayrı adla (`…2`) yayınlanır.

Kontrat örnekleri: [x-defender/README.md](x-defender/README.md).
