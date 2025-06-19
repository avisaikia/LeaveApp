import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/leave_balance_model.dart';

class LeaveBalanceProvider with ChangeNotifier {
  LeaveBalance? _balance;
  LeaveBalance? get balance => _balance;

  Future<void> fetchBalance(String userId) async {
    final supabase = Supabase.instance.client;

    final response =
        await supabase
            .from('leave_balances')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

    if (response != null) {
      _balance = LeaveBalance.fromJson(response);
    } else {
      // No balance found, so insert default
      final insertData = {
        'user_id': userId,
        'total_leaves': 20,
        'used_leaves': 0,
      };

      final inserted =
          await supabase
              .from('leave_balances')
              .insert(insertData)
              .select()
              .single();

      _balance = LeaveBalance.fromJson(inserted);
    }

    notifyListeners();

    print('fetchBalance response: $_balance');
  }
}
