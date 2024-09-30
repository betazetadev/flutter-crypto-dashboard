import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/crypto_service.dart';
import 'dart:async';
import '../widget/select_crypto_dialog.dart';

class CryptoDashboard extends StatefulWidget {
  @override
  _CryptoDashboardState createState() => _CryptoDashboardState();
}

class _CryptoDashboardState extends State<CryptoDashboard> {
  final CryptoService _cryptoService = CryptoService();
  bool _isLoading = false;
  late SharedPreferences _prefs;

  // Cryptocurrency list with corresponding colors
  final Map<String, Color> _cryptoList = {
    'bitcoin': Colors.orange,
    'ethereum': Colors.blue,
    'cardano': Colors.green,
    'dogecoin': Colors.purple,
    'polkadot': Colors.red,
    'solana': Colors.brown,
    'litecoin': Colors.pink,
    'binancecoin': Colors.yellow,
    'ripple': Colors.cyan,
    'tron': Colors.teal,
  };

  String _selectedPeriod = '7';
  Map<String, bool> _selectedCryptos = {};
  Map<String, List<double>> _cryptoPrices = {};
  List<String> _selectedCryptoList = [];

  @override
  void initState() {
    super.initState();
    _initCryptoSelection();
  }

  // Initialize the selected cryptocurrencies and load data
  Future<void> _initCryptoSelection() async {
    _prefs = await SharedPreferences.getInstance();

    // Load selected cryptocurrencies from storage
    List<String>? storedSelectedCryptos =
    _prefs.getStringList('selectedCryptos');
    if (storedSelectedCryptos != null && storedSelectedCryptos.isNotEmpty) {
      _selectedCryptoList = storedSelectedCryptos;
    }

    _cryptoList.keys.forEach((key) {
      _selectedCryptos[key] = _selectedCryptoList
          .contains(key);
    });

    _loadDataFromStorage();
    _selectedCryptos.forEach((crypto, isSelected) {
      if (isSelected) {
        _fetchData(crypto,
            _selectedPeriod);
      }
    });
  }

  // Load cryptocurrency data from storage
  Future<void> _loadDataFromStorage() async {
    for (String crypto in _cryptoList.keys) {
      if (_prefs.containsKey(crypto)) {
        List<String>? storedPrices = _prefs.getStringList(crypto);
        if (storedPrices != null) {
          setState(() {
            _cryptoPrices[crypto] =
                storedPrices.map((e) => double.parse(e)).toList();
          });
        }
      }
    }
  }

  void _fetchData(String crypto, String days) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final prices = await _cryptoService.getCryptoPrices(crypto, days);
      setState(() {
        _cryptoPrices[crypto] = prices;
        _prefs.setStringList(crypto, prices.map((e) => e.toString()).toList());
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: Too many requests. Please wait.'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Save selected cryptocurrencies to local storage
  void _saveSelectedCryptos() {
    _prefs.setStringList('selectedCryptos', _selectedCryptoList);
  }

  // Open the dialog to select cryptocurrencies
  void _openCryptoSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return SelectCryptoDialog(
          cryptoList: _cryptoList,
          selectedCryptos: _selectedCryptos,
          onSelected: (crypto, isSelected) {
            setState(() {
              _selectedCryptos[crypto] = isSelected;
              if (isSelected) {
                _fetchData(crypto, _selectedPeriod);
                if (!_selectedCryptoList.contains(crypto)) {
                  _selectedCryptoList.add(crypto);
                }
              } else {
                _cryptoPrices.remove(crypto);
                _selectedCryptoList.remove(crypto);
              }
              if (_selectedCryptoList.isEmpty) {
                _selectedCryptos['bitcoin'] = true;
                _selectedCryptoList.add('bitcoin');
                _fetchData('bitcoin', _selectedPeriod);
              }
              _saveSelectedCryptos();
            });
          },
        );
      },
    );
  }

  // Build the line chart with the selected cryptocurrencies
  Widget _buildLineChart() {
    DateTime today = DateTime.now();
    int daysInPeriod = int.parse(_selectedPeriod);
    DateTime startDate = today.subtract(Duration(days: daysInPeriod));

    return LineChart(
      LineChartData(
        maxX: daysInPeriod.toDouble() - 1,
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: Colors.black),
            bottom: BorderSide(color: Colors.black),
            top: BorderSide.none,
            right: BorderSide.none,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                DateTime date = startDate.add(Duration(days: value.toInt()));
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    DateFormat('dd/MM').format(date),
                    style: TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              reservedSize: 40,
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('\$${value.toInt()}',
                    style: TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        lineBarsData: _cryptoPrices.entries
            .where((entry) => _selectedCryptos[entry.key] == true)
            .map((entry) {
          return LineChartBarData(
            spots: entry.value.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value);
            }).toList(),
            isCurved: false,
            color: _cryptoList[entry.key],
            barWidth: 2,
            dotData: FlDotData(show: false),
          );
        }).toList(),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final spot = touchedSpot;
                final coinName = _cryptoList.entries.firstWhere((entry) {
                  return entry.value == spot.bar.color;
                }).key;
                final coinColor = _cryptoList[coinName];

                return LineTooltipItem(
                  '• ${spot.y.toStringAsFixed(2)}\$',
                  TextStyle(
                    color: coinColor,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crypto Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _openCryptoSelectionDialog,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _selectedCryptoList.map((crypto) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: FilterChip(
                            label: Text(crypto),
                            backgroundColor: _selectedCryptos[crypto]!
                                ? _cryptoList[crypto]
                                : null,
                            selectedColor: _cryptoList[crypto],
                            selected: _cryptoPrices.containsKey(crypto),
                            onSelected: (bool selected) {
                              if (_selectedCryptoList.length == 1 && !selected) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('At least one cryptocurrency must be selected.'),
                                  backgroundColor: Colors.orange,
                                ));
                                return;
                              }
                              setState(() {
                                if (selected) {
                                  _fetchData(crypto, _selectedPeriod);
                                } else {
                                  _cryptoPrices.remove(crypto);
                                }
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedPeriod,
                  items: [
                    DropdownMenuItem(value: '7', child: Text('Last week')),
                    DropdownMenuItem(value: '15', child: Text('Last 15 days')),
                    DropdownMenuItem(value: '30', child: Text('Last month')),
                    DropdownMenuItem(value: '90', child: Text('Last 3 months')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPeriod = value!;
                      _selectedCryptoList.forEach((crypto) {
                        if (_selectedCryptos[crypto] == true && _cryptoPrices.containsKey(crypto)) {
                          _fetchData(crypto, _selectedPeriod);
                        }
                      });
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: _cryptoPrices.isNotEmpty
                  ? _buildLineChart()
                  : Center(child: Text('Select cryptocurrencies to display')),
            ),
          ],
        ),
      ),
    );
  }
}
