import 'package:flutter/material.dart';
import '../dao/bank_dao.dart';
import '../models/bank_model.dart';
import '../dao/user_dao.dart';
import '../models/user_model.dart';
import '../dao/account_dao.dart';
import '../models/account_model.dart';
import 'home.dart';
import '../utils/read_sms.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _accountNumberController = TextEditingController();

  List<Bank> banks = [];
  Bank? selectedBank;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  Future<void> _loadBanks() async {
    final bankList = await BankDao().getAllBanks();
    setState(() {
      banks = bankList;
      isLoading = false;
    });
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate() || selectedBank == null) return;

    final user = User(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );
    final userId = await UserDao().insertUser(user);

    final account = Account(
      userId: userId,
      accountNumber: _accountNumberController.text.trim(),
      bankId: selectedBank!.bankId,
    );
    await AccountDao().insertAccount(account);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registration successful!')),
    );

    await SmsWatcher().startWatching();

    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    const verticalSpacing = SizedBox(height: 20);

    InputDecoration inputDecoration(String label, IconData icon) => InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primary, width: 2),
          ),
          prefixIcon: Icon(icon, color: primary.withOpacity(0.7)),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 40, bottom: 30),
                          child: Image.asset(
                            'assets/images/Transactly.png',
                            height: 100,
                          ),
                        ),
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        verticalSpacing,
                        TextFormField(
                          controller: _firstNameController,
                          decoration: inputDecoration('First Name', Icons.person),
                          validator: (value) =>
                              value == null || value.trim().isEmpty ? 'Enter your first name' : null,
                        ),
                        verticalSpacing,
                        TextFormField(
                          controller: _lastNameController,
                          decoration: inputDecoration('Last Name', Icons.person_outline),
                          validator: (value) =>
                              value == null || value.trim().isEmpty ? 'Enter your last name' : null,
                        ),
                        verticalSpacing,
                        TextFormField(
                          controller: _accountNumberController,
                          decoration: inputDecoration('Account Number', Icons.account_balance_wallet),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              value == null || value.trim().isEmpty ? 'Enter your account number' : null,
                        ),
                        verticalSpacing,
                        isLoading
                            ? const CircularProgressIndicator()
                            : DropdownButtonFormField<Bank>(
                                value: selectedBank,
                                items: banks.map((bank) {
                                  final bankName = bank.longName ?? bank.name;
                                  return DropdownMenuItem<Bank>(
                                    value: bank,
                                    child: Text(
                                      bankName.length > 30 ? '${bankName.substring(0, 27)}...' : bankName,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => selectedBank = val),
                                decoration: InputDecoration(
                                  labelText: 'Select Bank',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: primary, width: 2),
                                  ),
                                  prefixIcon: Icon(Icons.account_balance, color: primary.withOpacity(0.7)),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                ),
                                validator: (val) => val == null ? 'Select a bank' : null,
                              ),
                        verticalSpacing,
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _registerUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
