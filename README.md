# Bitirme Projesi Raporu
## Projenin Amacı
Bu projede, gerçek bir e-ticaret platformunu modelleyerek müşteri, ürün, sipariş, satıcı ve kategori verilerinin SQL ile yönetilmesi hedeflenmiştir.

## Veri Tabanı Tasarımı
- **Musteri**: Müşteri bilgilerini tutar.
- **Kategori**: Ürün kategorilerini saklar.
- **Satici**: Satıcı bilgilerini içerir.
- **Urun**: Ürün detaylarını saklar (stok, fiyat, kategori, satıcı).
- **Siparis**: Müşteri siparişlerini tutar.
- **Siparis_Detay**: Siparişin içindeki ürün kalemlerini tutar.

### İlişkiler
- Bir müşteri birden fazla sipariş verebilir.
- Bir sipariş birden fazla ürün içerebilir.
- Bir ürün yalnızca bir kategoriye ve bir satıcıya bağlıdır.

## Örnek Veri
Proje kapsamında örnek müşteri, satıcı, kategori, ürün ve sipariş verileri girilmiştir.

## Uygulanan SQL Komutları
- **DDL**: CREATE TABLE, PRIMARY KEY, FOREIGN KEY, INDEX
- **DML**: INSERT, UPDATE, DELETE, TRUNCATE
- **VIEW**: Sipariş detaylarını birleştiren view
- **STORED PROCEDURE**: Sipariş ekleme, stok güncelleme
- **TRIGGER**: Sipariş detay eklendiğinde stok ve toplam güncelleme

## Raporlama Sorguları
- En çok sipariş veren 5 müşteri
- En çok satılan ürünler
- En yüksek cirolu satıcılar
- Şehirlere göre müşteri sayısı
- Kategori bazlı toplam satış
- Aylara göre sipariş sayısı
- Hiç sipariş vermemiş müşteriler
- Hiç satılmamış ürünler
- Ortalama sipariş tutarını geçen siparişler

## Karşılaşılan Sorunlar
- FOREIGN KEY tanımlarken veri tiplerinin aynı olması gerektiğine dikkat edilmiştir.
- Stok güncelleme işlemlerinde transaction kullanılarak veri tutarlılığı sağlanmıştır.
- SQL Server’a özgü komutlar (IDENTITY, GO) tercih edilmiştir.

## Sonuç
Bu proje kapsamında bir online alışveriş platformunun temel veritabanı tasarımı, veri ekleme/güncelleme işlemleri ve raporlama sorguları başarıyla uygulanmıştır.
