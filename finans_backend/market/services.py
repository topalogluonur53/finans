import os
import certifi
import tempfile
import shutil

# ─────────────────────────────────────────────────────────────────────────────
# SSL FIX — Windows'ta Türkçe/Unicode karakterli kullanıcı dizinlerinde
# certifi'nin CA bundle yolu libcurl/curl_cffi tarafından okunamıyor.
# Çözüm: CURL_CA_BUNDLE ortam değişkenini ASCII yoluna yönlendir.
# Bu importlardan ÖNCE yapılmalı (yfinance yüklenirken env'i okur).
# ─────────────────────────────────────────────────────────────────────────────
def _setup_ssl_env():
    ca_bundle = certifi.where()
    try:
        ca_bundle.encode('ascii')
        # Yol ASCII — doğrudan kullan
        os.environ.setdefault('CURL_CA_BUNDLE',     ca_bundle)
        os.environ.setdefault('REQUESTS_CA_BUNDLE', ca_bundle)
        return
    except (UnicodeEncodeError, UnicodeDecodeError):
        pass

    # Unicode yol — ASCII geçici konuma kopyala
    tmp_ca = os.path.join(tempfile.gettempdir(), 'cacert_yf.pem')
    if not os.path.exists(tmp_ca):
        shutil.copy2(ca_bundle, tmp_ca)
    try:
        tmp_ca.encode('ascii')
        os.environ['CURL_CA_BUNDLE']     = tmp_ca
        os.environ['REQUESTS_CA_BUNDLE'] = tmp_ca
    except (UnicodeEncodeError, UnicodeDecodeError):
        # Tempdir de ASCII değil — doğrulamayı tamamen kapat
        os.environ['CURL_CA_BUNDLE']     = ''
        os.environ['REQUESTS_CA_BUNDLE'] = ''

_setup_ssl_env()

# ─────────────────────────────────────────────────────────────────────────────
# Normal importlar (SSL fix sonrasında)
# ─────────────────────────────────────────────────────────────────────────────
import yfinance as yf
import pandas as pd
from decimal import Decimal
from .models import MarketData
import logging

logger = logging.getLogger(__name__)

# ─────────────────────────────────────────────────────────────────────────────
# Sembol Konfigürasyonu
# ─────────────────────────────────────────────────────────────────────────────

MARKET_CONFIG = {
    'commodity': {
        'GC=F':  'Altın (Ons)',
        'SI=F':  'Gümüş (Ons)',
        'PL=F':  'Platin (Ons)',
        'PA=F':  'Paladyum (Ons)',
        'BZ=F':  'Brent Petrol',
        'CL=F':  'WTI Petrol',
        'NG=F':  'Doğalgaz',
        'HG=F':  'Bakır',
    },
    'index': {
        'XU100.IS': 'BIST 100',
        'XU050.IS': 'BIST 50',
        'XU030.IS': 'BIST 30',
        'XUTUM.IS': 'BIST Tüm',
        'XBANK.IS': 'BIST Banka',
        'XUSIN.IS': 'BIST Sınai',
        'XHIZM.IS': 'BIST Hizmetler',  # Not: Yahoo Finance'de bulunmayabilir
        'XTKJS.IS': 'BIST Teknoloji',
        'XGMYO.IS': 'BIST GMYO',
        'XHOLD.IS': 'BIST Holding ve Yatırım',
        '^GSPC':    'S&P 500',
        '^IXIC':    'NASDAQ',
        '^DJI':     'Dow Jones',
        '^FTSE':    'FTSE 100',
        '^GDAXI':   'DAX Performance',
    },
    'currency': {
        'USDTRY=X': 'Dolar/TL',
        'EURTRY=X': 'Euro/TL',
        'EURUSD=X': 'Euro/Dolar',
        'GBPUSD=X': 'Sterlin/Dolar',
        'GBPTRY=X': 'Sterlin/TL',
        'JPYTRY=X': 'Yen/TL',
        'CHFTRY=X': 'İsviçre Frangı/TL',
    },
}

# BIST 100 bileşenleri (temsili liste)
BIST100_STOCKS = [
    'AEFES.IS', 'AGHOL.IS', 'AHGAZ.IS', 'AKBNK.IS', 'AKFGY.IS',
    'AKFYE.IS', 'AKSA.IS', 'AKSEN.IS', 'ALARK.IS', 'ALBRK.IS', 'ALFAS.IS',
    'ARCLK.IS', 'ASELS.IS', 'ASTOR.IS', 'BERA.IS', 'BIMAS.IS', 'BRMEN.IS',
    'BRSAN.IS', 'BUCIM.IS', 'CANTE.IS', 'CCOLA.IS', 'CEMTS.IS', 'CIMSA.IS',
    'CWENE.IS', 'DOAS.IS', 'DOHOL.IS', 'ECILC.IS', 'ECZYT.IS', 'EGEEN.IS',
    'EKGYO.IS', 'ENJSA.IS', 'ENKAI.IS', 'EREGL.IS', 'EUPWR.IS', 'EUREN.IS',
    'FROTO.IS', 'GARAN.IS', 'GENIL.IS', 'GESAN.IS', 'GLYHO.IS', 'GUBRF.IS',
    'GWIND.IS', 'HALKB.IS', 'HEKTS.IS', 'HKTM.IS', 'HLGYO.IS',
    'ISCTR.IS', 'ISDMR.IS', 'ISFIN.IS', 'ISGYO.IS', 'ISMEN.IS', 'IZENR.IS',
    'KCHOL.IS', 'KMPUR.IS', 'KONYA.IS', 'KORDS.IS',
    'KRDMD.IS', 'KZBGY.IS', 'MAVI.IS', 'MGROS.IS', 'MIATK.IS', 'ODAS.IS',
    'OTKAR.IS', 'OYAKC.IS', 'PENTA.IS', 'PETKM.IS', 'PGSUS.IS', 'PNLSN.IS',
    'QUAGR.IS', 'SAHOL.IS', 'SASA.IS', 'SELEC.IS', 'SISE.IS', 'SKBNK.IS',
    'SMRTG.IS', 'SOKM.IS', 'TAVHL.IS', 'TCELL.IS', 'THYAO.IS', 'TKFEN.IS',
    'TOASO.IS', 'TRGYO.IS', 'TSKB.IS', 'TTKOM.IS', 'TTRAK.IS', 'TUKAS.IS',
    'TUPRS.IS', 'ULKER.IS', 'VAKBN.IS', 'VESBE.IS', 'VESTL.IS', 'YEOTK.IS',
    'YKBNK.IS', 'YYLGD.IS', 'ZOREN.IS',
]

SP500_STOCKS = ['AAPL', 'MSFT', 'AMZN', 'NVDA', 'GOOGL', 'META', 'TSLA']

INDEX_CONSTITUENTS = {
    'XU100.IS': BIST100_STOCKS,
    '^GSPC': SP500_STOCKS,
}


def _safe_decimal(value, places='0.0001'):
    """None-safe Decimal dönüşümü."""
    try:
        if value is None or (isinstance(value, float) and pd.isna(value)):
            return None
        return Decimal(str(float(value))).quantize(Decimal(places))
    except Exception:
        return None


def _bulk_download(symbols: list, period: str = '5d') -> pd.DataFrame:
    """
    yf.download ile sembolleri toplu çeker.
    SSL env workaround _setup_ssl_env() ile modül başında ayarlanmıştır.
    """
    if not symbols:
        return pd.DataFrame()
    try:
        df = yf.download(
            tickers=symbols,
            period=period,
            group_by='ticker',
            auto_adjust=True,
            progress=False,
        )
        return df
    except Exception as e:
        logger.error(f"yf.download hatası: {e}")
        return pd.DataFrame()


def _extract_price_row(df: pd.DataFrame, symbol: str):
    """
    DataFrame'den belirli sembolün son ve bir önceki kapanış fiyatını döndürür.
    Returns: (current_price, prev_price, open_, high_, low_, volume_) ya da None
    """
    if df.empty:
        return None
    try:
        if isinstance(df.columns, pd.MultiIndex):
            if symbol in df.columns.levels[0]:
                # Old/group_by='ticker' format: Level 0 = Ticker, Level 1 = Price
                sym_df = df[symbol].dropna(subset=['Close'])
            else:
                # New yfinance format: Level 0 = Price, Level 1 = Ticker
                try:
                    sym_df = df.xs(symbol, axis=1, level=1).dropna(subset=['Close'])
                except KeyError:
                    return None
        else:
            sym_df = df.dropna(subset=['Close'])

        if sym_df is None or sym_df.empty or len(sym_df) < 1:
            return None

        last = sym_df.iloc[-1]
        prev = sym_df.iloc[-2] if len(sym_df) >= 2 else last

        return (
            last['Close'],
            prev['Close'],
            last.get('Open'),
            last.get('High'),
            last.get('Low'),
            last.get('Volume'),
        )
    except KeyError:
        return None
    except Exception as e:
        logger.warning(f"_extract_price_row [{symbol}]: {e}")
        return None


def update_market_from_yahoo():
    """
    Yahoo Finance üzerinden piyasa verilerini toplu olarak çeker ve günceller.
    """

    # ── 1. Ana sembol listesini hazırla ──────────────────────────────────────
    core_symbols = {}  # symbol → (name, db_type, is_index)
    for m_type, symbols_dict in MARKET_CONFIG.items():
        for sym, name in symbols_dict.items():
            is_idx  = (m_type == 'index')
            db_type = 'stock' if m_type == 'index' else m_type
            core_symbols[sym] = (name, db_type, is_idx)

    # ── 2. Endeks bileşenlerini ekle ─────────────────────────────────────────
    constituent_symbols = {}  # symbol → parent_symbol
    for idx_sym, constituents in INDEX_CONSTITUENTS.items():
        for c_sym in constituents:
            if c_sym not in core_symbols:
                display = c_sym.replace('.IS', '')
                core_symbols[c_sym] = (display, 'stock', False)
            constituent_symbols[c_sym] = idx_sym

    all_symbols = list(core_symbols.keys())
    logger.info(f"Toplam {len(all_symbols)} sembol çekilecek.")

    # ── 3. Toplu indirme (100'lük batch'ler) ────────────────────────────────
    BATCH_SIZE = 100
    all_dfs = []
    for i in range(0, len(all_symbols), BATCH_SIZE):
        batch = all_symbols[i:i + BATCH_SIZE]
        logger.info(f"Batch {i // BATCH_SIZE + 1}: {len(batch)} sembol indiriliyor…")
        batch_df = _bulk_download(batch, period='5d')
        if not batch_df.empty:
            all_dfs.append((batch, batch_df))

    # ── 4. Her sembolü DB'ye yaz ─────────────────────────────────────────────
    updated, skipped = 0, 0
    for batch_syms, df in all_dfs:
        for sym in batch_syms:
            name, db_type, is_idx = core_symbols[sym]
            parent = constituent_symbols.get(sym)

            try:
                row = _extract_price_row(df, sym)
                if row is None:
                    logger.warning(f"Veri alınamadı: {sym}")
                    skipped += 1
                    continue

                c_price, p_price, open_, high_, low_, vol_ = row
                price_diff = c_price - p_price
                change_pct = (price_diff / p_price * 100) if p_price and p_price != 0 else 0.0

                MarketData.objects.update_or_create(
                    symbol=sym,
                    defaults={
                        'name':              name,
                        'price':             _safe_decimal(c_price) or Decimal('0'),
                        'price_change_24h':  _safe_decimal(price_diff),
                        'change_percent_24h':_safe_decimal(change_pct, '0.01'),
                        'market_type':       db_type,
                        'is_index':          is_idx,
                        'parent_symbol':     parent,
                        'open_price':        _safe_decimal(open_),
                        'day_high':          _safe_decimal(high_),
                        'day_low':           _safe_decimal(low_),
                        'volume':            int(vol_) if vol_ is not None and not pd.isna(vol_) else None,
                    }
                )
                updated += 1
            except Exception as e:
                logger.error(f"Güncelleme hatası ({sym}): {e}")
                skipped += 1

    logger.info(f"Market güncelleme tamamlandı. Güncellenen: {updated}, Atlanan: {skipped}")

    # ── 5. Değerli metal türevlerini hesapla ─────────────────────────────────
    calculate_precious_metals_derivatives()


def calculate_precious_metals_derivatives():
    """
    Altın, Gümüş, Platin ve Paladyum türevlerini güncel USDTRY kuru ile hesaplar.
    """
    try:
        def get_price(sym):
            try:
                return MarketData.objects.get(symbol=sym).price
            except MarketData.DoesNotExist:
                return None

        def get_change(sym):
            try:
                return MarketData.objects.get(symbol=sym).change_percent_24h or Decimal('0')
            except MarketData.DoesNotExist:
                return Decimal('0')

        gold_ons      = get_price('GC=F')
        silver_ons    = get_price('SI=F')
        platinum_ons  = get_price('PL=F')
        palladium_ons = get_price('PA=F')
        usd_try       = get_price('USDTRY=X')

        if not all([gold_ons, silver_ons, platinum_ons, palladium_ons, usd_try]):
            logger.warning("Metal türevleri: temel sembollerden biri bulunamadı, atlanıyor.")
            return

        ONS_TO_GRAM    = Decimal('31.1035')
        gold_gram      = (gold_ons / ONS_TO_GRAM) * usd_try
        silver_gram    = (silver_ons / ONS_TO_GRAM) * usd_try
        platinum_gram  = (platinum_ons / ONS_TO_GRAM) * usd_try
        palladium_gram = (palladium_ons / ONS_TO_GRAM) * usd_try

        metals = [
            ('GRAM-ALTIN',       'Gram Altın',           gold_gram,                                    'GC=F'),
            ('GRAM-GUMUS',       'Gram Gümüş',           silver_gram,                                  'SI=F'),
            ('GRAM-PLATIN',      'Gram Platin',          platinum_gram,                                'PL=F'),
            ('GRAM-PALADYUM',    'Gram Paladyum',        palladium_gram,                               'PA=F'),
            ('CEYREK-ALTIN',     'Çeyrek Altın',         gold_gram * Decimal('1.75') * Decimal('0.916'), 'GC=F'),
            ('YARIM-ALTIN',      'Yarım Altın',          gold_gram * Decimal('3.50') * Decimal('0.916'), 'GC=F'),
            ('TAM-ALTIN',        'Tam Altın',            gold_gram * Decimal('7.02') * Decimal('0.916'), 'GC=F'),
            ('CUMHURIYET-ALTIN', 'Cumhuriyet Altını',    gold_gram * Decimal('7.21') * Decimal('0.916'), 'GC=F'),
            ('22-AYAR-BILEZIK',  '22 Ayar Bilezik (gr)', gold_gram * Decimal('0.916'),                 'GC=F'),
        ]

        for sym, name, price, base_sym in metals:
            try:
                MarketData.objects.update_or_create(
                    symbol=sym,
                    defaults={
                        'name':               name,
                        'price':              price.quantize(Decimal('0.01')),
                        'market_type':        'commodity',
                        'parent_symbol':      base_sym,
                        'change_percent_24h': get_change(base_sym),
                    }
                )
            except Exception as e:
                logger.error(f"Metal türevi kaydedilemedi ({sym}): {e}")

        # Altın/Gümüş Rasyosu
        if silver_ons > Decimal('0'):
            try:
                ratio = gold_ons / silver_ons
                MarketData.objects.update_or_create(
                    symbol='XAUXAG',
                    defaults={
                        'name':               'Altın/Gümüş Rasyosu',
                        'price':              ratio.quantize(Decimal('0.0001')),
                        'market_type':        'commodity',
                        'parent_symbol':      None,
                        'change_percent_24h': get_change('GC=F'),
                    }
                )
            except Exception as e:
                logger.error(f"Altın/Gümüş rasyosu kaydedilemedi: {e}")

    except Exception as e:
        logger.error(f"calculate_precious_metals_derivatives genel hata: {e}")
