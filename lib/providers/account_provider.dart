import 'package:flutter/material.dart';
import '../dao/account_dao.dart';
import '../models/account_model.dart';
import '../dao/bank_dao.dart';
import '../models/bank_model.dart';
import '../dao/user_dao.dart';
import '../models/user_model.dart';

class AccountProvider extends ChangeNotifier {
  Account? _activeAccount;
  Bank? _bank;
  User? _user;

  Account? get activeAccount => _activeAccount;
  Bank? get bank => _bank;
  User? get user => _user;

  Future<void> loadActiveAccount() async {
    try {
      debugPrint('[AccountProvider] Loading active account...');
      final account = await AccountDao().getActiveAccount();
      
      if (account == null) {
        debugPrint('[AccountProvider] No active account found');
        _setFallbackValues();
        return;
      }

      debugPrint('[AccountProvider] Loaded account: ${account.accountNumber}');
      debugPrint('[AccountProvider] Account user ID: ${account.userId}');
      debugPrint('[AccountProvider] Account bank ID: ${account.bankId}');

      if (account.bankId == null) {
        debugPrint('[AccountProvider] Account has null bankId');
        _setFallbackValues();
        return;
      }

      _activeAccount = account;

      // Load bank with error logging
      try {
        _bank = await BankDao().getBankById(account.bankId!);
        debugPrint(_bank != null 
            ? '[AccountProvider] Loaded bank: ${_bank!.name}'
            : '[AccountProvider] Bank not found for ID: ${account.bankId}');
      } catch (e) {
        debugPrint('[AccountProvider] Error loading bank: $e');
        _bank = Bank(bankId: 0, name: 'Unknown Bank', smsAddressBox: '626626');
      }

      // Load user with detailed error logging
      try {
        if (account.userId == null) {
          debugPrint('[AccountProvider] Account has null userId');
        } else {
          _user = await UserDao().getUserById(account.userId);
          if (_user == null) {
            debugPrint('[AccountProvider] User not found for ID: ${account.userId}');
            // Add temporary debug to check all users
            final allUsers = await UserDao().getAllUsers();
            debugPrint('[AccountProvider] All users in DB: ${allUsers.map((u) => '${u.userId}:${u.firstName}').join(', ')}');
          } else {
            debugPrint('[AccountProvider] Loaded user: ${_user!.firstName} ${_user!.lastName}');
          }
        }
      } catch (e) {
        debugPrint('[AccountProvider] Error loading user: $e');
      }

      // Ensure we have fallback user if loading failed
      if (_user == null) {
        debugPrint('[AccountProvider] Using fallback user');
        _user = User(userId: 0, firstName: 'User', lastName: '');
      }

      notifyListeners();
      debugPrint('[AccountProvider] Account data loaded successfully');
    } catch (e, stack) {
      debugPrint('[AccountProvider] Critical error in loadActiveAccount: $e');
      debugPrint(stack.toString());
      _setFallbackValues();
    }
  }

  void _setFallbackValues() {
    debugPrint('[AccountProvider] Setting fallback values');
    _bank = Bank(bankId: 0, name: 'Unknown Bank', smsAddressBox: '626626');
    _user = User(userId: 0, firstName: 'User', lastName: '');
    notifyListeners();
  }

  Future<void> switchAccount(Account newAccount) async {
    debugPrint('[AccountProvider] Switching account to: ${newAccount.accountNumber}');
    await loadActiveAccount();
  }
}