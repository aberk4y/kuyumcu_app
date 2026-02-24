import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'price_model.dart';

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final TextEditingController _amountController = TextEditingController(text: "1");
  String selectedSource = "GRAM ALTIN";
  String selectedTarget = "Türk Lirası (TRY)";
  bool isTurkish = true;
  double result = 0.0;
  List<Price> prices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  // Hesaplama için güncel fiyatları yükle
  Future<void> _loadPrices() async {
    try {
      final data = await ApiService.fetchPrices();
      setState(() {
        prices = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // Hesaplama Mantığı
  void _calculate() {
    if (prices.isEmpty) return;

    double amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    double sourcePriceValue = 0;
    double targetDivider = 1.0;

    // Kaynak fiyatını bul (Altın türleri)
    try {
      final sourcePrice = prices.firstWhere((p) => p.name.toUpperCase().contains(selectedSource.toUpperCase()));
      sourcePriceValue = double.parse(sourcePrice.sell.replaceAll('.', '').replaceAll(',', '.'));
    } catch (e) {
      sourcePriceValue = 0;
    }

    // Hedef birim çarpanını bul (Döviz ise)
    if (selectedTarget.contains("USD")) {
      final usd = prices.firstWhere((p) => p.name.contains("USD"));
      targetDivider = double.parse(usd.sell.replaceAll('.', '').replaceAll(',', '.'));
    } else if (selectedTarget.contains("EUR")) {
      final eur = prices.firstWhere((p) => p.name.contains("EUR"));
      targetDivider = double.parse(eur.sell.replaceAll('.', '').replaceAll(',', '.'));
    }

    setState(() {
      result = (amount * sourcePriceValue) / targetDivider;
    });
  }

  // Kaynak ve Hedefi Yer Değiştirme
  void _swap() {
    // Bu basit çeviricide altın -> döviz mantığı olduğu için
    // sadece görselliği veya listeyi tetikleyebilirsiniz.
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFBFBFB),
      child: SafeArea(
        child: isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              const SizedBox(height: 20),

              /// ÜST BÖLÜM (LOGO & DİL)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 55), // Dengelemek için
                  Column(
                    children: [
                      const Text("ASLANOĞLU", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                      Text(isTurkish ? "Kuyumculuk" : "Jewelry", style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => setState(() => isTurkish = !isTurkish),
                    child: Container(
                      height: 40, width: 45,
                      decoration: BoxDecoration(color: const Color(0xFFFFCC00), borderRadius: BorderRadius.circular(10)),
                      child: Center(child: Text(isTurkish ? "TR" : "EN", style: const TextStyle(fontWeight: FontWeight.bold))),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              Text(isTurkish ? "ALTIN ÇEVİRİCİ" : "GOLD CONVERTER", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
              Text(isTurkish ? "(Bilgi içindir)" : "(For information only)", style: const TextStyle(fontSize: 13, color: Colors.grey)),

              const SizedBox(height: 25),

              /// ÇEVİRİ KARTI
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(isTurkish ? "Miktar" : "Amount"),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(15),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel(isTurkish ? "Kaynak" : "Source"),
                    _buildDropdown(
                      value: selectedSource,
                      items: ["GRAM ALTIN", "HAS ALTIN", "22 AYAR", "14 AYAR", "ALTIN GÜMÜŞ"],
                      onChanged: (val) => setState(() => selectedSource = val!),
                    ),

                    /// SWAP (YER DEĞİŞTİRME) BUTONU
                    Center(
                      child: IconButton(
                        icon: const Icon(CupertinoIcons.arrow_2_squarepath, color: Color(0xFFD4AF37)),
                        onPressed: _swap,
                      ),
                    ),

                    _buildLabel(isTurkish ? "Hedef" : "Target"),
                    _buildDropdown(
                      value: selectedTarget,
                      items: ["Türk Lirası (TRY)", "Amerikan Doları (USD)", "Euro (EUR)"],
                      onChanged: (val) => setState(() => selectedTarget = val!),
                    ),

                    const SizedBox(height: 25),

                    /// HESAPLAMA SONUCU
                    if (result > 0)
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(15),
                          width: double.infinity,
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              Text(isTurkish ? "Sonuç" : "Result", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              Text("${result.toStringAsFixed(2)} ${selectedTarget.split(' ').last}",
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.green)),
                            ],
                          ),
                        ),
                      ),

                    /// HESAPLA BUTONU
                    SizedBox(
                      width: double.infinity, height: 55,
                      child: ElevatedButton(
                        onPressed: _calculate,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: Text(isTurkish ? "Hesapla" : "Calculate", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF455A64))));

  Widget _buildDropdown({required String value, required List<String> items, required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, isExpanded: true,
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}