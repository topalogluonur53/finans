import yfinance as yf
from decimal import Decimal
from .models import MarketData
import logging

logger = logging.getLogger(__name__)

def update_market_from_yahoo():
    """
    Yahoo Finance üzerinden zenginleştirilmiş piyasa verilerini çeker.
    Emtia, Borsa ve Döviz verilerini günceller.
    """
    
    # Kategori ve Sembol Konfigürasyonu
    market_config = {
        'commodity': {
            'GC=F': 'Altın (Ons)',
            'SI=F': 'Gümüş (Ons)',
            'PL=F': 'Platin (Ons)',
            'PA=F': 'Paladyum (Ons)',
            'BZ=F': 'Brent Petrol',
            'CL=F': 'WTI Petrol',
            'NG=F': 'Doğalgaz',
            'HG=F': 'Bakır'
        },
        'index': {
            'XU100.IS': 'BIST 100',
            '^GSPC': 'S&P 500',
            '^IXIC': 'NASDAQ',
            '^DJI': 'Dow Jones',
            '^FTSE': 'FTSE 100',
            '^GDAXI': 'DAX Performance'
        },
        'currency': {
            'USDTRY=X': 'Dolar/TL',
            'EURTRY=X': 'Euro/TL',
            'EURUSD=X': 'Euro/Dolar',
            'GBPUSD=X': 'Sterlin/Dolar',
            'GBPTRY=X': 'Sterlin/TL',
            'JPYTRY=X': 'Yen/TL',
            'CHFTRY=X': 'İsviçre Frangı/TL'
        }
    }

    # Endeks Bileşenleri (Örnek Temsili Liste - Yahoo bazen tüm listeyi vermez, popüler olanları ekliyoruz)
    index_constituents = {
        'XU100.IS': [
            'THYAO.IS', 'ASELS.IS', 'EREGL.IS', 'AKBNK.IS', 'GARAN.IS', 
            'ISCTR.IS', 'SISE.IS', 'KCHOL.IS', 'SAHOL.IS', 'TUPRS.IS',
            'BIMAS.IS', 'YKBNK.IS', 'ARCLK.IS', 'FROTO.IS', 'TOASO.IS'
        ],
        '^GSPC': [
            'AAPL', 'MSFT', 'AMZN', 'NVDA', 'GOOGL', 'META', 'TSLA'
        ]
    }

    # Tüm sembolleri tek seferde çekmek için bir liste hazırlayalım
    all_tickers_map = {}
    for m_type, symbols in market_config.items():
        for sym, name in symbols.items():
            # Sadece endeksler için is_index=True
            is_idx = (m_type == 'index')
            all_tickers_map[sym] = (name, m_type, is_idx)

    for idx_sym, constituents in index_constituents.items():
        for c_sym in constituents:
            if c_sym not in all_tickers_map:
                all_tickers_map[c_sym] = (c_sym.replace('.IS', ''), 'stock', False)

    for ticker_symbol, (display_name, m_type, is_index) in all_tickers_map.items():
        try:
            ticker = yf.Ticker(ticker_symbol)
            history = ticker.history(period='5d')
            
            if history.empty:
                logger.warning(f"Veri alınamadı: {ticker_symbol}")
                continue

            current_row = history.iloc[-1]
            prev_row = history.iloc[-2] if len(history) > 1 else current_row
            
            current_price = current_row['Close']
            price_diff = current_price - prev_row['Close']
            change_percent = (price_diff / prev_row['Close'] * 100) if prev_row['Close'] != 0 else 0
            
            parent = None
            for idx_sym, constituents in index_constituents.items():
                if ticker_symbol in constituents:
                    parent = idx_sym
                    break

            MarketData.objects.update_or_create(
                symbol=ticker_symbol,
                defaults={
                    'name': display_name,
                    'price': Decimal(str(current_price)).quantize(Decimal('0.0001')),
                    'price_change_24h': Decimal(str(price_diff)).quantize(Decimal('0.0001')),
                    'change_percent_24h': Decimal(str(change_percent)).quantize(Decimal('0.01')),
                    'market_type': 'stock' if m_type == 'index' else m_type, # Modelde 'index' yok, stock'a haritalıyoruz ama is_index set ediyoruz
                    'is_index': is_index,
                    'parent_symbol': parent,
                    'open_price': Decimal(str(current_row['Open'])).quantize(Decimal('0.0001')),
                    'day_high': Decimal(str(current_row['High'])).quantize(Decimal('0.0001')),
                    'day_low': Decimal(str(current_row['Low'])).quantize(Decimal('0.0001')),
                    'volume': int(current_row['Volume']) if 'Volume' in current_row else 0
                }
            )
        except Exception as e:
            logger.error(f"Hata oluştu ({ticker_symbol}): {str(e)}")

    # Değerli Metaller ve Altın Türevleri Hesaplaması
    calculate_precious_metals_derivatives()

def calculate_precious_metals_derivatives():
    """
    Altın, Gümüş, Platin ve Paladyum türevlerini hesaplar.
    """
    try:
        gold_ons = MarketData.objects.get(symbol='GC=F').price
        silver_ons = MarketData.objects.get(symbol='SI=F').price
        platinum_ons = MarketData.objects.get(symbol='PL=F').price
        palladium_ons = MarketData.objects.get(symbol='PA=F').price
        usd_try = MarketData.objects.get(symbol='USDTRY=X').price
        
        # Gram Hesaplamaları (Ons / 31.1035 * USD/TRY)
        ons_to_gram = Decimal('31.1035')
        gold_gram = (gold_ons / ons_to_gram) * usd_try
        silver_gram = (silver_ons / ons_to_gram) * usd_try
        platinum_gram = (platinum_ons / ons_to_gram) * usd_try
        palladium_gram = (palladium_ons / ons_to_gram) * usd_try
        
        metals = [
            ('GRAM-ALTIN', 'Gram Altın', gold_gram, 'GC=F'),
            ('GRAM-GUMUS', 'Gram Gümüş', silver_gram, 'SI=F'),
            ('GRAM-PLATIN', 'Gram Platin', platinum_gram, 'PL=F'),
            ('GRAM-PALADYUM', 'Gram Paladyum', palladium_gram, 'PA=F'),
            # Altın Türevleri
            ('CEYREK-ALTIN', 'Çeyrek Altın', gold_gram * Decimal('1.75') * Decimal('0.916'), 'GC=F'), # 22 ayar kabuluyle approx
            ('YARIM-ALTIN', 'Yarım Altın', gold_gram * Decimal('3.50') * Decimal('0.916'), 'GC=F'),
            ('TAM-ALTIN', 'Tam Altın', gold_gram * Decimal('7.02') * Decimal('0.916'), 'GC=F'),
            ('CUMHURIYET-ALTIN', 'Cumhuriyet Altını', gold_gram * Decimal('7.21') * Decimal('0.916'), 'GC=F'),
            ('22-AYAR-BILEZIK', '22 Ayar Bilezik (gr)', gold_gram * Decimal('0.916'), 'GC=F'),
        ]
        
        for sym, name, price, base_sym in metals:
            base_data = MarketData.objects.get(symbol=base_sym)
            MarketData.objects.update_or_create(
                symbol=sym,
                defaults={
                    'name': name,
                    'price': price.quantize(Decimal('0.01')),
                    'market_type': 'commodity',
                    'parent_symbol': base_sym,
                    'change_percent_24h': base_data.change_percent_24h
                }
            )
            
        # Altın/Gümüş Rasyosu (Gold/Silver Ratio)
        if silver_ons > Decimal('0'):
            ratio = gold_ons / silver_ons
            base_data_gold = MarketData.objects.get(symbol='GC=F')
            MarketData.objects.update_or_create(
                symbol='XAUXAG',
                defaults={
                    'name': 'Altın/Gümüş Rasyosu',
                    'price': ratio.quantize(Decimal('0.0001')),
                    'market_type': 'commodity',
                    'parent_symbol': None,
                    'change_percent_24h': base_data_gold.change_percent_24h # Just an approximation or keeping it
                }
            )
            
    except Exception as e:
        logger.error(f"Metal türevleri hesaplanamadı: {str(e)}")
