import 'package:flutter/material.dart';

class SelectCryptoDialog extends StatelessWidget {
  final Map<String, Color> cryptoList;
  final Map<String, bool> selectedCryptos;
  final Function(String, bool) onSelected;

  const SelectCryptoDialog({
    required this.cryptoList,
    required this.selectedCryptos,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Cryptocurrencies'),
      content: SingleChildScrollView(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: cryptoList.keys.map((crypto) {
                return CheckboxListTile(
                  title: Text(crypto),
                  value: selectedCryptos[crypto],
                  activeColor: cryptoList[crypto],
                  onChanged: (bool? selected) {
                    setState(() {
                      onSelected(crypto, selected!);
                    });
                  },
                );
              }).toList(),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          child: Text('Close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
