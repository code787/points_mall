import 'package:flutter/material.dart';

import 'widgets/points_transactions_list.dart';
import 'widgets/redemption_requests_list.dart';

class TransactionCenterScreen extends StatelessWidget {
  const TransactionCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('流水查询'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '积分流水'),
              Tab(text: '兑换申请'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PointsTransactionsList(),
            RedemptionRequestsList(),
          ],
        ),
      ),
    );
  }
}
