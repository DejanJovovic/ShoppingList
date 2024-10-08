import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
        'shoppinglist-f4bb7-default-rtdb.firebaseio.com', 'shopping-list.json');

    
    // if the code inside try causes an error, catch that error
    // if there is a problem with the internet connection for example
    try { 
      final response = await http.get(url);

       if(response.statusCode >= 400){
      setState(() {
        _error = 'Failed to fetch data. Please try again!';
      });
    }

    // ** this is only for firebase ** returns a null as a string, instead of null
    if(response.body == 'null'){
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final Map<String, dynamic> groceryListData = json.decode(response.body);
    final List<GroceryItem> loadedGroceryItems = [];

    for (final item in groceryListData.entries) {
      // loops through all the unique id's in firebase that contain data for grocery items

      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value; // firstWhere will filter a list, and will yield one item

      loadedGroceryItems.add(
        GroceryItem(
          id: item.key, // unique firebase id's
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }
    setState(() {
      _groceryItems = loadedGroceryItems;
      _isLoading = false;
    });

    } catch (error) {
         setState(() {
        _error = 'Something went wrong. Please try again!';
      });
    }

   
  }

  void _addItem() async {
    final newGroceryItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newGroceryItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newGroceryItem);
    });
  }

  void _removeItem(GroceryItem item) async{

    final index = _groceryItems.indexOf(item);

    setState(() {
      _groceryItems.remove(item);
    });

    // targeting a specific id when deleting
    final url = Uri.https(
        'shoppinglist-f4bb7-default-rtdb.firebaseio.com', 'shopping-list/${item.id}.json');

    final response = await http.delete(url);
    
    //something went wrong when deleting the item, undo that item
    if(response.statusCode >= 400) {
      // Optional: Show an error message
      setState(() {
        // using insert to bring back the deleted item on the place where it was previously
      _groceryItems.insert(index, item);
    });
    }

    
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No items added yet.'));

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(), // renders a loading spinner
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          key: ValueKey(_groceryItems[index].id),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              // leading outputs an indicator for the category this grocery item belongs to
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
            ),
          ),
        ),
      );
    }

  // if for some reason there is an error when getting the data from firebase, 
  // here i check if its not null and display it on the screen
    if(_error != null) {
      content = Center(child: Text(_error!));
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('Your Groceries'),
          actions: [
            IconButton(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: content);
  }
}
