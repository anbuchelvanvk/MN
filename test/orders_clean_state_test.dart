import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mn_family_app/models/online_order_model.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/orders/online_orders_handler_screen.dart';

void main() {
  testWidgets('OnlineOrdersHandler starts with 0 orders and renders empty state cleanly', (tester) async {
    final eco = EcosystemProvider();

    // Verify initial clean state: 0 mock orders
    expect(eco.onlineOrders, isEmpty);
    expect(eco.os1Orders, isEmpty);
    expect(eco.os2Orders, isEmpty);
    expect(eco.overdueOnlineOrders, isEmpty);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<EcosystemProvider>.value(
          value: eco,
          child: const OnlineOrdersHandlerScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Must show empty state widgets
    expect(find.text('No Active Orders'), findsOneWidget);
    expect(find.text('Create Order'), findsOneWidget);
    // Should NOT have mock orders
    expect(find.text('ORD-MN-901'), findsNothing);
    expect(find.text('ORD-VD-405'), findsNothing);

    // Verify creating an order adds it and renders it properly
    final newOrder = OnlineOrderModel(
      orderId: 'ORD-TEST-101',
      customerName: 'Real Customer',
      salesChannel: 'WhatsApp',
      handledByEmpId: 'MN-1007',
      handledByName: 'Kaaviya',
      brand: 'MN Jewel Park',
      expectedDeliveryDate: '2026-11-20',
      createdAt: '2026-11-04',
      stages: OnlineOrderModel.createDefaultStages(),
      checklist: OnlineOrderModel.createDefaultChecklist(),
    );

    eco.createOnlineOrder(newOrder);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('ORD-TEST-101'), findsWidgets);
    expect(find.text('Real Customer'), findsWidgets);
    expect(find.text('No Active Orders'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
