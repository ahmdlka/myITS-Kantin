-- ==========================================
-- QUERY UNTUK SISTEM myITS KANTIN
-- TOTAL: 40 QUERY (8 PER ANGGOTA)
-- ==========================================

-- ------------------------------------------
-- ANGGOTA 1
-- ------------------------------------------

-- 1. Searching: Cari menu berdasarkan nama toko
SELECT m.nama_menu, m.harga, t.nama AS nama_toko
FROM Menu m
JOIN Toko t ON m.id_toko = t.id_toko
WHERE t.nama ILIKE '%Kantin Pusat%';

-- 2. Searching: Cari pesanan pelanggan berdasarkan departemen
SELECT p.id_pesanan, pl.nama, d.nama_departemen, p.total_bayar
FROM Pesanan p
JOIN Pelanggan pl ON p.id_pelanggan = pl.id_pelanggan
JOIN Departemen d ON pl.id_departemen = d.id_departemen
WHERE d.nama_departemen = 'Teknik Informatika';

-- 3. View: Daftar Toko dan Lokasinya
CREATE VIEW v_daftar_toko_kantin AS
SELECT t.id_toko, t.nama AS nama_toko, k.nama_kantin, k.lokasi
FROM Toko t
JOIN Kantin k ON t.id_kantin = k.id_kantin;

-- 4. View: Menu Terlaris
CREATE VIEW v_menu_terlaris AS
SELECT m.nama_menu, SUM(pm.quantity) as total_terjual
FROM Pesanan_Menu pm
JOIN Menu m ON pm.id_menu = m.id_menu
GROUP BY m.id_menu, m.nama_menu
ORDER BY total_terjual DESC
LIMIT 5;

-- 5. Trigger: Kurangi Stok
CREATE OR REPLACE FUNCTION fn_tr_kurangi_stok() RETURNS TRIGGER AS $$
BEGIN
    UPDATE Menu SET stok = stok - NEW.quantity WHERE id_menu = NEW.id_menu;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_kurangi_stok
AFTER INSERT ON Pesanan_Menu
FOR EACH ROW EXECUTE FUNCTION fn_tr_kurangi_stok();

-- 6. Trigger: Kembalikan Stok (Jika batal)
CREATE OR REPLACE FUNCTION fn_tr_kembalikan_stok() RETURNS TRIGGER AS $$
BEGIN
    UPDATE Menu SET stok = stok + OLD.quantity WHERE id_menu = OLD.id_menu;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_kembalikan_stok
AFTER DELETE ON Pesanan_Menu
FOR EACH ROW EXECUTE FUNCTION fn_tr_kembalikan_stok();

-- 7. Function: Hitung Total Item dalam satu pesanan
CREATE OR REPLACE FUNCTION fn_hitung_total_item(p_id_pesanan INT) RETURNS INT AS $$
DECLARE
    v_total INT;
BEGIN
    SELECT SUM(quantity) INTO v_total FROM Pesanan_Menu WHERE id_pesanan = p_id_pesanan;
    RETURN COALESCE(v_total, 0);
END;
$$ LANGUAGE plpgsql;

-- 8. Procedure: Update Status Pesanan
CREATE OR REPLACE PROCEDURE sp_update_status_pesanan(p_id_pesanan INT, p_status VARCHAR) AS $$
BEGIN
    UPDATE Pesanan SET status_pesanan = p_status WHERE id_pesanan = p_id_pesanan;
END;
$$ LANGUAGE plpgsql;


-- ------------------------------------------
-- ANGGOTA 2
-- ------------------------------------------

-- 9. Searching: Cari toko di lokasi kantin tertentu
SELECT t.nama, t.waktu_buka, k.lokasi
FROM Toko t
JOIN Kantin k ON t.id_kantin = k.id_kantin
WHERE k.lokasi = 'Gedung Perpustakaan';

-- 10. Searching: Detail menu dalam satu pesanan
SELECT m.nama_menu, pm.quantity, pm.sub_total_bayar
FROM Pesanan_Menu pm
JOIN Menu m ON pm.id_menu = m.id_menu
WHERE pm.id_pesanan = 101;

-- 11. View: Rekap Pendapatan per Toko
CREATE VIEW v_rekap_pendapatan_toko AS
SELECT t.nama, SUM(p.total_bayar) as pendapatan_total
FROM Pesanan p
JOIN Toko t ON p.id_toko = t.id_toko
WHERE p.status_pembayaran = 'Lunas'
GROUP BY t.id_toko, t.nama;

-- 12. View: Pelanggan Aktif (> 5 pesanan)
CREATE VIEW v_pelanggan_aktif AS
SELECT pl.nama, COUNT(p.id_pesanan) as jumlah_pesanan
FROM Pelanggan pl
JOIN Pesanan p ON pl.id_pelanggan = p.id_pelanggan
GROUP BY pl.id_pelanggan, pl.nama
HAVING COUNT(p.id_pesanan) > 5;

-- 13. Trigger: Auto Update Total Bayar di tabel Pesanan
CREATE OR REPLACE FUNCTION fn_tr_update_total_bayar() RETURNS TRIGGER AS $$
BEGIN
    UPDATE Pesanan 
    SET total_bayar = (SELECT SUM(sub_total_bayar) FROM Pesanan_Menu WHERE id_pesanan = NEW.id_pesanan)
    WHERE id_pesanan = NEW.id_pesanan;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_total_bayar
AFTER INSERT OR UPDATE ON Pesanan_Menu
FOR EACH ROW EXECUTE FUNCTION fn_tr_update_total_bayar();

-- 14. Trigger: Cegah Harga Negatif
CREATE OR REPLACE FUNCTION fn_tr_validasi_harga() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.harga < 0 THEN
        RAISE EXCEPTION 'Harga tidak boleh negatif';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_validasi_harga
BEFORE INSERT OR UPDATE ON Menu
FOR EACH ROW EXECUTE FUNCTION fn_tr_validasi_harga();

-- 15. Function: Cek Stok Tersedia
CREATE OR REPLACE FUNCTION fn_cek_stok_tersedia(p_id_menu VARCHAR, p_qty INT) RETURNS BOOLEAN AS $$
DECLARE
    v_stok INT;
BEGIN
    SELECT stok INTO v_stok FROM Menu WHERE id_menu = p_id_menu;
    RETURN v_stok >= p_qty;
END;
$$ LANGUAGE plpgsql;

-- 16. Procedure: Tambah Menu Baru
CREATE OR REPLACE PROCEDURE sp_tambah_menu_baru(p_id VARCHAR, p_nama VARCHAR, p_harga NUMERIC, p_stok INT, p_toko INT) AS $$
BEGIN
    INSERT INTO Menu (id_menu, nama_menu, harga, stok, id_toko)
    VALUES (p_id, p_nama, p_harga, p_stok, p_toko);
END;
$$ LANGUAGE plpgsql;


-- ------------------------------------------
-- ANGGOTA 3
-- ------------------------------------------

-- 17. Searching: Pelanggan di toko X pada tanggal Y
SELECT DISTINCT pl.nama
FROM Pelanggan pl
JOIN Pesanan p ON pl.id_pelanggan = p.id_pelanggan
WHERE p.id_toko = 1 AND p.waktu_pesan::DATE = '2023-10-27';

-- 18. Searching: Menu di bawah 15.000
SELECT m.nama_menu, m.harga, t.nama as nama_toko
FROM Menu m
JOIN Toko t ON m.id_toko = t.id_toko
WHERE m.harga < 15000;

-- 19. View: Antrean Pesanan Aktif
CREATE VIEW v_antrean_pesanan AS
SELECT p.id_pesanan, pl.nama as pelanggan, t.nama as toko, p.status_pesanan
FROM Pesanan p
JOIN Pelanggan pl ON p.id_pelanggan = pl.id_pelanggan
JOIN Toko t ON p.id_toko = t.id_toko
WHERE p.status_pesanan IN ('Menunggu', 'Diproses');

-- 20. View: Distribusi Pelanggan per Departemen
CREATE VIEW v_distribusi_pelanggan_dept AS
SELECT d.nama_departemen, COUNT(pl.id_pelanggan) as jumlah_mhs
FROM Departemen d
LEFT JOIN Pelanggan pl ON d.id_departemen = pl.id_departemen
GROUP BY d.id_departemen, d.nama_departemen;

-- 21. Trigger: Validasi Jam Operasional Toko
CREATE OR REPLACE FUNCTION fn_tr_cek_jam_toko() RETURNS TRIGGER AS $$
DECLARE
    v_buka TIME;
    v_tutup TIME;
    v_sekarang TIME := CURRENT_TIME;
BEGIN
    SELECT waktu_buka, waktu_tutup INTO v_buka, v_tutup FROM Toko WHERE id_toko = NEW.id_toko;
    IF v_sekarang < v_buka OR v_sekarang > v_tutup THEN
        RAISE EXCEPTION 'Toko sudah tutup atau belum buka';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_cek_jam_toko
BEFORE INSERT ON Pesanan
FOR EACH ROW EXECUTE FUNCTION fn_tr_cek_jam_toko();

-- 22. Trigger: Cegah Hapus Departemen Jika Ada Mahasiswa
CREATE OR REPLACE FUNCTION fn_tr_cegah_hapus_dept() RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM Pelanggan WHERE id_departemen = OLD.id_departemen) THEN
        RAISE EXCEPTION 'Tidak bisa menghapus departemen yang masih memiliki anggota';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_cegah_hapus_dept
BEFORE DELETE ON Departemen
FOR EACH ROW EXECUTE FUNCTION fn_tr_cegah_hapus_dept();

-- 23. Function: Ambil Nama Kantin dari Toko
CREATE OR REPLACE FUNCTION fn_get_nama_kantin(p_id_toko INT) RETURNS VARCHAR AS $$
DECLARE
    v_nama VARCHAR;
BEGIN
    SELECT k.nama_kantin INTO v_nama 
    FROM Kantin k JOIN Toko t ON k.id_kantin = t.id_kantin 
    WHERE t.id_toko = p_id_toko;
    RETURN v_nama;
END;
$$ LANGUAGE plpgsql;

-- 24. Procedure: Hapus Pesanan Lama (Cleanup)
CREATE OR REPLACE PROCEDURE sp_hapus_pesanan_lama() AS $$
BEGIN
    DELETE FROM Pesanan WHERE waktu_pesan < CURRENT_DATE - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;


-- ------------------------------------------
-- ANGGOTA 4
-- ------------------------------------------

-- 25. Searching: Total belanja pelanggan X di semua toko
SELECT pl.nama, SUM(p.total_bayar) as total_pengeluaran
FROM Pelanggan pl
JOIN Pesanan p ON pl.id_pelanggan = p.id_pelanggan
WHERE pl.id_pelanggan = '5025211044'
GROUP BY pl.nama;

-- 26. Searching: Departemen yang pernah makan di Kantin Pusat
SELECT DISTINCT d.nama_departemen
FROM Departemen d
JOIN Pelanggan pl ON d.id_departemen = pl.id_departemen
JOIN Pesanan p ON pl.id_pelanggan = p.id_pelanggan
JOIN Toko t ON p.id_toko = t.id_toko
JOIN Kantin k ON t.id_kantin = k.id_kantin
WHERE k.nama_kantin = 'Kantin Pusat';

-- 27. View: Toko Terpopuler
CREATE VIEW v_toko_terpopuler AS
SELECT t.nama, COUNT(p.id_pesanan) as jumlah_transaksi
FROM Toko t
JOIN Pesanan p ON t.id_toko = p.id_toko
GROUP BY t.id_toko, t.nama
ORDER BY jumlah_transaksi DESC;

-- 28. View: Rata-rata Belanja Pelanggan
CREATE VIEW v_rata_rata_belanja AS
SELECT AVG(total_bayar) as rata_rata_transaksi FROM Pesanan;

-- 29. Trigger: Catatan Default
CREATE OR REPLACE FUNCTION fn_tr_catatan_default() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.catatan IS NULL OR NEW.catatan = '' THEN
        NEW.catatan := 'Tanpa alat makan';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_catatan_default
BEFORE INSERT ON Pesanan
FOR EACH ROW EXECUTE FUNCTION fn_tr_catatan_default();

-- 30. Trigger: Cegah Update Stok Negatif
CREATE OR REPLACE FUNCTION fn_tr_cegah_stok_negatif() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.stok < 0 THEN
        RAISE EXCEPTION 'Stok tidak boleh kurang dari nol';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_cegah_stok_negatif
BEFORE UPDATE OF stok ON Menu
FOR EACH ROW EXECUTE FUNCTION fn_tr_cegah_stok_negatif();

-- 31. Function: Total Omzet Hari Ini
CREATE OR REPLACE FUNCTION fn_total_omzet_hari_ini() RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT SUM(total_bayar) INTO v_total FROM Pesanan WHERE waktu_pesan::DATE = CURRENT_DATE;
    RETURN COALESCE(v_total, 0);
END;
$$ LANGUAGE plpgsql;

-- 32. Procedure: Tutup Semua Toko di Kantin X
CREATE OR REPLACE PROCEDURE sp_tutup_kantin(p_id_kantin INT) AS $$
BEGIN
    UPDATE Toko SET is_open = FALSE WHERE id_kantin = p_id_kantin;
END;
$$ LANGUAGE plpgsql;


-- ------------------------------------------
-- ANGGOTA 5
-- ------------------------------------------

-- 33. Searching: Pesanan Tunai di Toko Tertentu
SELECT id_pesanan, total_bayar, waktu_pesan
FROM Pesanan
WHERE metode_pembayaran = 'Tunai' AND id_toko = 2;

-- 34. Searching: Pelanggan yang membeli menu 'Nasi Goreng'
SELECT DISTINCT pl.nama, pl.email
FROM Pelanggan pl
JOIN Pesanan p ON pl.id_pelanggan = p.id_pelanggan
JOIN Pesanan_Menu pm ON p.id_pesanan = pm.id_pesanan
JOIN Menu m ON pm.id_menu = m.id_menu
WHERE m.nama_menu ILIKE '%Nasi Goreng%';

-- 35. View: Daftar Menu Habis
CREATE VIEW v_menu_habis AS
SELECT m.nama_menu, t.nama as toko
FROM Menu m
JOIN Toko t ON m.id_toko = t.id_toko
WHERE m.stok = 0;

-- 36. View: Riwayat Pembayaran QRIS
CREATE VIEW v_riwayat_qris AS
SELECT p.id_pesanan, pl.nama, p.total_bayar, p.waktu_pesan
FROM Pesanan p
JOIN Pelanggan pl ON p.id_pelanggan = pl.id_pelanggan
WHERE p.metode_pembayaran = 'QRIS';

-- 37. Trigger: Update Waktu Saat Selesai
CREATE OR REPLACE FUNCTION fn_tr_waktu_selesai() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status_pesanan = 'Selesai' AND OLD.status_pesanan <> 'Selesai' THEN
        -- Simulasi update metadata atau log
        RAISE NOTICE 'Pesanan % telah selesai pada %', NEW.id_pesanan, CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_waktu_selesai
AFTER UPDATE ON Pesanan
FOR EACH ROW EXECUTE FUNCTION fn_tr_waktu_selesai();

-- 38. Trigger: Notifikasi Stok Menipis
CREATE OR REPLACE FUNCTION fn_tr_notif_stok() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.stok < 5 THEN
        RAISE NOTICE 'Peringatan: Stok menu % sisa %', NEW.nama_menu, NEW.stok;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_notif_stok
AFTER UPDATE OF stok ON Menu
FOR EACH ROW EXECUTE FUNCTION fn_tr_notif_stok();

-- 39. Function: Cek Berapa Jam Toko Buka
CREATE OR REPLACE FUNCTION fn_durasi_buka(p_id_toko INT) RETURNS INTERVAL AS $$
DECLARE
    v_buka TIME;
    v_tutup TIME;
BEGIN
    SELECT waktu_buka, waktu_tutup INTO v_buka, v_tutup FROM Toko WHERE id_toko = p_id_toko;
    RETURN v_tutup - v_buka;
END;
$$ LANGUAGE plpgsql;

-- 40. Procedure: Ganti No HP Pelanggan
CREATE OR REPLACE PROCEDURE sp_update_nohp(p_id VARCHAR, p_baru VARCHAR) AS $$
BEGIN
    UPDATE Pelanggan SET no_hp = p_baru WHERE id_pelanggan = p_id;
END;
$$ LANGUAGE plpgsql;
