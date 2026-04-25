# Zikirmatik V2

Flutter tabanlı, offline-first Zikirmatik uygulaması.

## Mimari

- State/DI: `flutter_riverpod`
- Routing: `go_router`
- Lokal veri: `drift` + SQLite
- Küçük ayarlar: `shared_preferences`
- Yerel bildirim: `flutter_local_notifications`
- Servis ayrımı: Google Play, Huawei AppGallery ve iOS servisleri arayüz/adaptör katmanı arkasında tutulur.

## Önemli kararlar

- İlk ekran sayaç değildir. `/` route'u dashboard/merkez ekrandır.
- Sayaç ayrı route'tadır: `/sayac`.
- Görsel tasarım placeholder seviyesindedir. Ana ekran ve görsel sistem, kullanıcı tasarım dosyaları geldikten sonra uygulanacaktır.
- İlk sürüm ücretsiz, reklamsız ve limitsizdir. Monetization servisleri şu an no-op/allow-all çalışır.
- Drift tablolarında ileride server sync için `id`, `createdAt`, `updatedAt`, `deletedAt`, `syncStatus` ve opsiyonel `userId` alanları bulunur.

## Flavor komutları

Google Play debug build:

```powershell
flutter build apk --debug --flavor googlePlay --dart-define=STORE_CHANNEL=googlePlay
```

Huawei AppGallery debug build:

```powershell
flutter build apk --debug --flavor huaweiAppGallery --dart-define=STORE_CHANNEL=huaweiAppGallery
```

## Geliştirme komutları

Kod üretimi:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

Kontroller:

```powershell
dart format --set-exit-if-changed .
flutter analyze
flutter test
```
