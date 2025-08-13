import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../dao/category_dao.dart';
import '../models/category_model.dart';
import '../models/budget_model.dart';
import '../dao/budget_dao.dart';

class CreateBudgetPage extends StatefulWidget {
  final CategoryDao categoryDao;
  final BudgetDao budgetDao;
  final Function()? onBudgetCreated;

  const CreateBudgetPage({
    super.key,
    required this.categoryDao,
    required this.budgetDao,
    this.onBudgetCreated,
  });

  @override
  State<CreateBudgetPage> createState() => _CreateBudgetPageState();
}

class _CreateBudgetPageState extends State<CreateBudgetPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _selectedPeriod = 'monthly';
  DateTime? _startDate;
  DateTime? _endDate;
  Category? _selectedCategory;
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _startDate = DateTime.now();
    _calculateEndDate();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await widget.categoryDao.getAllCategories();
      setState(() {
        _categories = categories.where((c) => c.type == 'expense').toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load categories';
      });
    }
  }

  void _calculateEndDate() {
    if (_startDate == null) return;
    
    setState(() {
      switch (_selectedPeriod) {
        case 'weekly':
          _endDate = _startDate!.add(const Duration(days: 6));
          break;
        case 'monthly':
          _endDate = DateTime(_startDate!.year, _startDate!.month + 1, _startDate!.day);
          break;
        case 'yearly':
          _endDate = DateTime(_startDate!.year + 1, _startDate!.month, _startDate!.day);
          break;
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _startDate = pickedDate;
        _calculateEndDate();
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _startDate == null || _endDate == null) {
      setState(() {
        _errorMessage = 'Please fill all fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final amount = double.parse(_amountController.text);
      
      await widget.budgetDao.insertBudget(Budget(
        categoryId: _selectedCategory!.categoryId!,
        period: _selectedPeriod,
        limitAmount: amount,
        startDate: _startDate,
        endDate: _endDate,
        year: _startDate!.year,
        month: _selectedPeriod == 'monthly' ? _startDate!.month : null,
        week: _selectedPeriod == 'weekly' ? _weekNumber(_startDate!) : null,
      ));

      if (widget.onBudgetCreated != null) {
        widget.onBudgetCreated!();
      }
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create budget: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _weekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysPassed = date.difference(firstDayOfYear).inDays;
    return ((daysPassed + firstDayOfYear.weekday) / 7).ceil();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Budget'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category Dropdown
              DropdownButtonFormField<Category>(
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                value: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem<Category>(
                    value: category,
                    child: Row(
                      children: [
                        Icon(
                          _iconDataFromKey(category.iconKey),
                          color: _colorFromHex(category.colorHex),
                        ),
                        const SizedBox(width: 12),
                        Text(category.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                validator: (value) => value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 20),

              // Period Selection
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Period',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                value: _selectedPeriod,
                items: const [
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPeriod = value;
                      _calculateEndDate();
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Date Range
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: theme.dividerColor),
                ),
                onPressed: () => _selectDate(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date Range',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _startDate != null && _endDate != null
                          ? '${DateFormat('MMM d, y').format(_startDate!)} - ${DateFormat('MMM d, y').format(_endDate!)}'
                          : 'Select date',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedPeriod == 'monthly'
                    ? 'Budget applies to 1 month starting from selected date'
                    : _selectedPeriod == 'weekly'
                        ? 'Budget applies to 7 days starting from selected date'
                        : 'Budget applies to 1 year starting from selected date',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 20),

              // Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (MWK)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  prefixText: 'MWK ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Error Message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Budget'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add these helper methods at the bottom of the class
  IconData _iconDataFromKey(String key) {
    switch (key) {
      case 'fastfood': return Icons.restaurant;
      case 'grocery': return Icons.receipt;
      case 'car': return Icons.directions_car;
      case 'money': return Icons.attach_money;
      case 'gift': return Icons.card_giftcard;
      case 'shopping': return Icons.shopping_cart;
      case 'coffee': return Icons.coffee;
      case 'movie': return Icons.movie;
      case 'fitness': return Icons.fitness_center;
      case 'gas': return Icons.local_gas_station;
      case 'phone': return Icons.phone_iphone;
      case 'home': return Icons.home;
      case 'hospital': return Icons.local_hospital;
      case 'school': return Icons.school;
      case 'computer': return Icons.computer;
      case 'flight': return Icons.flight;
      case 'pets': return Icons.pets;
      case 'soccer': return Icons.sports_soccer;
      case 'music': return Icons.music_note;
      case 'beach': return Icons.beach_access;
      default: return Icons.category;
    }
  }

  Color _colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}