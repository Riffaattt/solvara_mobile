# PRD Flutter v2 — Solvara Reporter App

**Komponen:** Flutter mobile app untuk warga/pelapor  
**Versi:** 2.0 — selaras dengan Backend Laravel + MySQL v2 dan dua flow IBM Langflow  
**Tanggal:** 11 Oktober 2026  
**Status:** Spesifikasi MVP untuk implementasi  
**Pengguna dokumen:** IBM Bob / AI coding agent, Flutter developer, backend integrator

> **Tujuan dokumen:** menjadi sumber spesifikasi utama untuk aplikasi Flutter sisi warga. Aplikasi menggunakan API Laravel; aplikasi tidak memanggil Gemini atau Langflow secara langsung.

## Instruksi untuk AI Coding Agent

Baca dokumen ini sepenuhnya sebelum coding. Audit repository Flutter yang ada, versi Flutter/Dart, struktur folder, package, navigasi, konfigurasi environment, model, API client, test, serta implementasi sebelumnya. Setelah audit singkat, **langsung implementasikan requirement MVP** secara bertahap; jangan berhenti pada rencana atau mockup.

- Pertahankan kode yang masih berfungsi dan ikuti konvensi repository yang ada.
- Gunakan Backend PRD `Solvara_PRD_Backend_Laravel_MySQL_v2.md` sebagai kontrak backend pendamping. Endpoint dan field pada dokumen ini adalah kontrak yang harus disepakati antara frontend dan backend.
- Jangan membuat data laporan palsu untuk menggantikan endpoint yang belum tersedia. Untuk UI development, gunakan fixture/test-only yang jelas dipisahkan dari build production.
- Jangan menanam API key Gemini, Langflow API key, password database, atau secret backend dalam Flutter.
- Jangan mengklaim fitur atau integrasi sudah berfungsi sebelum menjalankan dan menguji aplikasi.
- Bila implementasi backend belum sama dengan kontrak di sini, catat perbedaan lalu selaraskan dengan backend sebelum menulis adapter yang menyembunyikan mismatch.
- Jalankan `flutter analyze` dan test yang relevan. Laporkan hasil aktual, termasuk kegagalan yang belum terselesaikan.

## 1. Ringkasan Produk

Solvara adalah aplikasi pelaporan fasilitas publik. Warga mengirim deskripsi masalah, foto, lokasi, dan waktu kejadian. Laravel menerima submission, menyimpan foto secara privat sementara, menjalankan Langflow Flow A untuk moderasi dan relevansi foto, lalu mencari laporan sekitar melalui MySQL. Jika ada kandidat, Laravel menjalankan Flow B untuk menilai kemungkinan duplikat. Keputusan resmi dibuat oleh backend dan, untuk kasus yang ambigu, dapat memerlukan pemeriksaan petugas.

Aplikasi Flutter bertanggung jawab untuk mengumpulkan data dengan baik, mengirimnya secara aman, menampilkan status proses asinkron, meminta tanggapan warga jika ada kemungkinan duplikat, dan menampilkan laporan resmi yang diterima.

### Tujuan MVP

1. Memungkinkan warga login.
2. Membuat submission dengan deskripsi, 1–3 foto, lokasi (koordinat dan/atau alamat), serta waktu kejadian.
3. Mengirim submission sebagai `multipart/form-data` ke Laravel.
4. Menampilkan progress pemeriksaan AI tanpa menganggap submission langsung menjadi laporan resmi.
5. Menampilkan kandidat laporan serupa hanya jika backend menyediakannya dan field tersebut aman untuk pelapor.
6. Menerima tanggapan warga pada kasus dugaan duplikat.
7. Menampilkan daftar, detail, timeline, dan status laporan resmi milik warga.
8. Memungkinkan warga mengirim feedback pada laporan yang sudah diterima.

## 2. Arsitektur dan Batas Tanggung Jawab

- **Flutter:** UI warga, kamera/galeri, izin lokasi, validasi awal, formulir submission, status tracking, daftar/detail laporan, feedback.
- **Laravel API:** autentikasi, validasi final, private temporary storage, submission lifecycle, rate limiting, pemanggilan Langflow, pencarian kandidat, idempotensi, aturan bisnis, keputusan penerimaan, dan data yang boleh ditampilkan ke warga.
- **MySQL:** sumber data utama untuk metadata submission, laporan resmi, status, dan relasi laporan.
- **Private file storage:** foto sebelum diterima disimpan di quarantine/private storage; file tidak boleh ditampilkan melalui URL publik permanen.
- **Langflow Flow A — Image Gate:** memeriksa keamanan gambar, relevansi dengan masalah fasilitas publik, kategori yang disarankan, dan kecocokan dengan deskripsi.
- **Langflow Flow B — Duplicate Intelligence:** membandingkan laporan baru dengan kandidat yang sudah dicari dan dipilih backend.

**Flutter tidak memanggil Langflow/Gemini langsung.** Flutter tidak menentukan moderasi final, skor prioritas, atau status penerimaan; semua keputusan itu berasal dari Laravel.

## 3. Pengguna dan Cakupan

### Pengguna

Warga/pelapor yang ingin mengirim pengaduan dan melacak statusnya.

### Termasuk MVP

- Login, logout, dan pemulihan sesi.
- Beranda warga.
- Formulir laporan: deskripsi, foto, kategori opsional, lokasi, waktu kejadian.
- Pratinjau sebelum upload.
- Status submission asinkron.
- Tanggapan terhadap laporan yang dicurigai duplikat.
- Laporan Saya, detail laporan, dan timeline status.
- Feedback pada laporan yang telah diterima.
- Penanganan izin, loading, error jaringan, empty state, dan retry.

### Tidak termasuk MVP

- Dashboard petugas/admin.
- Registrasi akun apabila endpoint `POST /auth/register` belum tersedia di backend.
- Mengubah status laporan sebagai petugas.
- Memanggil model AI langsung dari perangkat.
- Chatbot bebas, notifikasi push produksi, video, laporan offline yang kompleks, atau pengenalan akar masalah otomatis di perangkat.

## 4. Alur Penggunaan

### 4.1 Login dan pemulihan sesi

1. Saat aplikasi dibuka, periksa token yang disimpan secara aman.
2. Jika token tersedia, panggil `GET /api/v1/auth/me` untuk memvalidasi sesi.
3. Jika sukses, arahkan ke Beranda. Jika `401`, hapus token dan tampilkan Login.
4. Login memakai email dan password melalui `POST /api/v1/auth/login`.
5. Logout mengirim `POST /api/v1/auth/logout` jika memungkinkan, lalu hapus token lokal tanpa bergantung pada keberhasilan jaringan.

Jangan mengasumsikan endpoint registrasi tersedia. Jika belum ada, tampilkan keterangan bahwa akun diberikan/dibuat sesuai mekanisme backend, bukan form registrasi palsu.

### 4.2 Membuat submission

1. Warga memilih **Buat Laporan**.
2. Mengisi deskripsi masalah (20–2.000 karakter).
3. Memilih 1–3 foto dari kamera atau galeri. Ukuran awal maksimal mengikuti backend: 10 MB per gambar; validasi server tetap otoritatif.
4. Memilih kategori jika tersedia. Daftar kategori berasal dari `GET /api/v1/categories`, bukan hardcode.
5. Mengambil lokasi GPS atau memasukkan alamat/area manual. Koordinat harus dikirim berpasangan; jangan mengirim latitude saja atau longitude saja.
6. Memilih waktu kejadian. Default adalah waktu sekarang perangkat, tetapi server tetap mencatat `received_at` sebagai waktu resmi penerimaan.
7. Menampilkan layar pratinjau yang merangkum deskripsi, foto, lokasi, kategori, dan waktu.
8. Saat pengguna mengonfirmasi, kirim `POST /api/v1/report-submissions` sebagai multipart request.
9. Setelah respons `202 Accepted`, tampilkan layar **Status Pemeriksaan** menggunakan `submission_id`. Jangan menunggu inferensi AI berlangsung dalam request upload.
10. Poll status memakai `GET /api/v1/report-submissions/{id}` dengan interval awal sekitar 3–5 detik, backoff hingga 15–30 detik, batas waktu/attempt yang wajar, dan aksi refresh manual. Hentikan polling saat status terminal atau layar ditutup; ketika pengguna membuka kembali submission, lanjutkan dari status server.

Jika jaringan terputus setelah upload dan hasil submit tidak diketahui, jangan langsung membuat submission baru. Gunakan dukungan idempotensi jika backend menyediakannya; jika belum, tampilkan pesan bahwa status sedang diverifikasi dan coba cari submission yang telah dibuat bila endpoint tersebut tersedia.

### 4.3 Menangani hasil pemeriksaan

- **Masih diproses:** tampilkan status dan penjelasan singkat; jangan menyatakan gagal.
- **Perlu review petugas:** informasikan bahwa laporan memerlukan pemeriksaan, tanpa menampilkan detail sensitif moderasi.
- **Kemungkinan duplikat:** tampilkan kandidat aman yang dikirim backend dan minta warga memilih apakah masalahnya sama, berbeda, atau tidak yakin.
- **Diterima:** tampilkan `report_id`/`public_code` jika disediakan, dan tautan ke Detail Laporan.
- **Ditolak:** tampilkan alasan umum yang aman dan instruksi yang dapat dilakukan warga (mis. periksa foto/deskripsi dan buat submission baru bila diizinkan kebijakan).
- **Terkait laporan yang sudah ada:** tampilkan informasi publik laporan tujuan hanya jika backend mengizinkannya.
- **Gagal diproses:** tampilkan error yang ramah, pilihan refresh, dan instruksi coba lagi atau hubungi dukungan; jangan mengubahnya menjadi “ditolak”.
- **Kedaluwarsa:** beri tahu bahwa proses submission sudah kedaluwarsa dan minta warga memulai submission baru bila diperlukan.

### 4.4 Melacak laporan resmi

Warga membuka **Laporan Saya** yang berasal dari `GET /api/v1/reports`. Detail berasal dari `GET /api/v1/reports/{id}`. Data dibatasi backend pada laporan milik warga yang login. Tampilkan status, deskripsi, kategori, tanggal, foto yang memang diizinkan, lokasi yang pantas ditampilkan, dan timeline publik.

### 4.5 Mengirim feedback

Pada laporan yang sesuai kebijakan backend, warga dapat memilih `still_occurring` atau `additional_info`, menambahkan pesan opsional, lalu mengirim feedback. UI menyatakan feedback terkirim hanya setelah server mengonfirmasi sukses.

## 5. Status Submission dan Pemetaan UI

Status pipeline berasal dari backend, bukan dihitung sendiri oleh Flutter.

Pemetaan status ke UI:

- `received` — **Submission diterima**; tampilkan bahwa proses akan dimulai.
- `queued_for_moderation` — **Menunggu pemeriksaan foto**; tampilkan progress.
- `moderating` — **Foto sedang diperiksa**; tampilkan progress.
- `queued_for_duplicate_check` — **Pemeriksaan awal lolos**; tampilkan progress pencarian laporan terkait.
- `checking_duplicates` — **Memeriksa laporan serupa**; tampilkan progress.
- `duplicate_review` — **Ditemukan kemungkinan laporan serupa**; tampilkan kandidat aman dan pilihan tanggapan.
- `manual_review` — **Menunggu pemeriksaan petugas**; informasikan bahwa petugas akan meninjau.
- `accepted` — **Laporan diterima**; tampilkan tautan detail laporan resmi.
- `rejected` — **Submission tidak diterima**; tampilkan alasan umum yang aman dari API.
- `linked_to_existing_report` — **Dikaitkan dengan laporan yang sudah ada**; tampilkan referensi publik jika tersedia.
- `processing_failed` — **Pemeriksaan mengalami kendala**; tawarkan refresh, jangan simpulkan konten ditolak.
- `expired` — **Submission kedaluwarsa**; beri opsi memulai laporan baru.

Status `report_submissions` berbeda dari status laporan resmi. Status laporan resmi dapat meliputi `submitted`, `accepted`, `in_progress`, `resolved_pending_verification`, `verified`, `reopened`, dan `rejected`. Flutter harus menggunakan dua pemetaan UI terpisah.

## 6. Tech Stack dan Arsitektur Kode

Gunakan dependency yang kompatibel dengan versi Flutter/Dart repository.

Pilihan MVP:

- **Framework:** Flutter + Dart; prioritaskan Android bila scope tim terbatas.
- **State management:** `flutter_riverpod`, dengan satu pola state yang konsisten.
- **HTTP client:** `dio`, termasuk interceptor token, timeout, multipart upload, dan mapping error.
- **Routing:** `go_router`, dengan route terproteksi berdasarkan sesi.
- **Token:** `flutter_secure_storage`; jangan simpan token di log atau SharedPreferences.
- **Foto:** `image_picker` untuk kamera/galeri dan validasi ukuran/format.
- **Lokasi:** `geolocator`, minta izin ketika dibutuhkan dan sediakan fallback manual.
- **Peta opsional:** `flutter_map` + `latlong2`; gunakan tile provider yang sesuai dan tampilkan atribusi. Bukan blocker MVP.
- **Tanggal:** `intl` untuk format Bahasa Indonesia.
- **Testing:** Flutter test dengan mock API/repository, unit test, widget test, serta contract/integration test.

Struktur yang disarankan, sesuaikan jika repository sudah memiliki konvensi baik:

```text
lib/
  app/
    app.dart
    router.dart
  core/
    config/
    network/
    errors/
    storage/
    widgets/
  features/
    auth/
      data/ domain/ presentation/
    home/
    categories/
    report_submission/
      data/ domain/ presentation/
    submission_tracking/
    reports/
    feedback/
```

Pisahkan presentation → controller/provider → repository → API client. Widget tidak melakukan request HTTP secara langsung. Gunakan DTO Dart bertipe dan mapping status di satu tempat.

## 7. Kontrak REST API — Sumber Kebenaran untuk Integrasi

Base URL dibaca dari konfigurasi build, contoh `--dart-define=API_BASE_URL=https://api.example.com`. `API_BASE_URL` adalah base host saja; kode menambahkan prefix `/api/v1`. Untuk pengembangan lokal di perangkat fisik, jangan gunakan `localhost` untuk menunjuk komputer developer; gunakan alamat host LAN atau URL tunnel development yang aman.

Semua endpoint menggunakan JSON, kecuali upload submission yang memakai multipart. Endpoint yang membutuhkan login menggunakan `Authorization: Bearer <token>`.

Endpoint yang dipakai aplikasi warga:

- **`POST /api/v1/auth/login`** — login; mengembalikan token dan profil pengguna.
- **`POST /api/v1/auth/logout`** — revoke token; aplikasi juga menghapus token lokal.
- **`GET /api/v1/auth/me`** — validasi sesi dan mengambil profil/role.
- **`GET /api/v1/categories`** — mengambil kategori aktif (`id`, `code`, `name`).
- **`POST /api/v1/report-submissions`** — membuat submission multipart; mengembalikan `202 Accepted`, `submission_id`, `status`, dan `message`.
- **`GET /api/v1/report-submissions/{id}`** — polling status pipeline, pesan aman, kandidat publik bila ada, serta `report_id` jika diterima.
- **`POST /api/v1/report-submissions/{id}/duplicate-response`** — mengirim tanggapan warga atas kandidat duplikat.
- **`GET /api/v1/reports`** — daftar laporan milik pengguna yang login beserta pagination.
- **`GET /api/v1/reports/{id}`** — detail laporan serta timeline yang boleh dilihat warga.
- **`POST /api/v1/reports/{id}/feedback`** — mengirim feedback.

Flutter **tidak** memanggil Flow A/Flow B, endpoint petugas, atau API Gemini secara langsung.

### 7.1 Login

Request:

```json
{
  "email": "warga@example.com",
  "password": "password-user"
}
```

Bentuk response kontrak:

```json
{
  "data": {
    "token": "<access-token>",
    "user": {
      "id": "usr_123",
      "name": "Nama Warga",
      "email": "warga@example.com",
      "role": "citizen"
    }
  }
}
```

Nama key `token`/struktur wrapper harus diselaraskan dengan implementasi auth backend aktual. Normalisasikan respons melalui satu DTO dan jangan membuat fallback yang diam-diam menyamarkan format API yang berbeda.

### 7.2 Kategori

Request: `GET /api/v1/categories`

Response kontrak yang direkomendasikan:

```json
{
  "data": [
    { "id": "cat_road", "code": "road_damage", "name": "Jalan rusak" },
    { "id": "cat_waste", "code": "waste", "name": "Sampah menumpuk" }
  ]
}
```

ID contoh di atas bukan nilai hardcoded untuk aplikasi. Flutter harus memakai nilai yang dikembalikan server. Jika API tidak tersedia atau gagal, jangan mengirim kategori palsu; kategori dapat dilewati jika endpoint dan kebijakan backend mengizinkan.

### 7.3 Membuat submission (multipart)

Request: `POST /api/v1/report-submissions` dengan `Content-Type: multipart/form-data`.

Field multipart yang digunakan:

- **`description`** — string, wajib, 20–2.000 karakter.
- **`selected_category_id`** — ID kategori dari `GET /api/v1/categories`; opsional jika backend mengizinkan klasifikasi otomatis. Jangan mengirim `selected_category_id` dan `category_code` bersamaan kecuali backend mendukungnya.
- **`latitude` dan `longitude`** — koordinat numerik, keduanya harus dikirim bersama; latitude rentang -90..90 dan longitude -180..180.
- **`address_text`** — alamat/area sebagai fallback atau penjelas lokasi. Jika koordinat tidak tersedia, backend dapat mengarahkan submission ke `manual_review` dan melewati pencarian spasial.
- **`occurred_at`** — ISO-8601 dengan timezone/offset; waktu kejadian yang dinyatakan pengguna.
- **`client_captured_at`** — ISO-8601 opsional jika waktu foto diketahui; bukan waktu resmi penerimaan.
- **`gps_accuracy_m`** — akurasi GPS opsional yang dilaporkan perangkat.
- **`attachments[]`** — 1–3 file gambar; batas awal 10 MB per file atau limit yang dipublikasikan backend. Validasi server tetap menjadi sumber kebenaran.

Header opsional yang direkomendasikan jika backend mengimplementasikannya:

```http
Authorization: Bearer <token>
Idempotency-Key: <uuid-per-submit-attempt>
Accept: application/json
```

Backend perlu menyimpan dan menghormati `Idempotency-Key` agar retry karena network timeout tidak membuat submission ganda. Jika backend belum mendukung header ini, jangan mengklaim idempotensi tersedia; nonaktifkan double tap dan tangani status submit yang tidak diketahui secara hati-hati.

Contoh response:

```json
{
  "data": {
    "submission_id": "01JEXAMPLEULID",
    "status": "queued_for_moderation",
    "message": "Laporan sedang memeriksa foto dan informasi yang dikirim."
  }
}
```

HTTP status sukses yang diharapkan `202 Accepted`. Flutter tidak boleh membuka detail report seolah-olah laporan resmi sudah dibuat.

### 7.4 Status submission

Request: `GET /api/v1/report-submissions/{submission_id}`.

Contoh response:

```json
{
  "data": {
    "submission_id": "01JEXAMPLEULID",
    "status": "duplicate_review",
    "message": "Kami menemukan laporan yang mungkin berkaitan.",
    "moderation": {
      "decision": "approved",
      "category": "road_damage"
    },
    "possible_matches": [
      {
        "report_id": "01JREPORTEXAMPLE",
        "public_code": "SOL-2026-0012",
        "title": "Jalan berlubang dekat sekolah",
        "category": "road_damage",
        "distance_m": 34.2,
        "created_at": "2026-10-10T10:00:00+07:00",
        "public_status": "in_progress",
        "reason": "Lokasi dan tipe masalah tampak serupa"
      }
    ],
    "report_id": null
  }
}
```

Ini adalah kontrak frontend yang diusulkan. Backend harus mengembalikan hanya informasi kandidat yang boleh diketahui pelapor, tanpa nama/email pemilik laporan, catatan internal petugas, prompt/model raw output, URL foto karantina, atau PII lain. Jika backend tidak memiliki `title`, gunakan field publik yang benar-benar tersedia; jangan mengarang.

### 7.5 Menjawab kemungkinan duplikat

Endpoint: `POST /api/v1/report-submissions/{submission_id}/duplicate-response`.

Request kontrak yang direkomendasikan:

```json
{
  "candidate_report_id": "01JREPORTEXAMPLE",
  "response": "same_issue",
  "message": "Lubang jalan yang sama sudah terlihat di lokasi tersebut."
}
```

Nilai `response` yang direkomendasikan: `same_issue`, `different_issue`, atau `not_sure`. `message` opsional dan harus dibatasi panjangnya. `candidate_report_id` harus berasal dari `possible_matches` dalam submission yang sama. Backend harus memvalidasi keanggotaan kandidat, kepemilikan submission, serta status submission.

Respons contoh: `202 Accepted` atau `200 OK` dengan status terbaru. Keputusan final tetap berada di backend dan mungkin memerlukan petugas; Flutter tidak boleh memutuskan sendiri bahwa submission menjadi duplikat atau diterima.

**Sinkronisasi wajib:** jika backend v2 belum menerapkan body dan nilai enum di atas, selaraskan implementasi backend serta OpenAPI/kontrak sebelum menyelesaikan integrasi Flutter.

### 7.6 Daftar laporan

Request minimum: `GET /api/v1/reports?page=1`.

Parameter `page` dan `per_page` boleh digunakan bila didukung backend. Jangan mengasumsikan filter lain tersedia sebelum dikonfirmasi.

Response kontrak yang direkomendasikan:

```json
{
  "data": [
    {
      "id": "01JREPORTEXAMPLE",
      "public_code": "SOL-2026-0012",
      "title": "Jalan berlubang dekat sekolah",
      "category": { "code": "road_damage", "name": "Jalan rusak" },
      "status": "in_progress",
      "created_at": "2026-10-10T10:00:00+07:00"
    }
  ],
  "meta": { "current_page": 1, "last_page": 1, "per_page": 15, "total": 1 }
}
```

Bentuk pagination perlu mengikuti Laravel Resource/Paginator aktual. Flutter memetakan response di repository; jangan mem-parsing JSON langsung di widget.

### 7.7 Detail dan feedback

Detail: `GET /api/v1/reports/{id}`. Tampilkan hanya atribut yang boleh dilihat pemilik laporan: kode publik, deskripsi, foto resmi, kategori, lokasi yang diizinkan, waktu kejadian/penerimaan jika dipublikasikan, status, dan timeline publik.

Feedback: `POST /api/v1/reports/{id}/feedback`.

```json
{
  "type": "still_occurring",
  "message": "Masalah masih terjadi saat hujan."
}
```

Nilai `type` yang direkomendasikan: `still_occurring` atau `additional_info`. Batasi pesan, validasi status report, dan selaraskan enum dengan backend.

## 8. Networking, Error, dan Reliability

- Semua request terproteksi menambahkan `Authorization: Bearer <token>` melalui Dio interceptor.
- Konfigurasikan connect/receive/send timeout; upload perlu send timeout yang cukup.
- Jangan otomatis retry request multipart yang mungkin membuat submission baru kecuali backend mendukung idempotency.
- Retry polling `GET` boleh memakai exponential backoff dengan jitter dan batas wajar.
- `401`: hapus sesi lalu ke Login.
- `403`: tampilkan akses ditolak.
- `404`: tampilkan data tidak tersedia.
- `409`: tangani konflik/status submission sesuai `error.code` bila backend menggunakannya.
- `413` atau error validasi ukuran: minta warga memilih gambar lebih kecil.
- `422`: tampilkan validasi field berdasarkan response server.
- `429`: beri tahu pengguna menunggu dan coba lagi.
- `5xx`/timeout: tampilkan masalah koneksi/server; jangan memetakannya menjadi moderasi gagal/ditolak.
- Jangan tampilkan stack trace, credential, raw model response, atau detail konten sensitif.

Bentuk error yang diharapkan:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Periksa kembali data yang kamu kirim.",
    "fields": { "description": ["Deskripsi wajib diisi."] }
  }
}
```

## 9. UX dan Aksesibilitas

- Semua label/status berbahasa Indonesia.
- Status tidak hanya dibedakan menggunakan warna; sertakan teks dan ikon.
- Tombol submit dinonaktifkan saat upload berjalan untuk mencegah double submit.
- Tampilkan progress upload terpisah dari progress analisis AI.
- Beri keterangan kapan koordinat digunakan dan minta izin lokasi saat dibutuhkan, bukan pada startup tanpa konteks.
- Sediakan pilihan alamat manual jika izin GPS ditolak atau lokasi tidak akurat.
- Foto memiliki pratinjau dan opsi menghapus/mengganti sebelum submit.
- Beri warning jika akurasi GPS buruk, tetapi sediakan pilihan melanjutkan sesuai kebijakan backend.
- Lakukan refresh data saat kembali ke layar detail/daftar jika diperlukan.
- Gunakan ukuran teks yang nyaman, semantic labels, dan area sentuh memadai.

## 10. Keamanan dan Privasi

- Simpan token hanya menggunakan secure storage dan jangan log token atau isi sensitif.
- Jangan embed API key Gemini/Langflow dalam app.
- Jangan menampilkan URL foto temporary/quarantine.
- Jangan mengekspos informasi pribadi warga lain pada kandidat duplikat.
- Jangan menyimpan foto secara permanen di local cache tanpa kebutuhan dan kebijakan yang jelas.
- Validasi MIME/ukuran di frontend untuk UX, tetapi percayakan pemeriksaan final ke Laravel.
- Jangan menampilkan alasan moderasi yang mengulang isi sensitif secara eksplisit.
- Hormati penghapusan submission temporary dan keterbatasan retensi yang ditentukan backend.

## 11. Testing dan Acceptance Criteria

### Unit dan widget test

- Validasi deskripsi, jumlah foto, ukuran, kategori, koordinat, alamat, dan waktu.
- Mapping setiap submission status ke teks/UI yang benar.
- Parsing DTO dari contoh API sukses/error.
- Perilaku login/logout dan `401`.
- Loading, empty, offline/error, retry, serta navigasi.
- Tombol duplicate-response hanya tersedia ketika statusnya `duplicate_review` dan kandidat datang dari API.

### Integrasi API (dengan mock/contract test)

- Login → me → kategori → submit multipart → poll submission.
- Status berubah dari `queued_for_moderation` menjadi `duplicate_review`, lalu tanggapan warga.
- Submission diterima dan `report_id` ditautkan ke detail laporan.
- Submission `manual_review`, `rejected`, `processing_failed`, dan `expired` ditampilkan dengan benar.
- List/detail laporan hanya memperlihatkan data untuk user yang login.
- Feedback dikirim dan menampilkan sukses hanya setelah response sukses.

### Acceptance criteria MVP

1. Warga dapat login dan logout.
2. Form submission mengirim field sesuai kontrak backend.
3. Upload memproses 1–3 gambar dan tidak mengunci UI selama analisis AI.
4. Aplikasi menangani response `202 Accepted` dan melakukan polling status.
5. Semua status submission backend memiliki state UI yang jelas.
6. Kandidat duplikat hanya menampilkan field publik dan dapat diberi tanggapan warga.
7. Laporan resmi ditampilkan di Laporan Saya hanya setelah backend menyediakan report ID.
8. Flutter tidak memanggil Langflow/Gemini langsung.
9. Tidak ada secret dalam source code atau log.
10. `flutter analyze` dan automated tests yang relevan selesai, dan hasil aktual dilaporkan.

## 12. Urutan Implementasi

1. Audit repository dan dependencies.
2. Implementasikan app config, Dio, interceptor auth, error model, secure storage, dan routing.
3. Implementasikan login dan `/auth/me`.
4. Implementasikan categories dan form submission.
5. Implementasikan kamera/galeri, lokasi GPS/manual, waktu kejadian, pratinjau, dan multipart upload.
6. Implementasikan submission tracking/polling dengan seluruh state backend.
7. Implementasikan duplicate review/response.
8. Implementasikan daftar, detail, timeline, dan feedback laporan resmi.
9. Tambahkan tests, accessibility, loading/empty/error states, serta dokumentasi build/run.
10. Uji integrasi terhadap backend staging/URL lokal yang sesuai.

## 13. Definition of Done

- Fitur wajib pada PRD telah diimplementasikan, atau setiap blocker eksternal dituliskan dengan jelas.
- Kontrak request/response sesuai Backend PRD v2 dan diuji menggunakan mock atau backend nyata.
- Tidak ada endpoint Langflow/Gemini dipanggil dari Flutter.
- Tidak ada data demo masuk ke build production.
- Status async, error, retry, dan review manual dipetakan dengan benar.
- Unit/widget tests dan `flutter analyze` telah dijalankan; hasil dilaporkan tanpa klaim palsu.
- Dokumentasi konfigurasi `API_BASE_URL`, izin perangkat, dan cara menjalankan tersedia.

## Catatan Kontrak yang Harus Disinkronkan dengan Backend

Backend PRD v2 sudah menetapkan endpoint submission/status/duplicate-response. Sebelum integrasi final, pastikan implementasi Laravel secara eksplisit menyepakati:

1. Struktur response `GET /categories`.
2. Detail `possible_matches` yang aman untuk warga pada status submission.
3. Body `duplicate-response` (`candidate_report_id`, `response`, `message`) dan enum yang diizinkan.
4. Envelope/pagination `GET /reports`.
5. Field publik dan timeline `GET /reports/{id}`.
6. Dukungan header idempotensi untuk upload agar retry aman.

**Mulai sekarang:** audit repository Flutter, bandingkan kontrak yang sudah ada dengan dokumen ini, lalu implementasikan aplikasi pelapor sesuai spesifikasi. Prioritaskan konsistensi kontrak API dan alur submission asinkron, bukan sekadar tampilan UI.
