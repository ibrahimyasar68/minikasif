#!/usr/bin/env python3
"""Play Store tanıtım görselini (1024x500) üretir.

Play Console'un "Feature graphic" alanı: mağaza sayfasının en üstünde, bazı
yerleşimlerde uygulama adının ve oynat düğmesinin ARKASINDA görünür. Bu yüzden
yazı kenarlara yaklaştırılmıyor, önemli hiçbir şey köşelere konmuyor.

Renkler ve font ikon betiğinden geliyor (tool/ikon_uret.py): palet tek yerde
dursun, ikon ile tanıtım görseli birbirinden ayrı düşmesin.

Kullanım (proje kökünden):
    python3 tool/tanitim_gorseli.py
"""
import pathlib

from PIL import Image, ImageDraw, ImageFont

from ikon_uret import ARKA_ALT, ARKA_UST, KOYU, kalin_font

KOK = pathlib.Path(__file__).resolve().parent.parent
IKON = KOK / "design/ikon/ikon_1024.png"
CIKTI = KOK / "design/magaza/tanitim_1024x500.png"

EN, BOY = 1024, 500
BEYAZ = (255, 255, 255)

BASLIK = "Mini Kesif"
ALT_BASLIK = "Dinle, bak, dokun"
ACIKLAMA = "0-4 yaş için eğitici oyun"


def arka_plan():
    """İkondaki turuncu geçişin aynısı, yatay olarak."""
    im = Image.new("RGB", (EN, BOY))
    d = ImageDraw.Draw(im)
    for x in range(EN):
        o = x / (EN - 1)
        d.line(
            [(x, 0), (x, BOY)],
            fill=tuple(
                round(ust + (alt - ust) * o) for ust, alt in zip(ARKA_UST, ARKA_ALT)
            ),
        )
    return im


def main():
    im = arka_plan()
    d = ImageDraw.Draw(im)

    # Sol: ikon, beyaz bir kart üzerinde. İkonun kendi zemini de turuncu;
    # doğrudan koyarsak arka planda kaybolurdu. Kart ikonun köşe yuvarlaklığını
    # izliyor (daire kullanınca köşelerden taşıyordu).
    cap = 300
    pay = 22
    cx, cy = 210, BOY // 2
    kart = [cx - cap // 2 - pay, cy - cap // 2 - pay, cx + cap // 2 + pay, cy + cap // 2 + pay]
    d.rounded_rectangle(kart, radius=int((cap + 2 * pay) * 0.24), fill=BEYAZ)
    ikon = Image.open(IKON).convert("RGBA").resize((cap, cap), Image.LANCZOS)
    im.paste(ikon, (cx - cap // 2, cy - cap // 2), ikon)

    # Sağ: ad ve iki satır tanıtım.
    x = 400
    baslik = ImageFont.truetype(kalin_font(), 92)
    alt = ImageFont.truetype(kalin_font(), 46)
    aciklama = ImageFont.truetype(kalin_font(), 34)

    d.text((x, 150), BASLIK, font=baslik, fill=BEYAZ)
    d.text((x + 4, 262), ALT_BASLIK, font=alt, fill=KOYU)
    d.text((x + 4, 322), ACIKLAMA, font=aciklama, fill=KOYU)

    CIKTI.parent.mkdir(parents=True, exist_ok=True)
    im.save(CIKTI)
    print(f"{CIKTI.relative_to(KOK)} {im.size[0]}x{im.size[1]}")


if __name__ == "__main__":
    main()
