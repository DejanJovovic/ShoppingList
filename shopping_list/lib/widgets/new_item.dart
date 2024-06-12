import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/models/grocery_item.dart'; // all the content provided from this package should be bundled in http

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() {
    return _NewItemState();
  }
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<
      FormState>(); // creates a global key object that can be used as a value for a key
  var _enteredName = '';
  var _enteredQuantity = 1;
  var _selectedCategory = categories[Categories.vegetables]!;

  var _isSending = false;

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      // validate executes to validate functions inside the form field, if at least one validator failed this will be false
      _formKey.currentState!
          .save(); // this will be triggered if validate returns true(if validation successeds)

      // update the UI when the add item button is pressed
      setState(() {
        _isSending = true;
      });

      // Firebase logic to post data
      final url = Uri.https('shoppinglist-f4bb7-default-rtdb.firebaseio.com',
          'shopping-list.json');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(
          // encode converts data to json
          // this data should be sent to firebase
          {
            // id doesnt need to be send because firebase generates it automatically
            'name': _enteredName,
            'quantity': _enteredQuantity,
            'category': _selectedCategory.title,
          },
        ),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (!context.mounted) {
        return;
      }

      Navigator.of(context).pop(
        GroceryItem(
            id: responseData['name'],
            name: _enteredName,
            quantity: _enteredQuantity,
            category: _selectedCategory),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a new item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                // instead of TextField()
                maxLength: 50, // no longer that 50 characters
                decoration: const InputDecoration(
                  label: Text('Name'),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length <= 1 ||
                      value.trim().length > 50) {
                    return 'Must be between 1 and 50 characters';
                  } // checking the validation
                  return null;
                },
                onSaved: (value) {
                  _enteredName = value!;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        label: Text('Quantity'),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: _enteredQuantity
                          .toString(), //allows to set an initial value that will be set inside this formField
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) ==
                                null || // tryParse returns null if it fails to convert a string to a number
                            int.tryParse(value)! <= 0) {
                          return 'Must be a valid, positive number.';
                        } // checking the validation
                        return null;
                      },
                      onSaved: (value) {
                        _enteredQuantity = int.parse(
                            value!); // parse will throw an error if it fails to convert the string to a number, tryParse yields null
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField(
                        value: _selectedCategory,
                        items: [
                          for (final category in categories.entries)
                            DropdownMenuItem(
                              value: category.value,
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    color: category.value.color,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(category.value.title)
                                ],
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            // setState is needed here because the UI should be updated when the new category is selected
                            _selectedCategory = value!;
                          });
                        }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    // if _isSending is false return null in the onPressed(disable that button) else reset the state
                    onPressed: _isSending
                        ? null
                        : () {
                            _formKey.currentState!
                                .reset(); // this will reset all the values on the input fields
                          },
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    // same as in the button above, if the _isSending is false disable this button else call _saveItem function
                    onPressed: _isSending ? null : _saveItem,
                    // if _isSending is false add a cicular progress indicator to let the user know its adding the item, else just show the Text widget
                    child: _isSending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(),
                          )
                        : const Text('Add item'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
