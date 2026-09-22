#!/usr/bin/env python3
"""MiniKasif uygulama ikonunu üretir.

Tasarım: turuncu zemin üzerinde büyüteç; merceğin içinde kırmızı bir elma
("bir şey keşfettik"), köşede küçük bir parıltı ve sağ altta "IY Labs" etiketi. İkon koddan çizildiği için
renk ya da şekil değişirse tek komutla yeniden üretilebilir; dışarıdan bir
görsel ya da paket gerekmez (sadece Pillow).

Kullanım (proje kökünden):
    python3 tool/ikon_uret.py                         # Android + design/ dosyaları
    python3 tool/ikon_uret.py --kuru --onizleme o.png # dosyalara dokunmadan önizleme

Android 8+ (API 26) "uyarlanabilir ikon" kullanır: ön plan ve arka plan ayrı
katmanlardır, telefon markası bunları daire, yuvarlak kare vb. şekillerde kırpar.
Katman 108 dp'dir; her kırpmada görünmesi garanti olan GÜVENLİ ALAN merkezdeki
66 dp çaplı dairedir. Bu betik ön planın o dairenin dışına taşmadığını ölçer.
"""
import argparse
import math
import os
import pathlib
import shutil
import sys

from PIL import Image, ImageDraw, ImageFont

KOK = pathlib.Path(__file__).resolve().parent.parent
RES = KOK / "android/app/src/main/res"
TASARIM = KOK / "design/ikon"

S = 4  # süper örnekleme: büyük çizip küçültünce kenarlar yumuşak olur

# --- Renkler (uygulamanın turuncu paletiyle uyumlu) ---
ARKA_UST = (255, 183, 77)  # #FFB74D
ARKA_ALT = (245, 124, 0)  # #F57C00
KOYU = (93, 58, 26)  # #5D3A1A  mercek çerçevesi ve sap
MERCEK = (255, 248, 225)  # #FFF8E1
ELMA = (229, 57, 53)  # #E53935
YAPRAK = (67, 160, 71)  # #43A047
SAP = (109, 76, 65)  # #6D4C41
BEYAZ = (255, 255, 255)

# --- Geometri: 108 birimlik tuval (Android uyarlanabilir ikon, dp) ---
L = (46.75, 46.75)  # mercek merkezi (sap sağ alta uzandığı için sol üstte)
R = 19.0  # mercek yarıçapı (çerçevenin ortası)
CERCEVE = 5.0
SAP_BOY = 16.0
SAP_EN = 9.0
GUVENLI_YARICAP = 33.0  # 66 dp çaplı güvenli alan

# Büyüteç grubu küçültülüp sol üste kaydırılıyor: sağ altta etikete yer açılsın.
GRUP_OLCEK = 0.84
GRUP_KAYMA = (-3.0, -3.0)

# "IY Labs" etiketi. Tam köşeye KONAMAZ: telefonların çoğu ikonu daire ya da
# yuvarlak kare şeklinde kırpar, köşeler kesilir. Güvenli dairenin içindeki en
# sağ-alt konum kullanılıyor.
ETIKET_METIN = "IY Labs"
ETIKET_MERKEZ = (62.0, 77.5)
ETIKET_EN = 24.0
ETIKET_BOY = 8.5


class Tuval:
    """108 birimlik koordinatlarla çizim; içeride size*S piksel."""

    def __init__(self, size):
        self.size = size
        self.k = size * S / 108
        self.img = Image.new("RGBA", (size * S, size * S), (0, 0, 0, 0))
        # Çizilen şekillere uygulanan ölçek ve kayma (tuval merkezine göre).
        self.olcek = 1.0
        self.kayma = (0.0, 0.0)

    def p(self, x, y):
        x = (x - 54) * self.olcek + 54 + self.kayma[0]
        y = (y - 54) * self.olcek + 54 + self.kayma[1]
        return (x * self.k, y * self.k)

    def daire(self, cx, cy, r, renk):
        d = ImageDraw.Draw(self.img)
        d.ellipse([*self.p(cx - r, cy - r), *self.p(cx + r, cy + r)], fill=renk)

    def elips(self, x0, y0, x1, y1, renk):
        ImageDraw.Draw(self.img).ellipse([*self.p(x0, y0), *self.p(x1, y1)], fill=renk)

    def cokgen(self, noktalar, renk):
        ImageDraw.Draw(self.img).polygon([self.p(x, y) for x, y in noktalar], fill=renk)

    def cizgi(self, a, b, en, renk):
        """Yuvarlak uçlu kalın çizgi."""
        (ax, ay), (bx, by) = a, b
        uz = math.hypot(bx - ax, by - ay)
        nx, ny = -(by - ay) / uz * en / 2, (bx - ax) / uz * en / 2
        self.cokgen([(ax + nx, ay + ny), (bx + nx, by + ny), (bx - nx, by - ny), (ax - nx, ay - ny)], renk)
        self.daire(ax, ay, en / 2, renk)
        self.daire(bx, by, en / 2, renk)

    def katman(self):
        """Yarı saydam şekiller için ayrı katman (alfa ile birleştirilir)."""
        k = Tuval(self.size)
        k.olcek, k.kayma = self.olcek, self.kayma
        return k

    def birlestir(self, ust):
        self.img = Image.alpha_composite(self.img, ust.img)

    def sonuc(self):
        return self.img.resize((self.size, self.size), Image.LANCZOS)


def donuk_elips(cx, cy, a, b, aci, n=40):
    t = math.radians(aci)
    return [
        (cx + a * math.cos(u) * math.cos(t) - b * math.sin(u) * math.sin(t),
         cy + a * math.cos(u) * math.sin(t) + b * math.sin(u) * math.cos(t))
        for u in (2 * math.pi * i / n for i in range(n))
    ]


def yildiz(cx, cy, dis, ic):
    """4 kollu parıltı."""
    return [
        (cx + (dis if i % 2 == 0 else ic) * math.cos(math.radians(-90 + 45 * i)),
         cy + (dis if i % 2 == 0 else ic) * math.sin(math.radians(-90 + 45 * i)))
        for i in range(8)
    ]


def on_plan(size, tek_renk=False):
    """Büyüteç + elma + parıltı, saydam zemin üzerinde.

    tek_renk: Android 13+ "temalı ikon" için beyaz siluet. Mercek içi saydam
    bırakılır ki elma çerçeveden ayrı okunsun.
    """
    t = Tuval(size)
    t.olcek, t.kayma = GRUP_OLCEK, GRUP_KAYMA
    koyu = BEYAZ if tek_renk else KOYU
    u = (math.cos(math.radians(45)), math.sin(math.radians(45)))

    # Sap (çerçeveden önce: çerçeve sapın başını örtsün)
    d0, d1 = R, R + CERCEVE / 2 + SAP_BOY
    t.cizgi((L[0] + u[0] * d0, L[1] + u[1] * d0), (L[0] + u[0] * d1, L[1] + u[1] * d1), SAP_EN, koyu)

    # Çerçeve ve mercek
    t.daire(*L, R + CERCEVE / 2, koyu)
    t.daire(*L, R - CERCEVE / 2, (0, 0, 0, 0) if tek_renk else MERCEK)
    if tek_renk:
        # Pillow saydam dolguyu "üstüne boyamaz"; iç daireyi silmek için maske.
        m = Image.new("L", t.img.size, 0)
        r = R - CERCEVE / 2
        ImageDraw.Draw(m).ellipse([*t.p(L[0] - r, L[1] - r), *t.p(L[0] + r, L[1] + r)], fill=255)
        bos = Image.new("RGBA", t.img.size, (0, 0, 0, 0))
        t.img = Image.composite(bos, t.img, m)
    else:
        # Mercek parlaması
        k = t.katman()
        ImageDraw.Draw(k.img).arc(
            [*k.p(L[0] - 12, L[1] - 12), *k.p(L[0] + 12, L[1] + 12)],
            start=200, end=250, fill=(255, 255, 255, 170), width=int(2.2 * k.k * k.olcek))
        t.birlestir(k)

    # Elma
    elma = BEYAZ if tek_renk else ELMA
    ex, ey = L[0], L[1] + 0.5
    t.daire(ex - 3.8, ey + 1.6, 7.3, elma)
    t.daire(ex + 3.8, ey + 1.6, 7.3, elma)
    t.elips(ex - 8.8, ey - 3.0, ex + 8.8, ey + 12.2, elma)
    if not tek_renk:
        t.daire(ex, ey - 6.6, 1.7, MERCEK)  # tepedeki çukur
        k = t.katman()
        k.elips(ex - 6.0, ey - 2.2, ex - 3.0, ey + 4.0, (255, 255, 255, 115))
        t.birlestir(k)
    t.cizgi((ex + 0.3, ey - 4.8), (ex + 1.5, ey - 10.3), 1.9, BEYAZ if tek_renk else SAP)
    t.cokgen(donuk_elips(ex + 5.3, ey - 9.2, 3.6, 1.7, -25), BEYAZ if tek_renk else YAPRAK)

    # Parıltı
    t.cokgen(yildiz(L[0] + 19.5, L[1] - 17.5, 5.2, 1.3), BEYAZ)
    t.daire(L[0] + 25.5, L[1] - 9.0, 1.2, BEYAZ)

    # Etiket gruptan bağımsız konumlanıyor.
    t.olcek, t.kayma = 1.0, (0.0, 0.0)
    etiket_ciz(t, tek_renk)
    return t.sonuc()


_FONT_YOLU = None


def kalin_font():
    """Uygulamanın da kullandığı Roboto Bold (Flutter SDK içinde gelir).

    Başka bir fonta sessizce düşmüyoruz: ikon her makinede aynı üretilmeli.
    """
    global _FONT_YOLU
    if _FONT_YOLU is None:
        kok = os.environ.get("FLUTTER_ROOT")
        if not kok and shutil.which("flutter"):
            kok = str(pathlib.Path(shutil.which("flutter")).resolve().parent.parent)
        yol = pathlib.Path(kok or "") / "bin/cache/artifacts/material_fonts/Roboto-Bold.ttf"
        if not kok or not yol.exists():
            sys.exit("Roboto-Bold.ttf bulunamadı: Flutter SDK kurulu mu? (FLUTTER_ROOT)")
        _FONT_YOLU = str(yol)
    return _FONT_YOLU


def etiket_ciz(t, tek_renk):
    """Koyu kapsül içinde beyaz 'IY Labs'. Temalı ikonda yazı oyulur."""
    cx, cy = ETIKET_MERKEZ
    x0, y0 = t.p(cx - ETIKET_EN / 2, cy - ETIKET_BOY / 2)
    x1, y1 = t.p(cx + ETIKET_EN / 2, cy + ETIKET_BOY / 2)
    yaricap = (y1 - y0) / 2
    ImageDraw.Draw(t.img).rounded_rectangle(
        [x0, y0, x1, y1], radius=yaricap, fill=BEYAZ if tek_renk else KOYU)

    # Yazıyı kapsüle sığacak en büyük boyutta seç.
    en_fazla_en = (x1 - x0) - 1.8 * yaricap
    en_fazla_boy = (y1 - y0) * 0.6
    boyut = int(y1 - y0)
    while True:
        font = ImageFont.truetype(kalin_font(), boyut)
        sol, ust, sag, alt = font.getbbox(ETIKET_METIN)
        if (sag - sol <= en_fazla_en and alt - ust <= en_fazla_boy) or boyut <= 4:
            break
        boyut -= 1
    tx = (x0 + x1) / 2 - (sol + sag) / 2
    ty = (y0 + y1) / 2 - (ust + alt) / 2
    if tek_renk:
        m = Image.new("L", t.img.size, 0)
        ImageDraw.Draw(m).text((tx, ty), ETIKET_METIN, font=font, fill=255)
        t.img = Image.composite(Image.new("RGBA", t.img.size, (0, 0, 0, 0)), t.img, m)
    else:
        ImageDraw.Draw(t.img).text((tx, ty), ETIKET_METIN, font=font, fill=BEYAZ)


def arka_plan(size):
    """Dikey turuncu geçiş."""
    img = Image.new("RGBA", (size, size))
    px = img.load()
    for y in range(size):
        f = y / max(size - 1, 1)
        renk = tuple(round(a + (b - a) * f) for a, b in zip(ARKA_UST, ARKA_ALT)) + (255,)
        for x in range(size):
            px[x, y] = renk
    return img


def gorunur(size):
    """Arka + ön planın görünen 72 dp'lik ortası (klasik ve mağaza ikonu için)."""
    tam = round(size * 108 / 72)
    img = Image.alpha_composite(arka_plan(tam), on_plan(tam))
    kenar = (tam - size) // 2
    return img.crop((kenar, kenar, kenar + size, kenar + size))


def maskele(img, sekil):
    n = img.size[0]
    m = Image.new("L", (n * S, n * S), 0)
    d = ImageDraw.Draw(m)
    N = n * S
    if sekil == "daire":
        d.ellipse([0, 0, N - 1, N - 1], fill=255)
    elif sekil == "yuvarlak_kare":
        d.rounded_rectangle([0, 0, N - 1, N - 1], radius=N * 0.22, fill=255)
    elif sekil == "squircle":  # Samsung One UI benzeri süperelips
        pts = []
        for i in range(360):
            a = math.radians(i)
            c, s = math.cos(a), math.sin(a)
            pts.append((N / 2 + N / 2 * math.copysign(abs(c) ** 0.5, c),
                        N / 2 + N / 2 * math.copysign(abs(s) ** 0.5, s)))
        d.polygon(pts, fill=255)
    m = m.resize((n, n), Image.LANCZOS)
    out = img.copy()
    out.putalpha(Image.composite(img.getchannel("A"), Image.new("L", (n, n), 0), m))
    return out


def guvenli_alan_kontrol():
    """Ön planın hiçbir pikseli 66 dp'lik güvenli dairenin dışına taşmamalı."""
    n = 432
    a = on_plan(n).getchannel("A").load()
    c = n / 2
    en_uzak = max(
        math.hypot(x + 0.5 - c, y + 0.5 - c)
        for y in range(n) for x in range(n) if a[x, y] > 8
    )
    birim = en_uzak / n * 108
    return birim, birim <= GUVENLI_YARICAP + 0.5


def onizleme(yol):
    font = ImageFont.load_default(size=22)
    kucuk = ImageFont.load_default(size=16)
    W, H = 1160, 700
    sayfa = Image.new("RGBA", (W, H), (250, 246, 240, 255))
    d = ImageDraw.Draw(sayfa)
    d.text((24, 16), "MiniKasif ikonu - telefon markalarinin kirpma sekilleri", fill=(40, 40, 40), font=font)
    buyuk = gorunur(216)
    for i, (ad, sekil) in enumerate([("Daire (Pixel)", "daire"), ("Squircle (Samsung)", "squircle"),
                                     ("Yuvarlak kare", "yuvarlak_kare")]):
        x = 24 + i * 250
        sayfa.alpha_composite(maskele(buyuk, sekil), (x, 60))
        d.text((x, 284), ad, fill=(70, 70, 70), font=kucuk)
    # Temalı ikon (Android 13+): tek renk siluet koyu zeminde
    x = 774
    koyu_zemin = Image.new("RGBA", (216, 216), (40, 44, 52, 255))
    mono = on_plan(324, tek_renk=True).crop((54, 54, 270, 270))
    renkli = Image.new("RGBA", mono.size, (200, 220, 255, 255))
    renkli.putalpha(mono.getchannel("A"))
    koyu_zemin.alpha_composite(renkli)
    sayfa.alpha_composite(maskele(koyu_zemin, "daire"), (x, 60))
    d.text((x, 284), "Temali ikon (Android 13+)", fill=(70, 70, 70), font=kucuk)

    d.text((24, 330), "Gercek boyutlar (ana ekranda ~48-72 px):", fill=(40, 40, 40), font=font)
    x = 24
    for zemin in [(250, 246, 240, 255), (30, 30, 34, 255)]:
        kutu = Image.new("RGBA", (520, 200), zemin)
        kx = 16
        for boy in (144, 96, 72, 48):
            kutu.alpha_composite(maskele(gorunur(boy), "daire"), (kx, 100 - boy // 2))
            kx += boy + 24
        sayfa.alpha_composite(kutu, (x, 380))
        x += 560
    d.text((24, 620), "Klasik ikon (Android 7 ve oncesi), 96 px:", fill=(40, 40, 40), font=kucuk)
    sayfa.alpha_composite(maskele(gorunur(96), "yuvarlak_kare"), (420, 590))
    sayfa.convert("RGB").save(yol)


def android_yaz():
    yogunluk = [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)]
    for ad, px in yogunluk:
        klasor = RES / f"mipmap-{ad}"
        klasor.mkdir(parents=True, exist_ok=True)
        katman = px * 108 // 48  # 108 dp katman: 108, 162, 216, 324, 432
        maskele(gorunur(px), "yuvarlak_kare").save(klasor / "ic_launcher.png", optimize=True)
        on_plan(katman).save(klasor / "ic_launcher_foreground.png", optimize=True)
        arka_plan(katman).save(klasor / "ic_launcher_background.png", optimize=True)
        on_plan(katman, tek_renk=True).save(klasor / "ic_launcher_monochrome.png", optimize=True)
    v26 = RES / "mipmap-anydpi-v26"
    v26.mkdir(exist_ok=True)
    (v26 / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<!-- Uretildi: tool/ikon_uret.py. Elle duzenlemeyin. -->\n"
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@mipmap/ic_launcher_background" />\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
        "    <!-- Android 13+ temali ikon; eski surumler yok sayar. -->\n"
        '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />\n'
        "</adaptive-icon>\n", encoding="utf-8")
    TASARIM.mkdir(parents=True, exist_ok=True)
    maskele(gorunur(1024), "yuvarlak_kare").save(TASARIM / "ikon_1024.png", optimize=True)
    gorunur(512).convert("RGB").save(TASARIM / "play_store_512.png", optimize=True)  # Play kendi kırpar


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--kuru", action="store_true", help="Android/design dosyalarına dokunma")
    ap.add_argument("--onizleme", help="önizleme sayfasını bu yola yaz")
    arg = ap.parse_args()

    birim, tamam = guvenli_alan_kontrol()
    print(f"güvenli alan: ön plan merkezden en fazla {birim:.2f} dp (sınır {GUVENLI_YARICAP}) "
          f"-> {'TAMAM' if tamam else 'TAŞIYOR'}")
    if not tamam:
        sys.exit(1)
    if arg.onizleme:
        onizleme(arg.onizleme)
        print(f"önizleme: {arg.onizleme}")
    if not arg.kuru:
        android_yaz()
        print("Android ikonları ve design/ikon dosyaları yazıldı")


if __name__ == "__main__":
    main()
