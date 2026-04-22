import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
  final TextEditingController _amountController = TextEditingController(text: '1');

  List<Price> _prices = const [];
  List<Currency> _currencies = const [];
  bool _loading = true;
  String? _errorMessage;
  _ConverterMode _mode = _ConverterMode.currency;

  String _sourceCurrency = 'USD';
  String _targetCurrency = 'TRY';
  String _sourceGold = 'GRAM ALTIN';
  String _targetGold = 'TRY';
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
    if (_prices.isNotEmpty && !_prices.any((price) => price.name == _sourceGold)) {
      _sourceGold = _prices.first.name;
    }

    if (_sourceCurrency == _targetCurrency) {
      _targetCurrency = 'TRY';
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

  String get _sourceCode =>
      _mode == _ConverterMode.currency ? _sourceCurrency : _shortGoldCode(_sourceGold);

  String get _targetCode => _mode == _ConverterMode.currency ? _targetCurrency : _targetGold;

  String get _sourceLabel =>
      _mode == _ConverterMode.currency ? _currencyLabel(_sourceCurrency) : _goldLabel(_sourceGold);

  String get _targetLabel =>
      _mode == _ConverterMode.currency ? _currencyLabel(_targetCurrency) : _currencyLabel(_targetGold);

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
            _ConverterHeader(
              onRefreshTap: _loadData,
            ),
            _SegmentSwitcher(
              currentMode: _mode,
              onModeChanged: (mode) {
                setState(() => _mode = mode);
                _recalculate();
              },
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
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                          child: Column(
                            children: [
                              _SelectorPanel(
                                sourceCode: _sourceCode,
                                sourceLabel: _sourceLabel,
                                targetCode: _targetCode,
                                targetLabel: _targetLabel,
                                onSourceTap: _pickSource,
                                onTargetTap: _pickTarget,
                                onSwap: _swapSelection,
                              ),
                              const SizedBox(height: 26),
                              Text(
                                formatTurkishNumber(
                                  _currentRate,
                                  minDecimals: 2,
                                  maxDecimals: _mode == _ConverterMode.currency ? 4 : 2,
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
                                        maxDecimals: _mode == _ConverterMode.currency ? 4 : 2,
                                      ),
                                      editable: false,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              _ConverterHint(mode: _mode),
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
        options: [
          const _PickerOption(code: 'TRY', label: 'Türk Lirası'),
          ..._currencies
              .map((currency) => _PickerOption(code: currency.code, label: currency.displayName))
              .toList(),
        ],
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
          .map((price) => _PickerOption(code: price.name, label: _goldLabel(price.name)))
          .toList(),
      currentCode: _sourceGold,
    );

    if (selected != null && mounted) {
      setState(() => _sourceGold = selected);
      _recalculate();
    }
  }

  Future<void> _pickTarget() async {
    final options = [
      const _PickerOption(code: 'TRY', label: 'Türk Lirası'),
      ..._currencies
          .map((currency) => _PickerOption(code: currency.code, label: currency.displayName))
          .toList(),
    ];

    final selected = await _showPickerSheet(
      title: 'Hedef birim',
      options: options,
      currentCode: _mode == _ConverterMode.currency ? _targetCurrency : _targetGold,
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
        final temp = _sourceCurrency;
        _sourceCurrency = _targetCurrency;
        _targetCurrency = temp;
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
                    separatorBuilder: (context, index) => const Divider(height: 1),
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
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
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
  const _ConverterHeader({required this.onRefreshTap});

  final Future<void> Function() onRefreshTap;

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
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.line_horizontal_3,
              color: Colors.white,
              size: 28,
            ),
            const Expanded(
              child: Text(
                'Çevirici',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                onRefreshTap();
              },
              icon: const Icon(
                CupertinoIcons.share,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
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
    return Container(
      height: 58,
      color: Colors.white,
      child: Row(
        children: [
          _SegmentButton(
            label: 'DÖVİZ',
            selected: currentMode == _ConverterMode.currency,
            onTap: () => onModeChanged(_ConverterMode.currency),
          ),
          _SegmentButton(
            label: 'ALTIN',
            selected: currentMode == _ConverterMode.gold,
            onTap: () => onModeChanged(_ConverterMode.gold),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.line : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.textPrimary : AppColors.textMuted,
              fontSize: 17,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
    required this.sourceLabel,
    required this.targetCode,
    required this.targetLabel,
    required this.onSourceTap,
    required this.onTargetTap,
    required this.onSwap,
  });

  final String sourceCode;
  final String sourceLabel;
  final String targetCode;
  final String targetLabel;
  final VoidCallback onSourceTap;
  final VoidCallback onTargetTap;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 26,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SelectorSide(
                      alignment: CrossAxisAlignment.start,
                      accentColor: const Color(0xFFCFF3D7),
                      code: sourceCode,
                      label: sourceLabel,
                      onTap: onSourceTap,
                    ),
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Color(0xFFD1EFD8),
                    indent: 26,
                    endIndent: 26,
                  ),
                  Expanded(
                    child: _SelectorSide(
                      alignment: CrossAxisAlignment.end,
                      accentColor: const Color(0xFFE8F7EC),
                      code: targetCode,
                      label: targetLabel,
                      onTap: onTargetTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: onSwap,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x15000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.arrow_left_arrow_right,
                color: AppColors.success,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorSide extends StatelessWidget {
  const _SelectorSide({
    required this.alignment,
    required this.accentColor,
    required this.code,
    required this.label,
    required this.onTap,
  });

  final CrossAxisAlignment alignment;
  final Color accentColor;
  final String code;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        child: Column(
          crossAxisAlignment: alignment,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: alignment == CrossAxisAlignment.start ? TextAlign.left : TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.3,
              ),
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

class _ConverterHint extends StatelessWidget {
  const _ConverterHint({required this.mode});

  final _ConverterMode mode;

  @override
  Widget build(BuildContext context) {
    final message = mode == _ConverterMode.currency
        ? 'Döviz çevirileri canlı satış fiyatına göre hesaplanır.'
        : 'Altın çevirileri marj uygulanmış satış fiyatı üzerinden hesaplanır.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }
}

class _ConverterErrorState extends StatelessWidget {
  const _ConverterErrorState({
    required this.message,
    required this.onRetry,
  });

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
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 15,
              ),
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
  const _PickerOption({
    required this.code,
    required this.label,
  });

  final String code;
  final String label;
}
