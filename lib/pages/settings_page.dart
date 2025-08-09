import 'package:flutter/material.dart';
import '../dao/user_dao.dart';
import '../dao/account_dao.dart';
import '../models/user_model.dart';
import '../models/account_model.dart';
import '../models/bank_model.dart';
import '../dao/bank_dao.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final UserDao userDao = UserDao();
  final AccountDao accountDao = AccountDao();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  List<Account> _accounts = [];
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadAccounts();
  }

  Future<void> _loadUser() async {
    final users = await userDao.getAllUsers();
    if (users.isNotEmpty) {
      setState(() {
        _user = users.first;
        _firstNameController.text = _user!.firstName;
        _lastNameController.text = _user!.lastName;
      });
    }
  }

  Future<void> _loadAccounts() async {
    final accounts = await accountDao.getAllAccountsWithBanks();
    setState(() {
      _accounts = accounts;
    });
  }

  void _updateUserInfo() async {
    if (_user != null) {
      final updatedUser = User(
        userId: _user!.userId,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
      );
      await userDao.updateUser(updatedUser);
      setState(() {
        _user = updatedUser;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User info updated')),
      );
    }
  }

  void _setActiveAccount(int accountId) async {
    await accountDao.setActiveAccount(accountId);
    await _loadAccounts();
  }

  void _showAddAccountDialog() {
  final TextEditingController accController = TextEditingController();
  Bank? selectedBank;

  showDialog(
    context: context,
    builder: (context) {
      return FutureBuilder<List<Bank>>(
        future: BankDao().getAllBanks(),
        builder: (context, snapshot) {
          final banks = snapshot.data ?? [];
          return AlertDialog(
            title: const Text('Add New Account'),
            content: SingleChildScrollView(  // added this
              child: ConstrainedBox(           // added this
                constraints: BoxConstraints(maxHeight: 200),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: accController,
                      decoration: const InputDecoration(
                        labelText: 'Account Number',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<Bank>(
                      value: selectedBank,
                      decoration: const InputDecoration(
                        labelText: 'Select Bank',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: banks.map((bank) {
                        return DropdownMenuItem<Bank>(
                          value: bank,
                          child: Text(bank.name),
                        );
                      }).toList(),
                      onChanged: (bank) {
                        FocusScope.of(context).unfocus();  // dismiss keyboard on select
                        selectedBank = bank;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (accController.text.isNotEmpty && selectedBank != null) {
                    await accountDao.insertAccount(Account(
                      accountNumber: accController.text,
                      bankId: selectedBank!.bankId,
                      isActive: false,
                    ));
                    Navigator.pop(context);
                    _loadAccounts();
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    },
  );
}


  void _showEditUserDialog() {
    final TextEditingController firstNameController =
        TextEditingController(text: _user?.firstName ?? '');
    final TextEditingController lastNameController =
        TextEditingController(text: _user?.lastName ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit User Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_user != null) {
                  final updatedUser = User(
                    userId: _user!.userId,
                    firstName: firstNameController.text.trim(),
                    lastName: lastNameController.text.trim(),
                  );
                  await userDao.updateUser(updatedUser);
                  setState(() {
                    _user = updatedUser;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User info updated')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileCard() {
    final theme = Theme.of(context);
    final initials = (_user?.firstName.isNotEmpty == true ? _user!.firstName[0] : '') +
        (_user?.lastName.isNotEmpty == true ? _user!.lastName[0] : '');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                initials.toUpperCase(),
                style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_user?.firstName ?? ''} ${_user?.lastName ?? ''}',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Account Owner',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: theme.colorScheme.primary, size: 28),
              onPressed: _showEditUserDialog,
              tooltip: 'Edit User Info',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statTile('Accounts', _accounts.length.toString()),
        _statTile('Active', _accounts.where((a) => a.isActive).length.toString()),
        _statTile('Banks', _accounts.map((a) => a.bank?.bankId).toSet().length.toString()),
      ],
    );
  }

  Widget _statTile(String label, String value) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountsSection() {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Linked Accounts',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ..._accounts.map((account) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: theme.colorScheme.primary.withOpacity(0.8),
                  size: 28,
                ),
                title: Text(
                  account.accountNumber,
                  style: theme.textTheme.bodyLarge,
                ),
                subtitle: Text(
                  account.bank?.name ?? 'Unknown Bank',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
                trailing: account.isActive
                    ? Chip(
                        label: const Text('Active'),
                        backgroundColor: theme.colorScheme.secondary,
                        labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        side: const BorderSide(color: Colors.white),
                      )
                    : TextButton(
                        onPressed: () => _setActiveAccount(account.accountId!),
                        child: const Text('Set Active'),
                      ),
              );
            }).toList(),
            Divider(
              height: 32,
              color: Theme.of(context).primaryColor,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _showAddAccountDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Account'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  side: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHelpAndVersionSection() {
    final theme = Theme.of(context);
    const appVersion = '1.0.0';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Info',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Version $appVersion',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Checking for updates...')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Check for Updates'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
       title: Text(
          'Settings',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.background,
        foregroundColor: theme.colorScheme.onBackground,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileCard(),
          const SizedBox(height: 24),
          _buildStats(),
          const SizedBox(height: 24),
          _buildAccountsSection(),
          const SizedBox(height: 24),
          _buildHelpAndVersionSection(),
        ],
      ),
    );
  }
}
