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

  // Save user
  final user = User(
    firstName: _firstNameController.text,
    lastName: _lastNameController.text,
  );
  final userId = await UserDao().insertUser(user);

  // Save account
  final account = Account(
    userId: userId,
    accountNumber: _accountNumberController.text,
    bankId: selectedBank!.bankId,
  );
  await AccountDao().insertAccount(account);


  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Registration successful!')),
  );
  // Start SMS watcher in background
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
  final secondary = theme.colorScheme.secondary;

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
                      // Logo
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
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // First Name
                      TextFormField(
                        controller: _firstNameController,
                        decoration: InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Enter your first name' : null,
                      ),
                      const SizedBox(height: 16),

                      // Last Name
                      TextFormField(
                        controller: _lastNameController,
                        decoration: InputDecoration(
                          labelText: 'Last Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Enter your last name' : null,
                      ),
                      const SizedBox(height: 14),

                      // Account Number
                      TextFormField(
                        controller: _accountNumberController,
                        decoration: InputDecoration(
                          labelText: 'Account Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value!.isEmpty ? 'Enter your account number' : null,
                      ),
                      const SizedBox(height: 16),

                      
                      isLoading
                          ? const CircularProgressIndicator()
                          : DropdownButtonFormField<Bank>(
                              value: selectedBank,
                              items: banks.map((bank) {
                                return DropdownMenuItem<Bank>(
                                  value: bank,
                                   child: Text(bank.longName ?? bank.name),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setState(() => selectedBank = val),
                              decoration: InputDecoration(
                                labelText: 'Select Bank',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (val) =>
                                  val == null ? 'Select a bank' : null,
                            ),

                      const SizedBox(height: 30),

                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _registerUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 16,
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
