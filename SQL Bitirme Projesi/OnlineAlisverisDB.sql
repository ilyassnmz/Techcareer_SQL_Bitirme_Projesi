---------------------------------------------------------
-- FINAL SQL SCRIPT : Online Alışveriş Platformu
-- Bitirme Projesi
---------------------------------------------------------

-- 1) VERİTABANI OLUŞTURMA
IF DB_ID('OnlineAlisverisDB1') IS NOT NULL
    DROP DATABASE OnlineAlisverisDB1;
GO

CREATE DATABASE OnlineAlisverisDB1;
GO

USE OnlineAlisverisDB1;
GO

---------------------------------------------------------
-- 2) TABLOLAR
---------------------------------------------------------

CREATE TABLE Musteri (
    id INT IDENTITY(1,1) PRIMARY KEY,
    ad NVARCHAR(50),
    soyad NVARCHAR(50),
    email NVARCHAR(100) UNIQUE,
    sehir NVARCHAR(50),
    kayit_tarihi DATE
);

CREATE TABLE Kategori (
    id INT IDENTITY(1,1) PRIMARY KEY,
    ad NVARCHAR(50)
);

CREATE TABLE Satici (
    id INT IDENTITY(1,1) PRIMARY KEY,
    ad NVARCHAR(50),
    adres NVARCHAR(100)
);

CREATE TABLE Urun (
    id INT IDENTITY(1,1) PRIMARY KEY,
    ad NVARCHAR(100),
    fiyat DECIMAL(10,2),
    stok INT,
    kategori_id INT,
    satici_id INT,
    FOREIGN KEY (kategori_id) REFERENCES Kategori(id),
    FOREIGN KEY (satici_id) REFERENCES Satici(id)
);

CREATE TABLE Siparis (
    id INT IDENTITY(1,1) PRIMARY KEY,
    musteri_id INT,
    tarih DATE,
    toplam_tutar DECIMAL(10,2),
    odeme_turu NVARCHAR(20),
    FOREIGN KEY (musteri_id) REFERENCES Musteri(id)
);

CREATE TABLE Siparis_Detay (
    id INT IDENTITY(1,1) PRIMARY KEY,
    siparis_id INT,
    urun_id INT,
    adet INT,
    fiyat DECIMAL(10,2),
    FOREIGN KEY (siparis_id) REFERENCES Siparis(id),
    FOREIGN KEY (urun_id) REFERENCES Urun(id)
);

---------------------------------------------------------
-- 3) ÖRNEK VERİLER
---------------------------------------------------------

-- Kategoriler
INSERT INTO Kategori (ad)
VALUES ('Elektronik'), ('Giyim'), ('Ev & Yaşam');

-- Satıcılar
INSERT INTO Satici (ad, adres)
VALUES ('TechStore', 'İstanbul'),
       ('ModaDünyası', 'Ankara'),
       ('EvTrend', 'İzmir');

-- Müşteriler
INSERT INTO Musteri (ad, soyad, email, sehir, kayit_tarihi)
VALUES ('Ali', 'Kaya', 'ali@gmail.com', 'İstanbul', '2023-01-10'),
       ('Ayşe', 'Demir', 'ayse@gmail.com', 'Ankara', '2023-02-15'),
       ('Mehmet', 'Yıldız', 'mehmet@gmail.com', 'İzmir', '2023-03-20');

-- Ürünler
INSERT INTO Urun (ad, fiyat, stok, kategori_id, satici_id)
VALUES ('Laptop', 25000, 10, 1, 1),
       ('T-Shirt', 250, 50, 2, 2),
       ('Kanepe', 7500, 5, 3, 3),
       ('Kulaklık', 1200, 30, 1, 1);

-- Siparişler
INSERT INTO Siparis (musteri_id, tarih, toplam_tutar, odeme_turu)
VALUES (1, '2023-03-01', 25000, 'Kredi Kartı'),
       (2, '2023-03-10', 250, 'Nakit'),
       (3, '2023-04-05', 8700, 'Kredi Kartı');

-- Sipariş Detayları
INSERT INTO Siparis_Detay (siparis_id, urun_id, adet, fiyat)
VALUES (1, 1, 1, 25000),
       (2, 2, 1, 250),
       (3, 3, 1, 7500),
       (3, 4, 1, 1200);

---------------------------------------------------------
-- 4) UPDATE / DELETE / TRUNCATE ÖRNEKLERİ
---------------------------------------------------------

UPDATE Musteri SET sehir = 'Bursa' WHERE ad = 'Ali';

DELETE FROM Urun WHERE stok = 0;

---------------------------------------------------------
-- 5) INDEX EKLEME
---------------------------------------------------------

CREATE INDEX IX_Urun_KategoriId ON Urun(kategori_id);
CREATE INDEX IX_Urun_SaticiId ON Urun(satici_id);
CREATE INDEX IX_Siparis_MusteriId ON Siparis(musteri_id);

---------------------------------------------------------
-- 6) VIEW
---------------------------------------------------------

CREATE VIEW vw_SiparisDetayFull
AS
SELECT
    sd.id AS siparis_detay_id,
    s.id AS siparis_id,
    s.tarih,
    m.ad + ' ' + m.soyad AS musteri_adi,
    u.ad AS urun_adi,
    k.ad AS kategori_adi,
    st.ad AS satici_adi,
    sd.adet,
    sd.fiyat,
    sd.adet * sd.fiyat AS tutar,
    s.toplam_tutar,
    s.odeme_turu
FROM Siparis_Detay sd
JOIN Siparis s ON sd.siparis_id = s.id
JOIN Musteri m ON s.musteri_id = m.id
JOIN Urun u ON sd.urun_id = u.id
JOIN Kategori k ON u.kategori_id = k.id
JOIN Satici st ON u.satici_id = st.id;

---------------------------------------------------------
-- 7) STORED PROCEDURE
---------------------------------------------------------

CREATE TYPE OrderItemType AS TABLE
(
    urun_id INT,
    adet INT,
    fiyat DECIMAL(10,2)
);
GO

CREATE PROCEDURE usp_CreateOrder
    @musteri_id INT,
    @tarih DATE,
    @odeme_turu NVARCHAR(50),
    @items OrderItemType READONLY,
    @new_siparis_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;

    IF EXISTS (
        SELECT 1 FROM @items i
        JOIN Urun u ON i.urun_id = u.id
        WHERE u.stok < i.adet
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50001, 'Yetersiz stok!', 1;
    END

    INSERT INTO Siparis (musteri_id, tarih, toplam_tutar, odeme_turu)
    VALUES (@musteri_id, @tarih, 0, @odeme_turu);

    SET @new_siparis_id = SCOPE_IDENTITY();

    INSERT INTO Siparis_Detay (siparis_id, urun_id, adet, fiyat)
    SELECT @new_siparis_id, urun_id, adet, fiyat FROM @items;

    UPDATE u
    SET stok = stok - i.adet
    FROM Urun u
    JOIN @items i ON u.id = i.urun_id;

    DECLARE @toplam DECIMAL(18,2);
    SELECT @toplam = SUM(adet * fiyat) FROM Siparis_Detay WHERE siparis_id = @new_siparis_id;

    UPDATE Siparis SET toplam_tutar = @toplam WHERE id = @new_siparis_id;

    COMMIT TRANSACTION;
END;
GO

---------------------------------------------------------
-- 8) TRIGGER
---------------------------------------------------------

CREATE TRIGGER trg_SiparisDetay_AfterInsert
ON Siparis_Detay
AFTER INSERT
AS
BEGIN
    UPDATE u
    SET stok = stok - i.adet
    FROM Urun u
    JOIN inserted i ON u.id = i.urun_id;

    UPDATE s
    SET toplam_tutar = (
        SELECT SUM(adet * fiyat) FROM Siparis_Detay sd WHERE sd.siparis_id = s.id
    )
    FROM Siparis s
    JOIN inserted i ON s.id = i.siparis_id;
END;
GO

---------------------------------------------------------
-- 9) RAPORLAMA SORGULARI
---------------------------------------------------------

SELECT TOP 5 m.ad, m.soyad, COUNT(s.id) AS siparis_sayisi
FROM Musteri m
JOIN Siparis s ON m.id = s.musteri_id
GROUP BY m.ad, m.soyad
ORDER BY siparis_sayisi DESC;

SELECT u.ad, SUM(sd.adet) AS toplam_adet
FROM Urun u
JOIN Siparis_Detay sd ON u.id = sd.urun_id
GROUP BY u.ad
ORDER BY toplam_adet DESC;

SELECT st.ad, SUM(sd.adet * sd.fiyat) AS toplam_ciro
FROM Satici st
JOIN Urun u ON st.id = u.satici_id
JOIN Siparis_Detay sd ON u.id = sd.urun_id
GROUP BY st.ad
ORDER BY toplam_ciro DESC;

SELECT sehir, COUNT(*) AS musteri_sayisi
FROM Musteri
GROUP BY sehir
ORDER BY musteri_sayisi DESC;

SELECT k.ad AS kategori_adi, SUM(sd.adet * sd.fiyat) AS toplam_satis
FROM Kategori k
JOIN Urun u ON k.id = u.kategori_id
JOIN Siparis_Detay sd ON u.id = sd.urun_id
GROUP BY k.ad
ORDER BY toplam_satis DESC;

SELECT YEAR(tarih) AS yil, MONTH(tarih) AS ay, COUNT(*) AS siparis_sayisi
FROM Siparis
GROUP BY YEAR(tarih), MONTH(tarih)
ORDER BY yil, ay;

SELECT m.ad, m.soyad
FROM Musteri m
LEFT JOIN Siparis s ON m.id = s.musteri_id
WHERE s.id IS NULL;

SELECT u.ad
FROM Urun u
LEFT JOIN Siparis_Detay sd ON u.id = sd.urun_id
WHERE sd.id IS NULL;

SELECT *
FROM Siparis
WHERE toplam_tutar > (SELECT AVG(toplam_tutar) FROM Siparis);

---------------------------------------------------------
-- SON
---------------------------------------------------------
