import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list_with_future_builder/data/categories.dart';
import 'package:shopping_list_with_future_builder/models/category.dart';

import 'package:shopping_list_with_future_builder/models/grocery_item.dart';
import 'package:shopping_list_with_future_builder/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItem = [];

  // var _isLoading = true;
//late : we have no initail value but we will have a value in future
  late Future<List<GroceryItem>> _loadedItems;

  String? _error;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadedItems = _loadItems();
  }

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
        'shopping-list-de575-default-rtdb.firebaseio.com', 'list-ho.json');

    final response = await http.get(url);

    if (response.statusCode >= 400) {
      // setState(() {
      //   _error = 'Failed to fetch data please try again later.';
      // });
      throw Exception('Failed to fetch grocery item, please try again!');
    }

//firebase return null string thats why null is in double quotes.
    if (response.body == "null") {
      // setState(() {
      //   _isLoading = false;
      // });
      return [];
    }
    final Map<String, dynamic> ListData = json.decode(response.body);
    final List<GroceryItem> loadedItemList = [];
    for (var item in ListData.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value;
      loadedItemList.add(GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category));
    }
    return loadedItemList;
    // setState(() {
    //   _groceryItem = loadedItemList;
    //   _isLoading = false;
    // });
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(builder: (ctx) => const NewItem()),
    );
    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItem.add(newItem);
    });
  }

  void _removeItem(GroceryItem groceryItem) async {
    final index = _groceryItem.indexOf(groceryItem);
    setState(() {
      _groceryItem.remove(groceryItem);
    });
    final url = Uri.https('shopping-list-de575-default-rtdb.firebaseio.com',
        'list-ho/${groceryItem.id}.json');
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        //message
        _groceryItem.insert(index, groceryItem);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // if (_isLoading) {
    //   content = const Center(
    //     child: CircularProgressIndicator(),
    //   );
    // }

    // if (_error != null) {
    //   content = Center(
    //     child: Text(_error!),
    //   );
    // }
    return Scaffold(
      appBar: AppBar(
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
        title: const Text('Your Groceries'),
      ),
      body: FutureBuilder(
        //considered a bad practice to write as future: _loadItem(); because it will execute every time build method executed.
        future: _loadedItems,
        //builder execute once only
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }
          if (snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No item Added yet'),
            );
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (ctx, index) => Dismissible(
              background: Container(
                decoration: const BoxDecoration(color: Colors.red),
              ),
              onDismissed: (direction) {
                _removeItem(snapshot.data![index]);
              },
              key: ValueKey(snapshot.data![index].id),
              child: ListTile(
                title: Text(snapshot.data![index].name),
                leading: Container(
                  width: 24,
                  height: 24,
                  color: snapshot.data![index].category.color,
                ),
                trailing: Text(
                  snapshot.data![index].quantity.toString(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
