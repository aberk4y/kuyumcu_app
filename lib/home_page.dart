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
  int _currentIndex = 1;

  late final List<Widget> _pages = [
    const _MarketPage(marketType: _MarketType.currency),
    const _MarketPage(marketType: _MarketType.gold),
    const ConverterPage(),
    const _ComingSoonPage(
      title: 'Portföy',
      message: 'Favori ürünler ve kişisel takip modülü burada yer alacak.',
      icon: CupertinoIcons.chart_pie_fill,
    ),
    const _ComingSoonPage(
      title: 'Çarşı',
      message: 'Mağaza duyuruları ve yerel kampanyalar bu alana eklenecek.',
      icon: CupertinoIcons.bag_fill,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _HaremBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

enum _MarketType { currency, gold }

class _MarketPage extends StatefulWidget {
  const _MarketPage({required this.marketType});

  final _MarketType marketType;

  @override
  State<_MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<_MarketPage> {
  List<Price> _prices = const [];
  List<Currency> _currencies = const [];
  bool _loading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  bool get _isGoldPage => widget.marketType == _MarketType.gold;

  @override
  void initState() {
    super.initState();
    _refreshData(showLoader: true);
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshData(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshData({bool showLoader = false}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        ApiService.fetchPrices(),
        ApiService.fetchCurrencies(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _prices = results[0] as List<Price>;
        _currencies = results[1] as List<Currency>;
        _loading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage = 'Canlı veriler şu anda alınamıyor.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final marketItems = _isGoldPage ? _prices : _currencies;

    return Material(
      color: AppColors.background,
      child: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _refreshData,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _MarketHeroHeader(
                title: 'ASLANOĞLU',
                currentLabel: _isGoldPage ? 'Altın' : 'Döviz',
                currencies: _currencies,
                onRefreshTap: _refreshData,
              ),
            ),
            SliverToBoxAdapter(
              child: _MarketTableHeader(),
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CupertinoActivityIndicator(radius: 16),
                ),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorState(
                  message: _errorMessage!,
                  onRetry: _refreshData,
                ),
              )
            else if (marketItems.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (_isGoldPage) {
                        return _GoldRowCard(price: _prices[index]);
                      }

                      return _CurrencyRowCard(currency: _currencies[index]);
                    },
                    childCount: marketItems.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MarketHeroHeader extends StatelessWidget {
  const _MarketHeroHeader({
    required this.title,
    required this.currentLabel,
    required this.currencies,
    required this.onRefreshTap,
  });

  final String title;
  final String currentLabel;
  final List<Currency> currencies;
  final Future<void> Function() onRefreshTap;

  @override
  Widget build(BuildContext context) {
    final featuredTickers = currencies.take(3).toList();

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
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.line_horizontal_3,
                    color: Colors.white,
                    size: 28,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 5,
                          ),
                        ),
                        Text(
                          currentLabel,
                          style: const TextStyle(
                            color: Color(0xFFD9D4FF),
                            fontSize: 12,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      onRefreshTap();
                    },
                    icon: const Icon(
                      CupertinoIcons.bell_fill,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (featuredTickers.isEmpty)
                const SizedBox(
                  height: 82,
                  child: Center(
                    child: CupertinoActivityIndicator(
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Row(
                  children: featuredTickers
                      .map(
                        (currency) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _TickerCard(currency: currency),
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TickerCard extends StatelessWidget {
  const _TickerCard({required this.currency});

  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final spread = currency.sellValue - currency.buyValue;
    final positive = spread >= 0;

    return Container(
      height: 86,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${currency.code}TRY',
            style: const TextStyle(
              color: Color(0xFFD5CEFF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            formatRawNumber(
              currency.sell,
              minDecimals: 3,
              maxDecimals: 4,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                positive
                    ? '+${formatTurkishNumber(spread, minDecimals: 2, maxDecimals: 4)}'
                    : formatTurkishNumber(spread, minDecimals: 2, maxDecimals: 4),
                style: TextStyle(
                  color: positive ? const Color(0xFF8FF3AF) : const Color(0xFFFFB3B3),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    _MiniBar(height: 6),
                    SizedBox(width: 2),
                    _MiniBar(height: 10),
                    SizedBox(width: 2),
                    _MiniBar(height: 5),
                    SizedBox(width: 2),
                    _MiniBar(height: 11),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
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
                  _splitName(price.name),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.15,
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
            child: Text(
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
          ),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Text(
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
                const SizedBox(height: 6),
                Text(
                  '${isPositive ? '+' : ''}${formatTurkishNumber(price.changeValue, minDecimals: 2, maxDecimals: 2)}%',
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyRowCard extends StatelessWidget {
  const _CurrencyRowCard({required this.currency});

  final Currency currency;

  @override
  Widget build(BuildContext context) {
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
                  currency.code,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  currency.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              formatRawNumber(
                currency.buy,
                minDecimals: 3,
                maxDecimals: 4,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              formatRawNumber(
                currency.sell,
                minDecimals: 3,
                maxDecimals: 4,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Gösterilecek veri bulunamadı.',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  const _ComingSoonPage({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 30,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: AppColors.royal, size: 42),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HaremBottomBar extends StatelessWidget {
  const _HaremBottomBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (label: 'Döviz', icon: CupertinoIcons.money_dollar_circle_fill),
      (label: 'Altın', icon: CupertinoIcons.money_dollar_circle),
      (label: 'Çevirici', icon: CupertinoIcons.arrow_2_circlepath_circle_fill),
      (label: 'Portföy', icon: CupertinoIcons.chart_bar_square_fill),
      (label: 'Çarşı', icon: CupertinoIcons.bag_fill),
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 72,
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
                      const SizedBox(height: 5),
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

String _splitName(String value) {
  return value.replaceAll(' ', '\n');
}
