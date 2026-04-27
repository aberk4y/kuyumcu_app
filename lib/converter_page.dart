import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'app_theme.dart';
import 'currency_model.dart';
import 'number_utils.dart';
import 'price_model.dart';

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

enum _ConverterMode { currency, gold }

class _ConverterPageState extends State<ConverterPage> {
  final TextEditingController _amountController = TextEditingController(
    text: '1',
  );

  List<Price> _prices = const [];
  List<Currency> _currencies = const [];
  bool _loading = true;
  String? _errorMessage;
  _ConverterMode _mode = _ConverterMode.currency;

  String _sourceCurrency = 'USD';
  String _targetCurrency = 'TRY';
  String _sourceGold = 'GRAM ALTIN';
  String _targetGold = 'TRY';
  bool _currencyToTry = true;
  double _result = 0;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_recalculate);
    _loadData();
  }

  @override
  void dispose() {
    _amountController
      ..removeListener(_recalculate)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

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
      });

      _ensureDefaults();
      _recalculate();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage = 'Çevirici verileri şu anda yüklenemiyor.';
      });
    }
  }

  void _ensureDefaults() {
    if (_prices.isNotEmpty &&
        !_prices.any((price) => price.name == _sourceGold)) {
      _sourceGold = _prices.first.name;
    }

    if (_mode == _ConverterMode.currency) {
      if (_currencyToTry) {
        _targetCurrency = 'TRY';
        if (_sourceCurrency == 'TRY') {
          _sourceCurrency = 'USD';
        }
      } else {
        _sourceCurrency = 'TRY';
        if (_targetCurrency == 'TRY') {
          _targetCurrency = 'USD';
        }
      }
    }
  }

  void _recalculate() {
    final amount = parseNumericValue(_amountController.text);
    final result = _mode == _ConverterMode.currency
        ? _calculateCurrency(amount, _sourceCurrency, _targetCurrency)
        : _calculateGold(amount, _sourceGold, _targetGold);

    if (mounted) {
      setState(() => _result = result);
    }
  }

  double _calculateCurrency(double amount, String source, String target) {
    final sourceRate = _currencyRate(source);
    final targetRate = _currencyRate(target);

    if (sourceRate == 0 || targetRate == 0) {
      return 0;
    }

    final inTry = amount * sourceRate;
    return inTry / targetRate;
  }

  double _calculateGold(double amount, String source, String target) {
    final gold = _prices.cast<Price?>().firstWhere(
      (price) => price?.name == source,
      orElse: () => null,
    );

    if (gold == null) {
      return 0;
    }

    final inTry = amount * gold.sellWithMarginValue;
    final targetRate = _currencyRate(target);
    if (targetRate == 0) {
      return 0;
    }

    return inTry / targetRate;
  }

  double _currencyRate(String code) {
    if (code == 'TRY') {
      return 1;
    }

    final match = _currencies.cast<Currency?>().firstWhere(
      (currency) => currency?.code == code,
      orElse: () => null,
    );

    return match?.sellValue ?? 0;
  }

  String get _sourceCode => _mode == _ConverterMode.currency
      ? _sourceCurrency
      : _shortGoldCode(_sourceGold);

  String get _targetCode =>
      _mode == _ConverterMode.currency ? _targetCurrency : _targetGold;

  String get _sourceLabel =>
      _mode == _ConverterMode.currency ? 'Kaynak' : _goldLabel(_sourceGold);

  String get _targetLabel =>
      _mode == _ConverterMode.currency ? 'Hedef' : _currencyLabel(_targetGold);

  double get _currentRate {
    if (_mode == _ConverterMode.currency) {
      return _calculateCurrency(1, _sourceCurrency, _targetCurrency);
    }

    return _calculateGold(1, _sourceGold, _targetGold);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            const _ConverterHeader(),
            Transform.translate(
              offset: const Offset(0, -8),
              child: _SegmentSwitcher(
                currentMode: _mode,
                onModeChanged: (mode) {
                  setState(() => _mode = mode);
                  _recalculate();
                },
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CupertinoActivityIndicator(radius: 16))
                  : _errorMessage != null
                  ? _ConverterErrorState(
                      message: _errorMessage!,
                      onRetry: _loadData,
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      child: Column(
                        children: [
                          _SelectorPanel(
                            sourceCode: _sourceCode,
                            targetCode: _targetCode,
                            mode: _mode,
                            onSourceTap: _pickSource,
                            onTargetTap: _pickTarget,
                            onSwap: _swapSelection,
                          ),
                          const SizedBox(height: 26),
                          Text(
                            formatTurkishNumber(
                              _currentRate,
                              minDecimals: 2,
                              maxDecimals: _mode == _ConverterMode.currency
                                  ? 4
                                  : 2,
                            ),
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w300,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '1 $_sourceCode = ${formatTurkishNumber(_currentRate, minDecimals: 2, maxDecimals: _mode == _ConverterMode.currency ? 4 : 2)} $_targetCode',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 26),
                          Row(
                            children: [
                              Expanded(
                                child: _InputCard(
                                  code: _sourceCode,
                                  controller: _amountController,
                                  editable: true,
                                  icon: CupertinoIcons.pencil_outline,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _InputCard(
                                  code: _targetCode,
                                  valueText: formatTurkishNumber(
                                    _result,
                                    minDecimals: 2,
                                    maxDecimals:
                                        _mode == _ConverterMode.currency
                                        ? 4
                                        : 2,
                                  ),
                                  editable: false,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const _DisclaimerNote(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSource() async {
    if (_mode == _ConverterMode.currency) {
      final selected = await _showPickerSheet(
        title: 'Kaynak döviz',
        options: _currencies
            .map(
              (currency) => _PickerOption(
                code: currency.code,
                label: currency.displayName,
              ),
            )
            .toList(),
        currentCode: _sourceCurrency,
      );

      if (selected != null && mounted) {
        setState(() => _sourceCurrency = selected);
        _recalculate();
      }
      return;
    }

    final selected = await _showPickerSheet(
      title: 'Kaynak altın',
      options: _prices
          .map(
            (price) =>
                _PickerOption(code: price.name, label: _goldLabel(price.name)),
          )
          .toList(),
      currentCode: _sourceGold,
    );

    if (selected != null && mounted) {
      setState(() => _sourceGold = selected);
      _recalculate();
    }
  }

  Future<void> _pickTarget() async {
    final options = _mode == _ConverterMode.currency
        ? _currencyToTry
              ? [const _PickerOption(code: 'TRY', label: 'Türk Lirası')]
              : _currencies
                    .map(
                      (currency) => _PickerOption(
                        code: currency.code,
                        label: currency.displayName,
                      ),
                    )
                    .toList()
        : [
            const _PickerOption(code: 'TRY', label: 'Türk Lirası'),
            ..._currencies
                .map(
                  (currency) => _PickerOption(
                    code: currency.code,
                    label: currency.displayName,
                  ),
                )
                .toList(),
          ];

    final selected = await _showPickerSheet(
      title: 'Hedef birim',
      options: options,
      currentCode: _mode == _ConverterMode.currency
          ? _targetCurrency
          : _targetGold,
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      if (_mode == _ConverterMode.currency) {
        _targetCurrency = selected;
      } else {
        _targetGold = selected;
      }
    });
    _recalculate();
  }

  void _swapSelection() {
    if (_mode == _ConverterMode.currency) {
      setState(() {
        _currencyToTry = !_currencyToTry;
        if (_currencyToTry) {
          final nextSource = _targetCurrency == 'TRY' ? 'USD' : _targetCurrency;
          _sourceCurrency = nextSource;
          _targetCurrency = 'TRY';
        } else {
          final nextTarget = _sourceCurrency == 'TRY' ? 'USD' : _sourceCurrency;
          _sourceCurrency = 'TRY';
          _targetCurrency = nextTarget;
        }
      });
    } else {
      setState(() {
        _targetGold = _targetGold == 'TRY' ? 'USD' : 'TRY';
      });
    }

    _recalculate();
  }

  Future<String?> _showPickerSheet({
    required String title,
    required List<_PickerOption> options,
    required String currentCode,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final selected = option.code == currentCode;

                      return ListTile(
                        onTap: () => Navigator.pop(context, option.code),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          option.code,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(option.label),
                        trailing: selected
                            ? const Icon(
                                CupertinoIcons.check_mark_circled_solid,
                                color: AppColors.royal,
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _currencyLabel(String code) {
    switch (code) {
      case 'USD':
        return 'Amerikan Doları';
      case 'EUR':
        return 'Avrupa Eurosu';
      case 'GBP':
        return 'İngiliz Sterlini';
      case 'TRY':
        return 'Türk Lirası';
      default:
        return code;
    }
  }

  String _goldLabel(String value) {
    return value
        .toLowerCase()
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _shortGoldCode(String value) {
    if (value == 'GRAM ALTIN') {
      return 'GRAM';
    }

    if (value == 'HAS ALTIN') {
      return 'HAS';
    }

    final parts = value.split(' ');
    return parts.first;
  }
}

class _ConverterHeader extends StatelessWidget {
  const _ConverterHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 38),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.royalDark, AppColors.royal, Color(0xFF4326D6)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Column(
        children: [
          Text(
            "ASLANOĞLU",
            style: GoogleFonts.cinzel(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: const Text(
              "Döviz & Altın Çevirici",
              style: TextStyle(
                color: Color(0xFFE7E2FF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentSwitcher extends StatelessWidget {
  const _SegmentSwitcher({
    required this.currentMode,
    required this.onModeChanged,
  });

  final _ConverterMode currentMode;
  final ValueChanged<_ConverterMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 58,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: currentMode == _ConverterMode.currency
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: MediaQuery.of(context).size.width / 2.35,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.royalDark, AppColors.royal],
                    ),
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
              ),

              Row(
                children: [
                  _buildTab(
                    label: "DÖVİZ",
                    selected: currentMode == _ConverterMode.currency,
                    onTap: () => onModeChanged(_ConverterMode.currency),
                  ),
                  _buildTab(
                    label: "ALTIN",
                    selected: currentMode == _ConverterMode.gold,
                    onTap: () => onModeChanged(_ConverterMode.gold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textMuted,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _SlidingSegmentButton extends StatelessWidget {
  const _SlidingSegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.royal : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectorPanel extends StatelessWidget {
  const _SelectorPanel({
    required this.sourceCode,
    required this.targetCode,
    required this.mode,
    required this.onSourceTap,
    required this.onTargetTap,
    required this.onSwap,
  });

  final String sourceCode;
  final String targetCode;
  final _ConverterMode mode;
  final VoidCallback onSourceTap;
  final VoidCallback onTargetTap;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModernSelectorCard(
              title: "Kaynak",
              code: sourceCode,
              onTap: onSourceTap,
            ),
          ),

          const SizedBox(width: 12),

          GestureDetector(
            onTap: onSwap,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5F1FF),
                border: Border.all(color: AppColors.royal.withOpacity(.25)),
              ),
              child: const Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.royal,
                size: 28,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: _ModernSelectorCard(
              title: "Hedef",
              code: targetCode,
              onTap: onTargetTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernSelectorCard extends StatelessWidget {
  const _ModernSelectorCard({
    required this.title,
    required this.code,
    required this.onTap,
  });

  final String title;
  final String code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 82,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE4E8F2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    code,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                const Icon(
                  CupertinoIcons.chevron_down,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.code,
    this.controller,
    this.valueText,
    required this.editable,
    this.icon,
  });

  final String code;
  final TextEditingController? controller;
  final String? valueText;
  final bool editable;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF9FAABC), width: 1.3),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: editable
                ? Row(
                    children: [
                      Icon(icon, color: AppColors.textMuted, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                    ],
                  )
                : Text(
                    valueText ?? '0',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textPrimary,
                    ),
                  ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Text(
              code,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConverterErrorState extends StatelessWidget {
  const _ConverterErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: AppColors.textMuted,
              size: 42,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
            ),
            const SizedBox(height: 16),
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
      ),
    );
  }
}

class _PickerOption {
  const _PickerOption({required this.code, required this.label});

  final String code;
  final String label;
}

class _DisclaimerNote extends StatelessWidget {
  const _DisclaimerNote();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
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
