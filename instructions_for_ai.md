# Instruksi Perbaikan dan Implementasi Fitur (paws-n-parcels)

Dokumen ini berisi instruksi terperinci untuk mengimplementasikan dua fitur baru pada sistem pengiriman paket (Delivery System) dan tampilan (GameScene) di project `paws-n-parcels`.

Ikuti instruksi ini baris demi baris, dan perbarui file-file terkait sesuai panduan.

## Objektif 1: Menyembunyikan `senderIndicator` saat Player Membawa Paket
**Konteks:** Saat ini, ketika player mengambil paket dari rumah pengirim, ikon panah kuning (`arrow_yellow`) sudah berhasil dihilangkan dari layar. Namun, indikator pengirim (seperti `indicator_sender` dan `indicator_highlight`) di atas rumah-rumah yang memiliki paket *masih tetap terlihat*. Indikator ini harus disembunyikan sampai player selesai mengantar paketnya.

**Langkah Implementasi:**
1. Buka file `Presentation/Scenes/GameScene.swift`.
2. Cari fungsi `private func updateIndicators()`.
3. Di dalam fungsi tersebut, temukan bagian kode yang mengecek status target receiver:
   ```swift
   let targetReceiverName = deliverySystem?.activePackage?.receiver.name
   ```
4. Tambahkan sebuah variabel konstan untuk mengecek apakah player sedang memegang paket atau tidak:
   ```swift
   let isHoldingPackage = deliverySystem?.activePackage != nil
   ```
5. Di dalam *looping* `for entity in mapBuilder.environmentEntities`, temukan logika yang mengatur `isHidden` untuk `highlight` dan `senderIcon`.
6. Ubah logika `isHidden` tersebut agar indikator ikut disembunyikan (bernilai `true`) jika `isHoldingPackage` bernilai `true`.
   Contoh perubahan:
   ```swift
   // Sebelum:
   highlight?.isHidden = !(isSender && isWithinRange)
   senderIcon?.isHidden = !isSender
   
   // Sesudah:
   highlight?.isHidden = !(isSender && isWithinRange) || isHoldingPackage
   senderIcon?.isHidden = !isSender || isHoldingPackage
   ```

---

## Objektif 2: Menerapkan Cooldown Spawn Request Baru Setelah Paket Terkirim
**Konteks:** Setelah paket berhasil diantar ke penerima, kemunculan request paket baru (yang digenerate oleh sistem) harus memiliki jeda/interval waktu (cooldown) (contoh: 5 detik). Nilai konfigurasi jeda ini harus diletakkan di `GameConfig`.

**Langkah Implementasi:**

1. **Tambahkan Konfigurasi Cooldown:**
   - Buka file `Core/GameConfig.swift`.
   - Tambahkan variabel statis baru untuk menyimpan nilai interval (misalnya 5 detik):
     ```swift
     static let newRequestSpawnDelay: Int = 5
     ```

2. **Perbarui Logika di RequestSystem:**
   - Buka file `Engine/Systems/RequestSystem.swift`.
   - Cari fungsi `func triggerNewPackageSpawn()`.
   - Tambahkan parameter `delaySeconds` pada fungsi tersebut dengan nilai *default* 0, dan teruskan nilainya ke fungsi `scheduleNextPackageSpawn`.
     Contoh perubahan:
     ```swift
     func triggerNewPackageSpawn(delaySeconds: Int = 0) {
         scheduleNextPackageSpawn(delaySeconds: delaySeconds)
     }
     ```

3. **Terapkan Cooldown di GameScene saat Paket Diantar:**
   - Buka kembali file `Presentation/Scenes/GameScene.swift`.
   - Cari fungsi `private func interactWithHouse(_ house: HouseEntity)`.
   - Di dalam blok kondisi sukses pengiriman (tepat di bawah `let result = deliverySys.deliverPackage(...)`), cari pemanggilan fungsi:
     ```swift
     requestSys.triggerNewPackageSpawn()
     ```
   - Ubah pemanggilan fungsi tersebut agar menggunakan nilai jeda yang telah kita buat di `GameConfig`:
     ```swift
     requestSys.triggerNewPackageSpawn(delaySeconds: GameConfig.newRequestSpawnDelay)
     ```

---
**Catatan untuk AI:**
Pastikan hanya memodifikasi bagian yang diinstruksikan. Jangan menghapus fungsionalitas lain atau logika animasi `bounceAction` yang sudah ada pada indikator.
