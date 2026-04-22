import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'app_theme.dart';
import 'converter_page.dart';
import 'currency_model.dart';
import 'number_utils.dart';
import 'price_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  late final List<Widget> _pages = const [
    _DashboardPage(),
    ConverterPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _MainBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _DashboardPage extends StatefulWidget {
  const _DashboardPage();

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  List<Price> _prices = const [];
  List<Currency> _currencies = const [];

  bool _isLoadingPrices = true;
  bool _isLoadingCurrencies = true;

  String? _priceError;
  String? _currencyError;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDashboard(showLoader: true);
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadDashboard(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboard({bool showLoader = false}) async {
    if (showLoader) {
      setState(() {
        _isLoadingPrices = true;
        _isLoadingCurrencies = true;
        _priceError = null;
        _currencyError = null;
      });
    }

    await Future.wait([
      _loadPrices(),
      _loadCurrencies(),
    ]);
  }

  Future<void> _loadPrices() async {
    try {
      final prices = await ApiService.fetchPrices();
      if (!mounted) {
        return;
      }

      setState(() {
        _prices = prices;
        _isLoadingPrices = false;
        _priceError = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _prices = const [];
        _isLoadingPrices = false;
        _priceError = 'Altın verileri şu anda alınamıyor.';
      });
    }
  }

  Future<void> _loadCurrencies() async {
    try {
      final currencies = await ApiService.fetchCurrencies();
      if (!mounted) {
        return;
      }

      const wanted = ['USD', 'EUR', 'GBP'];
      final filtered = currencies
          .where((currency) => wanted.contains(currency.code.toUpperCase()))
          .toList()
        ..sort((a, b) => wanted.indexOf(a.code).compareTo(wanted.indexOf(b.code)));

      setState(() {
        _currencies = filtered;
        _isLoadingCurrencies = false;
        _currencyError = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currencies = const [];
        _isLoadingCurrencies = false;
        _currencyError = 'Döviz verileri şu anda alınamıyor.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _loadDashboard,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _DashboardHeader(
                currencies: _currencies,
                isLoadingCurrencies: _isLoadingCurrencies,
                currencyError: _currencyError,
              ),
            ),
            const SliverToBoxAdapter(
              child: _MarketTableHeader(),
            ),
            if (_isLoadingPrices)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CupertinoActivityIndicator(radius: 16),
                ),
              )
            else if (_prices.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _GoldRowCard(price: _prices[index]),
                    childCount: _prices.length,
                  ),
                ),
              )
            else
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorState(
                  message: _priceError ?? 'Altın verileri şu anda alınamıyor.',
                  onRetry: _loadDashboard,
                ),
              ),
            const SliverToBoxAdapter(
              child: _DisclaimerNote(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.currencies,
    required this.isLoadingCurrencies,
    required this.currencyError,
  });

  final List<Currency> currencies;
  final bool isLoadingCurrencies;
  final String? currencyError;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.royalDark,
            AppColors.royal,
            Color(0xFF4326D6),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: const Column(
                  children: [
                    Text(
                      'ASLANOĞLU',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 6,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Alanya',
                      style: TextStyle(
                        color: Color(0xFFE7E2FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (isLoadingCurrencies)
                const SizedBox(
                  height: 92,
                  child: Center(
                    child: CupertinoActivityIndicator(
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _CurrencyTickerCard(currency: _findCurrency('USD')),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CurrencyTickerCard(currency: _findCurrency('EUR')),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CurrencyTickerCard(currency: _findCurrency('GBP')),
                    ),
                  ],
                ),
              if (currencyError != null) ...[
                const SizedBox(height: 10),
                Text(
                  currencyError!,
                  style: const TextStyle(
                    color: Color(0xFFE6E1FF),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Currency? _findCurrency(String code) {
    for (final currency in currencies) {
      if (currency.code.toUpperCase() == code) {
        return currency;
      }
    }
    return null;
  }
}

class _CurrencyTickerCard extends StatelessWidget {
  const _CurrencyTickerCard({required this.currency});

  final Currency? currency;

  @override
  Widget build(BuildContext context) {
    final hasData = currency != null;
    final spread = hasData ? currency!.sellValue - currency!.buyValue : 0.0;
    final positive = spread >= 0;

    return Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasData ? '${currency!.code}TRY' : '--',
            style: const TextStyle(
              color: Color(0xFFD5CEFF),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasData
                ? formatRawNumber(
                    currency!.sell,
                    minDecimals: 3,
                    maxDecimals: 4,
                  )
                : '--',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasData
                ? positive
                    ? '+${formatTurkishNumber(spread, minDecimals: 2, maxDecimals: 4)}'
                    : formatTurkishNumber(spread, minDecimals: 2, maxDecimals: 4)
                : 'Veri yok',
            style: TextStyle(
              color: hasData
                  ? positive
                      ? const Color(0xFF8FF3AF)
                      : const Color(0xFFFFB3B3)
                  : const Color(0xFFE6E1FF),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketTableHeader extends StatelessWidget {
  const _MarketTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE7EBF2),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: const Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              'Birim',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              'Alış',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              'Satış',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldRowCard extends StatelessWidget {
  const _GoldRowCard({required this.price});

  final Price price;

  @override
  Widget build(BuildContext context) {
    final isPositive = price.changeValue >= 0;
    final changeColor = isPositive ? AppColors.success : AppColors.danger;
    final changeLabel =
        '${isPositive ? '+' : ''}${formatTurkishNumber(price.changeValue, minDecimals: 2, maxDecimals: 2)}%';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.line),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.time,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      extractTimeLabel(price.lastUpdate),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Text(
                  changeLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatTurkishNumber(
                    price.buyWithMarginValue,
                    minDecimals: 2,
                    maxDecimals: 2,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              formatTurkishNumber(
                price.sellWithMarginValue,
                minDecimals: 2,
                maxDecimals: 2,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.wifi_exclamationmark,
            size: 42,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () {
              onRetry();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.royal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}

class _MainBottomBar extends StatelessWidget {
  const _MainBottomBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (label: 'Ana Sayfa', icon: CupertinoIcons.money_dollar_circle_fill),
      (label: 'Çevirici', icon: CupertinoIcons.arrow_2_circlepath_circle_fill),
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.line),
          ),
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = currentIndex == index;

            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: selected ? AppColors.royal : const Color(0xFFC6C9D3),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? AppColors.royal : const Color(0xFFC6C9D3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _DisclaimerNote extends StatelessWidget {
  const _DisclaimerNote();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 22),
      child: Text(
        'Uygulamada yer alan fiyatlar bilgilendirme amaçlıdır. Güncel alım-satım fiyatları mağaza içi fiyatlara göre değişiklik gösterebilir.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          height: 1.45,
        ),
      ),
    );
  }
}
