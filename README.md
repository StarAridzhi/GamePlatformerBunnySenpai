# Bunny Quest

Platformer 2D pixel art untuk **Godot 4.3+** (renderer GL Compatibility).

## Cara menjalankan
1. Buka Godot 4.3 atau lebih baru, klik **Import**, pilih `project.godot`.
2. Tekan **F5**. (Pertama kali dibuka, Godot akan meng-import aset sebentar.)

## Kontrol
| Aksi | Tombol |
|---|---|
| Gerak | A / D atau panah kiri-kanan (atau D-pad / stik kiri) |
| Lompat | Spasi / W / Panah atas / Z (tekan 2x = lompat ganda, tahan = lebih tinggi) |
| Turun dari platform tipis | Bawah + Lompat |
| Pause | Esc / P (R = ulang level, Q = ke judul) |

## Isi game
- 3 dunia: Sunny Meadow, Sunset Canyon, Moonlit Peaks (+ boss King Pig).
- Kumpulkan koin & 3 gem per level, buka checkpoint, tamatkan di bendera finish.
- Hero: Bunny (dari pack). 19 jenis musuh dari pack, tiap jenis punya perilaku sendiri.
- Progress & rekor tersimpan otomatis.

## Struktur
- `scripts/`  semua kode GDScript (level dibangun lewat kode dari `levels/*.json`)
- `levels/`   data level (grid tile + posisi koin/musuh/dll)
- `assets/enemies/`  sprite dari Pixel Adventure 2 (yang kamu berikan)
- `assets/gen/`  tile, background, koin, gem, dll. (dibuat prosedural dengan Python/PIL)
- `assets/audio/`  SFX & musik chiptune (disintesis prosedural)
- `assets/fonts/`  Press Start 2P (SIL OFL)

## Mengubah level
Edit file JSON di `levels/` (karakter `#` = tanah, `=` = platform tipis; ukuran tile 16px),
atau tambahkan musuh di daftar `enemies` (tipe: slime, snail, mushroom, chicken, pig, radish, rock1-3,
rino, duck, trunk, plant, turtle, bluebird, bee, bat, ghost, skull, fatbird).
