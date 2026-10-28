# SURUH - Panduan Penggunaan & Pengembangan Frontend

Dokumentasi Teknis & Pengoperasian Aplikasi Flutter SURUH Pontianak (Live Backend Ready).

---

## 1. Gambaran Umum & Arsitektur

Aplikasi SURUH adalah platform jasa on-demand Pontianak berbasis Flutter yang dibangun dengan prinsip **Clean Architecture**. Seluruh data operasional (kategori layanan, katalog servis, profil pengguna, dan riwayat pesanan) terhubung secara langsung (*live*) ke backend SURUH Django REST Framework API (`https://suruhjak.teknusa.com`) serta didukung SQLite (`AppDatabase`) untuk caching offline berkecepatan tinggi.

- **State Management:** Lapisan UI & Navigasi menggunakan BLoC / Cubit dan GoRouter.
- **Dependency Injection:** Injeksi dependensi modular menggunakan `get_it` (Service Locator).
- **Jaringan API:** HTTP Client dengan penanganan JWT Bearer token otomatis, error parsing, dan integrasi API DRF.
- **Local Database:** SQLite lokal via `sqflite` / `sqflite_common_ffi` untuk caching offline data kategori & layanan.

---

## 2. Prasyarat Sistem & Dependensi

- **Flutter:** Flutter SDK versi `^3.19.0` atau yang lebih baru (Channel Stable).
- **Dart:** Dart SDK versi `^3.3.0`.
- **Platform Target:** Linux (GTK3 / Clang / CMake), Android Studio / SDK (untuk APK), atau Chrome (untuk Web).

---

## 3. Konfigurasi Backend & API

Konfigurasi backend tersentralisasi di berkas `lib/core/config/app_config.dart`:

```dart
// lib/core/config/app_config.dart
const AppConfig({
  this.backend = Backend.suruhApi,
  this.appName = 'SURUH',
  this.tagline = 'Ada urusan? Suruh kami',
  this.publisher = 'SURUH Pontianak',
  this.articleUrl = 'https://suruhjak.teknusa.com/api/docs/',
  this.currencySymbol = 'Rp',
  this.currencyLocale = 'id_ID',
});

// Endpoint default: https://suruhjak.teknusa.com
// Endpoint lokal Docker: http://localhost:8019
```

---

## 4. Panduan Menjalankan Frontend

### A. Mengunduh Dependensi
```bash
cd suruh
flutter pub get
```

### B. Menjalankan Aplikasi di Linux Desktop
```bash
flutter run -d linux
```

### C. Menjalankan Aplikasi di Android
```bash
flutter run -d <device_id>
```

### D. Menjalankan Aplikasi di Web Browser
```bash
flutter run -d chrome
```

---

## 5. Alur Pengujian & Validasi Kualitas

Semua data demo dan mock telah dihapus dari kode sumber. Validasi dilakukan menggunakan unit test dan automated linter:

```bash
# Analisis kode (harus 0 issues)
flutter analyze

# Menjalankan seluruh test (BLoC, Entities, Pricing, Local DB SQLite)
flutter test
```

---

## 6. Fitur-Fitur Utama Aplikasi

1. **Autentikasi:** Login menggunakan nomor WhatsApp/HP/Email terdaftar dan password. Mendukung pembuatan akun baru.
2. **Beranda & Katalog:** Menampilkan kategori layanan Pontianak (Antar Barang, Belanja Pasar, Antar Makanan, Urus Dokumen, dll) dari endpoint backend.
3. **Keranjang & Estimasi:** Memasukkan item ke keranjang belanja, kalkulasi biaya ongkos kirim dan total biaya.
4. **Checkout:** Konfirmasi alamat pengantaran, metode pembayaran Tunai (COD) atau Transfer Bank.
5. **Pelacakan Pesanan:** Pemantauan status pesanan secara real-time dan histori pesanan aktif / selesai.
6. **Dashboard Driver:** Tampilan khusus mitra pengemudi untuk menerima dan menyelesaikan pesanan pelanggan.
7. **Profil Pengguna:** Manajemen alamat, edit profil (nama & email), dan informasi akun pengguna.

---

## 7. Perintah Build Produksi (Release)

- **Android APK:** `flutter build apk --release`
- **Android App Bundle:** `flutter build appbundle --release`
- **Linux Desktop:** `flutter build linux --release`
- **Web Portal:** `flutter build web --release`
