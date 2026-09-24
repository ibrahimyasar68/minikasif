#!/usr/bin/env python3
"""Uygulamaya gömülü emoji fontunu üretir (Noto Color Emoji altkümesi).

NEDEN GÖMÜYORUZ?
Emojileri telefonun kendi fontu çiziyordu: her markada farklı görünüyorlardı
ve eski Android sürümlerinde bazıları hiç yoktu (Samsung Galaxy A7 /
Android 8'de 🧸 boş kutu çıkıyordu). Gömülü font ile emojiler her cihazda
aynı ve eksiksiz.

NEDEN ALTKÜME?
Tam Noto Color Emoji ~25 MB. Uygulamada 37 emoji kullanılıyor; yalnızca
onları alınca dosya ~50 KB'a iniyor.

KAYNAK FONT
Depoda tutulmuyor (25 MB). Google Fonts, eski bir tarayıcı kimliğine TTF
sürümünü veriyor (modern tarayıcılara woff2 verir, Flutter onu okuyamaz):

    UA="Mozilla/5.0 (Linux; U; Android 4.3; tr-tr) AppleWebKit/534.30"
    URL=$(curl -sS -H "User-Agent: $UA" \\
        "https://fonts.googleapis.com/css2?family=Noto+Color+Emoji" \\
        | grep -oE "https://[^)]+" | head -1)
    curl -sSL -H "User-Agent: $UA" "$URL" -o /tmp/NotoColorEmoji.ttf

Lisans: SIL Open Font License 1.1 (assets/fonts/NotoColorEmoji-OFL.txt).
Gömmeye izin verir; lisans metni uygulamayla birlikte gelir ve açılışta
Flutter'ın lisans listesine eklenir (lib/main.dart).

KULLANIM (proje kökünden)
    python3 tool/emoji_fontu_uret.py /tmp/NotoColorEmoji.ttf

Yeni bir emoji eklenince bu betik yeniden çalıştırılmalı; yoksa emoji
fontta olmaz. test/data/emoji_fontu_test.dart bunu yakalar.
"""
import argparse
import pathlib
import re
import subprocess
import sys
import unicodedata

KOK = pathlib.Path(__file__).resolve().parent.parent
FONT = KOK / "assets/fonts/NotoColorEmoji-subset.ttf"
KAPSAM = KOK / "test/fixtures/emoji_fontu_kapsami.txt"

# Emoji biçim seçici: "☂️" gibi yazımlarda metne karışır, fontta da bulunmalı.
BICIM_SECICI = 0xFE0F


def emoji_mi(ch: str) -> bool:
    return ord(ch) > 0x2000 and (
        unicodedata.category(ch) in ("So", "Sk") or 0x1F000 <= ord(ch) <= 0x1FAFF
    )


def kullanilan_emojiler() -> set[str]:
    """lib/ altında EKRANA ÇİZİLEN emojiler.

    Yorum satırları sayılmaz: orada geçen emoji (ör. açıklamadaki 🔊)
    kullanıcıya gösterilmiyor, fontta yer kaplamasın.
    """
    bulunan: set[str] = set()
    for dosya in sorted((KOK / "lib").rglob("*.dart")):
        for satir in dosya.read_text().splitlines():
            if satir.lstrip().startswith("//"):
                continue
            kod = re.split(r"\s//\s", satir)[0]  # satır sonu yorumunu at
            bulunan |= {ch for ch in kod if emoji_mi(ch)}
    return bulunan


def altkume_uret(kaynak: pathlib.Path, emojiler: set[str]) -> None:
    kodlar = [ord(c) for c in sorted(emojiler)] + [BICIM_SECICI]
    komut = [
        sys.executable,
        "-m",
        "fontTools.subset",
        str(kaynak),
        "--unicodes=" + ",".join(f"U+{k:04X}" for k in kodlar),
        f"--output-file={FONT}",
        # SVG tablosu ikinci bir renkli çizim biçimi; Flutter COLR'ı
        # kullanıyor. Atılmazsa dosya gereksiz yere büyür.
        "--drop-tables+=SVG",
    ]
    FONT.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(komut, check=True)


def kapsam_yaz() -> list[int]:
    """Üretilen fontun gerçekten içerdiği kod noktalarını yazar.

    Testin karşılaştırdığı liste fontun KENDİSİNDEN okunuyor; betiğin ne
    istediğinden değil. Font üretimi sessizce eksik kalırsa test yakalar.
    """
    from fontTools.ttLib import TTFont

    with TTFont(FONT, lazy=True) as f:
        kodlar = sorted({k for t in f["cmap"].tables for k in t.cmap})
    KAPSAM.parent.mkdir(parents=True, exist_ok=True)
    KAPSAM.write_text(
        "# Gömülü emoji fontunun kapsadığı kod noktaları.\n"
        "# tool/emoji_fontu_uret.py üretir; elle düzenlemeyin.\n"
        + "".join(f"{k:04X}\n" for k in kodlar)
    )
    return kodlar


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("kaynak", type=pathlib.Path, help="Noto Color Emoji .ttf")
    args = ap.parse_args()
    if not args.kaynak.exists():
        sys.exit(f"Kaynak font bulunamadı: {args.kaynak}\n{__doc__}")

    emojiler = kullanilan_emojiler()
    print(f"{len(emojiler)} emoji: {' '.join(sorted(emojiler))}")
    altkume_uret(args.kaynak, emojiler)
    kodlar = kapsam_yaz()

    eksik = [c for c in emojiler if ord(c) not in kodlar]
    if eksik:
        sys.exit(f"Bu emojiler kaynak fontta yok: {' '.join(eksik)}")
    print(
        f"{FONT.relative_to(KOK)}  {FONT.stat().st_size / 1024:.0f} KB, "
        f"{len(kodlar)} kod noktası"
    )


if __name__ == "__main__":
    main()
