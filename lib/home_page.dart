import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'converter_page.dart';
import 'api_service.dart';
import 'price_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool isTurkish = true;

  List<Widget> get _pages => [
    _MainContent(
      isTurkish: isTurkish,
      onLanguageChange: () =>
          setState(() => isTurkish = !isTurkish),
    ),
    const ConverterPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        currentIndex: _currentIndex,
        onTap: (index) =>
            setState(() => _currentIndex = index),
        activeColor: const Color(0xFFFFCC00),
        inactiveColor: Colors.grey,
        backgroundColor: Colors.white,
        border: Border(
            top: BorderSide(
                color: Colors.grey.shade200, width: 0.5)),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.house_fill),
            label: isTurkish ? "Ana Sayfa" : "Home",
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.refresh_thick),
            label:
            isTurkish ? "Çevirici" : "Converter",
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoPageScaffold(
          backgroundColor:
          const Color(0xFFFBFBFB),
          child: _pages[index],
        );
      },
    );
  }
}

class _MainContent extends StatefulWidget {
  final bool isTurkish;
  final VoidCallback onLanguageChange;

  const _MainContent({
    super.key,
    required this.isTurkish,
    required this.onLanguageChange,
  });

  @override
  State<_MainContent> createState() =>
      _MainContentState();
}

class _MainContentState
    extends State<_MainContent> {
  late Future<List<Price>> pricesFuture;
  Timer? _autoRefreshTimer;

  int selectedCategory = 0;
  String searchQuery = "";
  final TextEditingController _searchController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    pricesFuture = ApiService.fetchPrices();

    /// 🔄 30 saniyede otomatik yenileme
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => _refresh(),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// 🌐 İnternet kontrol + yenileme
  Future<void> _refresh() async {
    final connectivity =
    await Connectivity().checkConnectivity();

    if (connectivity ==
        ConnectivityResult.none) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(widget.isTurkish
                ? "İnternet bağlantısı yok"
                : "No internet connection"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      pricesFuture =
          ApiService.fetchPrices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTR = widget.isTurkish;

    return Material(
      color: const Color(0xFFFBFBFB),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 15),

            /// LOGO
            Center(
              child: Column(
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    decoration:
                    BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                      border: Border.all(
                          color: const Color(
                              0xFFFFCC00),
                          width: 2),
                      image:
                      const DecorationImage(
                        image: AssetImage(
                            "assets/logo.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "ASLANOĞLU",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                        FontWeight.w900,
                        letterSpacing: 1.2),
                  ),
                  Text(
                    isTR
                        ? "Kuyumculuk"
                        : "Jewelry",
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight:
                        FontWeight.w500),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// ARAMA + DİL
            Padding(
              padding:
              const EdgeInsets.symmetric(
                  horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      padding:
                      const EdgeInsets
                          .symmetric(
                          horizontal:
                          15),
                      decoration:
                      BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius
                            .circular(15),
                        boxShadow: [
                          BoxShadow(
                              color: Colors
                                  .black
                                  .withOpacity(
                                  0.05),
                              blurRadius: 10)
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                              CupertinoIcons
                                  .search,
                              color: Colors
                                  .grey
                                  .shade400,
                              size: 20),
                          const SizedBox(
                              width: 10),
                          Expanded(
                            child: TextField(
                              controller:
                              _searchController,
                              onChanged:
                                  (value) =>
                                  setState(() =>
                                  searchQuery =
                                      value
                                          .toLowerCase()),
                              decoration:
                              InputDecoration(
                                hintText: isTR
                                    ? "Ara..."
                                    : "Search...",
                                border:
                                InputBorder
                                    .none,
                                isDense: true,
                              ),
                            ),
                          ),
                          GestureDetector(
                              onTap: _refresh,
                              child: Icon(
                                  CupertinoIcons
                                      .refresh,
                                  size: 18)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap:
                    widget.onLanguageChange,
                    child: Container(
                      height: 50,
                      width: 55,
                      decoration:
                      BoxDecoration(
                        color: const Color(
                            0xFFFFCC00),
                        borderRadius:
                        BorderRadius
                            .circular(15),
                      ),
                      child: Center(
                        child: Text(
                          isTR
                              ? "TR"
                              : "EN",
                          style:
                          const TextStyle(
                              fontWeight:
                              FontWeight
                                  .bold),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 15),

            /// TOGGLE
            Padding(
              padding:
              const EdgeInsets.symmetric(
                  horizontal: 20),
              child: Container(
                padding:
                const EdgeInsets.all(5),
                decoration:
                BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _toggleButton(
                        isTR
                            ? "Altın"
                            : "Gold",
                        0),
                    _toggleButton(
                        isTR
                            ? "Döviz"
                            : "Currency",
                        1),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            /// LIST
            Expanded(
              child: RefreshIndicator(
                color:
                const Color(0xFFFFCC00),
                onRefresh: _refresh,
                child: FutureBuilder<
                    List<Price>>(
                    future: pricesFuture,
                    builder: (context,
                        snapshot) {
                      if (snapshot
                          .connectionState ==
                          ConnectionState
                              .waiting) {
                        return const Center(
                            child:
                            CupertinoActivityIndicator());
                      }

                      if (snapshot
                          .hasError) {
                        return Center(
                            child: Text(isTR
                                ? "Veri alınamadı"
                                : "Failed to load data"));
                      }

                      final filtered =
                      snapshot.data!
                          .where((p) {
                        bool matchesCategory =
                        selectedCategory ==
                            0
                            ? (!p.name
                            .contains(
                            "USD") &&
                            !p.name
                                .contains(
                                "EUR"))
                            : (p.name
                            .contains(
                            "USD") ||
                            p.name
                                .contains(
                                "EUR"));

                        return matchesCategory &&
                            p.name
                                .toLowerCase()
                                .contains(
                                searchQuery);
                      }).toList();

                      return ListView
                          .builder(
                        padding:
                        const EdgeInsets
                            .symmetric(
                            horizontal:
                            20,
                            vertical:
                            10),
                        itemCount:
                        filtered.length,
                        itemBuilder:
                            (context,
                            index) =>
                            _buildPriceCard(
                                filtered[
                                index]),
                      );
                    }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleButton(
      String title, int index) {
    final isSelected =
        selectedCategory == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedCategory =
                index;
            _searchController
                .clear();
            searchQuery = "";
          });
        },
        child: AnimatedContainer(
          duration:
          const Duration(
              milliseconds: 250),
          padding:
          const EdgeInsets.symmetric(
              vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(
                0xFFFFCC00)
                : Colors.transparent,
            borderRadius:
            BorderRadius.circular(
                16),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight:
              FontWeight.bold,
              color: isSelected
                  ? Colors.black
                  : Colors.grey
                  .shade400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceCard(
      Price item) {
    final isPositive =
    !item.change
        .startsWith("-");
    return Container(
      margin:
      const EdgeInsets.only(
          bottom: 16),
      padding:
      const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black
                  .withOpacity(0.04),
              blurRadius: 12,
              offset:
              const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.name
                      .toUpperCase(),
                  style:
                  const TextStyle(
                      fontWeight:
                      FontWeight
                          .w800),
                  overflow:
                  TextOverflow
                      .ellipsis,
                ),
              ),
              Row(
                children: [
                  Icon(
                    isPositive
                        ? CupertinoIcons
                        .arrow_up_right
                        : CupertinoIcons
                        .arrow_down_right,
                    size: 14,
                    color: isPositive
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(
                      width: 4),
                  Text(
                    item.change,
                    style: TextStyle(
                        fontWeight:
                        FontWeight
                            .bold,
                        color: isPositive
                            ? Colors
                            .green
                            : Colors
                            .red),
                  )
                ],
              )
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _priceBox(
                  widget.isTurkish
                      ? "Alış"
                      : "Buy",
                  item.buyWithMargin),
              const SizedBox(
                  width: 12),
              _priceBox(
                  widget.isTurkish
                      ? "Satış"
                      : "Sell",
                  item.sellWithMargin),
            ],
          )
        ],
      ),
    );
  }

  Widget _priceBox(
      String title, String value) {
    return Expanded(
      child: Container(
        padding:
        const EdgeInsets.symmetric(
            vertical: 16),
        decoration: BoxDecoration(
          color:
          const Color(0xFFF9F9F9),
          borderRadius:
          BorderRadius.circular(
              15),
        ),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors
                        .grey
                        .shade500)),
            const SizedBox(
                height: 6),
            Text("$value ₺",
                style:
                const TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight
                        .w800)),
          ],
        ),
      ),
    );
  }
}