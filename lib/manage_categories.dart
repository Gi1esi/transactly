import 'package:flutter/material.dart';

class ManageCategoriesPage extends StatefulWidget {
  final bool isExpense;

  const ManageCategoriesPage({Key? key, required this.isExpense}) : super(key: key);

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  late List<String> categories;

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    categories = widget.isExpense
        ? ['Food', 'Transport', 'Bills']
        : ['Salary', 'Freelance'];
  }

  void _addCategory() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      categories.add(_controller.text.trim());
      _controller.clear();
    });
  }

  void _editCategory(int index) {
    _controller.text = categories[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(controller: _controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                categories[index] = _controller.text.trim();
              });
              _controller.clear();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  void _deleteCategory(int index) {
    setState(() {
      categories.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isExpense ? 'Manage Expense Categories' : 'Manage Income Categories';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'New Category',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addCategory,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: categories.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      categories[index],
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () => _editCategory(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteCategory(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
