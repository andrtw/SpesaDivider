import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

enum PriceType { DIVIDED, FULL }

class Item {
  final String id;
  double value;
  PriceType type;

  Item(this.value, this.type) : id = Uuid().v1();

  void update(double value, PriceType type) {
    this.value = value;
    this.type = type;
  }
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _items = List<Item>();
  final _currencyFormatter = NumberFormat.currency(
    locale: Intl.defaultLocale,
    name: 'Euro',
    symbol: '\u20AC',
    decimalDigits: 2,
  );
  var _amount = 0.0;
  var _total = 0.0;

  void _showTotalDialog([reset = false]) {
    if (reset) {
      _total = 0.0;
      _items.clear();
    }
    _priceController.clear();
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Enter the amount'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Container(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: _validatePrice,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Price'),
                  ),
                ),
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('OK'),
                onPressed: _setAmount,
              )
            ],
          );
        });
  }

  Future<PriceType> _showItemDialog(String dialogTitle,
      [double initialPrice = -1.0]) {
    _priceController.text = initialPrice != -1
        ? _currencyFormatter.format(initialPrice).substring(1)
        : '';

    buildPriceTypeButton(PriceType type) {
      return IconButton(
        onPressed: () {
          if (_formKey.currentState.validate()) {
            Navigator.pop(context, type);
          }
        },
        tooltip: type == PriceType.DIVIDED ? 'Divided' : 'Full',
        icon: Icon(type == PriceType.DIVIDED ? Icons.group : Icons.person),
      );
    }

    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(dialogTitle),
            content: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Form(
                    key: _formKey,
                    child: Container(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        validator: _validatePrice,
                        autofocus: true,
                        decoration: const InputDecoration(labelText: 'Price'),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 30.0),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      buildPriceTypeButton(PriceType.DIVIDED),
                      buildPriceTypeButton(PriceType.FULL),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }

  void _setAmount() {
    if (_formKey.currentState.validate()) {
      setState(() => _amount = double.parse(_priceController.text));
      Navigator.pop(context);
      _priceController.clear();
    }
  }

  void _addItem() async {
    if (_amount == 0.0) {
      _showTotalDialog();
    } else {
      _setItem(await _showItemDialog('Add item'));
    }
  }

  void _editItem(Item item) async {
    _setItem(await _showItemDialog('Edit item', item.value), item);
  }

  void _dismissItem(Item item) {
    setState(() {
      if (_items.contains(item)) {
        _items.remove(item);
        _total -= item.value;
      }
    });
  }

  String _validatePrice(String value) {
    if (double.tryParse(value) == null) {
      return 'Enter a valid price';
    }
    return null;
  }

  void _setItem(PriceType type, [Item item]) {
    var value = double.parse(_priceController.text);
    if (type == PriceType.DIVIDED) {
      value /= 2;
    }
    setState(() {
      if (item == null) {
        _items.add(Item(value, type));
        _total += value;
      } else {
        final oldItemIndex = _items.indexOf(item);
        final oldItem = _items[oldItemIndex];
        _total -= oldItem.value;
        _items[oldItemIndex].update(value, type);
        _total += value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    buildDismissibleIcon() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Icon(Icons.delete, color: Colors.white),
      );
    }

    buildBody() {
      if (_amount == 0) {
        return RaisedButton(
          child: Text('Start'),
          onPressed: _showTotalDialog,
          color: Colors.green,
          textColor: Colors.white,
        );
      } else if (_items.isEmpty) {
        return Text('No items');
      } else {
        buildDividedTiles() {
          return ListTile
              .divideTiles(
                context: context,
                tiles: _items.map((item) {
                  return Dismissible(
                    key: Key(item.id),
                    onDismissed: (direction) {
                      _dismissItem(item);
                    },
                    background: Container(
                      color: Colors.red,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          buildDismissibleIcon(),
                          buildDismissibleIcon(),
                        ],
                      ),
                    ),
                    child: ListTile(
                      title: Text(_currencyFormatter.format(item.value)),
                      leading: Icon(item.type == PriceType.DIVIDED
                          ? Icons.group
                          : Icons.person),
                      onTap: () => _editItem(item),
                    ),
                  );
                }),
              )
              .toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ListView(
                children: buildDividedTiles(),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey[200], width: 1.0),
                  )),
              child: Row(
                children: <Widget>[
                  Text(_currencyFormatter.format(_total)),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0)),
                  Text(_currencyFormatter.format(_amount - _total)),
                ],
              ),
            )
          ],
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Spesa Divider'),
        actions: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                child: Container(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Text(
                    _currencyFormatter.format(_amount),
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () {
                  _showTotalDialog(true);
                },
              ),
            ],
          )
        ],
      ),
      body: Center(
        child: buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }
}
