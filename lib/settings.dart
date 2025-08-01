import 'package:flutter/material.dart';
import 'account_dao.dart';
import 'account_model.dart';
import 'bank_dao.dart';
import 'transaction_dao.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<Account> accounts = [];
  Account? activeAccount;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accs = await AccountDao().getAllAccounts();
    setState(() {
      accounts = accs;
      activeAccount = accs.isNotEmpty ? accs.firstWhere((a) => a.isActive, orElse: () => accs.first) : null;
      isLoading = false;
    });
  }

  Future<void> _setActiveAccount(Account acc) async {
    await AccountDao().setActiveAccount(acc.accountId!);
    _loadAccounts();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Active account set to ${acc.accountNumber}')));
  }

  Future<void> _removeAccount(Account acc) async {
    await AccountDao().deleteAccount(acc.accountId!);
    _loadAccounts();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Account removed')));
  }

  Future<void> _clearTransactions() async {
    await TransactionDao().clearAllTransactions();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All transactions cleared')));
  }

  void _exportTransactions() {
    // TODO: Implement CSV/Excel export
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exported to CSV')));
  }

  void _importTransactions() {
    // TODO: Implement import logic
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import feature not implemented')));
  }

  void _editSmsBox(Account acc) async {
    final controller = TextEditingController(text: acc.bank?.smsAddressBox ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit SMS Address'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'SMS Address')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await BankDao().updateSmsAddress(acc.bankId!, result);
      _loadAccounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Active Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (activeAccount != null)
                  ListTile(
                    title: Text('${activeAccount!.accountNumber}'),
                    subtitle: Text(activeAccount!.bank?.name ?? 'Unknown Bank'),
                    trailing: const Icon(Icons.check_circle, color: Colors.green),
                  )
                else
                  const Text('No active account'),

                const SizedBox(height: 20),
                const Text('Linked Accounts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ...accounts.map((acc) {
                  return Card(
                    child: ListTile(
                      title: Text(acc.accountNumber),
                      subtitle: Text(acc.bank?.name ?? 'Unknown Bank'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'active') _setActiveAccount(acc);
                          if (value == 'remove') _removeAccount(acc);
                          if (value == 'editSms') _editSmsBox(acc);
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'active', child: Text('Set Active')),
                          const PopupMenuItem(value: 'editSms', child: Text('Edit SMS Address')),
                          const PopupMenuItem(value: 'remove', child: Text('Remove Account')),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to add account form (reuse registration)
                    Navigator.pushNamed(context, '/addAccount');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Account'),
                  style: ElevatedButton.styleFrom(backgroundColor: primary),
                ),

                const SizedBox(height: 30),
                const Text('Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Clear All Transactions'),
                  onTap: _clearTransactions,
                ),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Export Transactions (CSV)'),
                  onTap: _exportTransactions,
                ),
                ListTile(
                  leading: const Icon(Icons.upload),
                  title: const Text('Import Backup'),
                  onTap: _importTransactions,
                ),
              ],
            ),
    );
  }
}
