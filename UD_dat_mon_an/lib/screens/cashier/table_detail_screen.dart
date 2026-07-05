import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../models/table_model.dart';
import '../../models/order.dart';
import '../../core/utils/pdf_invoice_helper.dart';

class TableDetailScreen extends StatefulWidget {
  final TableModel table;

  const TableDetailScreen({super.key, required this.table});

  @override
  State<TableDetailScreen> createState() => _TableDetailScreenState();
}

class _TableDetailScreenState extends State<TableDetailScreen> {
  bool _isLoading = false;

  Future<void> _updateTableStatus(String status) async {
    await FirebaseFirestore.instance.collection('tables').doc(widget.table.id).update({
      'status': status,
      if (status == 'occupied') 'entryTime': FieldValue.serverTimestamp(),
      if (status == 'empty') 'entryTime': null,
    });
    if (mounted) Navigator.pop(context);
  }

  Future<void> _checkout(List<OrderModel> orders, double grandTotal) async {
    setState(() => _isLoading = true);

    try {
      // 1. Show payment method dialog
      final paymentMethod = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Chọn hình thức thanh toán'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.money),
                  title: const Text('Tiền mặt'),
                  onTap: () => Navigator.pop(context, 'cash'),
                ),
                ListTile(
                  leading: const Icon(Icons.qr_code),
                  title: const Text('MoMo / ZaloPay'),
                  onTap: () => Navigator.pop(context, 'ewallet'),
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance),
                  title: const Text('Thẻ Ngân Hàng'),
                  onTap: () => Navigator.pop(context, 'bank'),
                ),
              ],
            ),
          );
        },
      );

      if (paymentMethod == null) {
        setState(() => _isLoading = false);
        return; // Canceled
      }

      // 2. Print Invoice
      await PdfInvoiceHelper.generateAndPrintInvoice(orders, widget.table.id);

      // 3. Save Invoice to Firebase
      final invoice = {
        'tableId': widget.table.id,
        'orders': orders.map((o) => o.toMap()).toList(),
        'grandTotal': grandTotal,
        'paymentMethod': paymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance.collection('invoices').add(invoice);

      // 4. Mark orders as paid or delete them (we can just delete them to clear the table, or update status)
      final batch = FirebaseFirestore.instance.batch();
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('tableInfo', isEqualTo: widget.table.id)
          .get();
          
      for (var doc in ordersSnapshot.docs) {
        batch.update(doc.reference, {'status': 'paid'}); // or delete
      }
      await batch.commit();

      // 5. Update table to empty
      await FirebaseFirestore.instance.collection('tables').doc(widget.table.id).update({
        'status': 'empty',
        'entryTime': null,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanh toán thành công!')));
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết Bàn ${widget.table.id}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('tableInfo', isEqualTo: widget.table.id)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data?.docs.map((doc) => OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList() ?? [];
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          double grandTotal = 0;
          for (var o in orders) {
            grandTotal += o.totalAmount;
          }

          return Row(
            children: [
              // Left: Orders List
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Các món đã gọi:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (orders.isEmpty)
                        const Expanded(child: Center(child: Text('Bàn này chưa gọi món nào.')))
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return Card(
                                child: ExpansionTile(
                                  initiallyExpanded: true,
                                  title: Text('Đơn ${order.id?.substring(0, 5)} - ${_formatPrice(order.totalAmount.toInt())}'),
                                  children: order.orderItems?.map((item) {
                                    return ListTile(
                                      title: Text(item.name),
                                      subtitle: Text('${item.quantity} x ${_formatPrice(item.price)}'),
                                      trailing: Text(_formatPrice(item.total.toInt()), style: const TextStyle(fontWeight: FontWeight.bold)),
                                      // Here we could add an edit/delete button to modify the order
                                      // If cashier removes an item, update Firestore so Chef sees it.
                                    );
                                  }).toList() ?? [],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Right: Actions
              Expanded(
                flex: 1,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Tổng cộng:\n${_formatPrice(grandTotal.toInt())}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // Status controls
                      if (widget.table.status == 'empty')
                        ElevatedButton.icon(
                          onPressed: () => _updateTableStatus('occupied'),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Mở bàn (Khách vào)'),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                        ),
                      if (widget.table.status == 'empty')
                        const SizedBox(height: 16),
                      if (widget.table.status == 'empty')
                        ElevatedButton.icon(
                          onPressed: () => _updateTableStatus('booked'),
                          icon: const Icon(Icons.book_online),
                          label: const Text('Đặt trước bàn'),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.orange),
                        ),
                      if (widget.table.status != 'empty')
                        ElevatedButton.icon(
                          onPressed: () => _updateTableStatus('empty'),
                          icon: const Icon(Icons.clear),
                          label: const Text('Hủy bàn / Trống'),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.grey),
                        ),

                      const Spacer(),

                      // Checkout button
                      ElevatedButton.icon(
                        onPressed: orders.isEmpty || _isLoading ? null : () => _checkout(orders, grandTotal),
                        icon: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.payment),
                        label: const Text('THANH TOÁN', style: TextStyle(fontSize: 20)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(24),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatPrice(int price) {
    final formatted = price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$formatted ₫';
  }
}
