import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:list_belanja/data/categories.dart';
import 'package:list_belanja/models/grocery_item.dart';
import 'package:list_belanja/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _grocaryItem = [];
  var _isloading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
        'flutter-prep-ef1a6-default-rtdb.firebaseio.com', 'list-belanja.json');

    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _error = 'failed to fetch data, please try again later';
        });
      }

      if (response.body == 'null') {
        setState(() {
          _isloading = false;
        });
        return;
      }

      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }
      setState(() {
        _grocaryItem = loadedItems;
        _isloading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong! Please try again later.';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (context) => const NewItem(),
      ),
    );
    if (newItem == null) {
      return;
    }

    setState(() {
      _grocaryItem.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _grocaryItem.indexOf(item);
    setState(() {
      _grocaryItem.remove(item);
    });
    final url = Uri.https('flutter-prep-ef1a6-default-rtdb.firebaseio.com',
        'list-belanja/${item.id}.json');
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _grocaryItem.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('tidak ada data'),
    );

    if (_isloading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_grocaryItem.isNotEmpty) {
      content = ListView.builder(
        itemCount: _grocaryItem.length,
        itemBuilder: (context, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_grocaryItem[index]);
          },
          key: ValueKey(_grocaryItem[index].id),
          child: ListTile(
            title: Text(_grocaryItem[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _grocaryItem[index].category.color,
            ),
            trailing: Text(
              _grocaryItem[index].quantity.toString(),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      content = Center(child: Text(_error!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('your groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
