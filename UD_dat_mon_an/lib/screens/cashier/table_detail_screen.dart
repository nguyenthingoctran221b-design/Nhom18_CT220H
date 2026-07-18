import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../models/table_model.dart';
import '../../models/order.dart';
import '../../core/utils/pdf_invoice_helper.dart';

/// Chi Tiết Gọi Món & Thanh Toán (TableDetailScreen)
/// Màn hình đối soát và thanh toán tại bàn ăn dành cho Thu ngân:
/// - Đối soát: Phân tách rõ ràng giữa món Đã chế biến xong (status == 'done') và món Đang chờ/đang chế biến.
/// - In Hóa Đơn Tạm Tính: Cho phép kết xuất PDF hóa đơn theo bàn ăn chỉ tính tiền các món đã được bếp chế biến xong.
/// - Thanh Toán (Checkout):
///   1. Chọn hình thức thanh toán (Tiền mặt / Chuyển khoản QR).
///   2. Lưu hóa đơn chính thức vào collection 'invoices' làm lịch sử doanh thu cho quản lý.
///   3. Lưu lịch sử gọi món của phiên này sang hóa đơn thu ngân và xóa lịch sử phiên hiện tại ở máy khách.
///   4. Reset trạng thái bàn về Trống (empty) nếu không còn món ăn nào chờ chế biến.
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
      if (status == 'empty' || status == 'locked' || status == 'booked') 'entryTime': null,
    });
    if (mounted) Navigator.pop(context);
  }

  Future<void> _checkout(List<OrderModel> orders, List<OrderItem> doneItems, double grandTotal) async {
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
      await PdfInvoiceHelper.generateAndPrintInvoice(
        orders,
        widget.table.id,
        overrideItems: doneItems,
        overrideTotal: grandTotal,
      );

      // 3. Save Invoice to Firebase
      DateTime startedAt = widget.table.entryTime ?? DateTime.now();
      if (orders.isNotEmpty) {
        final earliest = orders.map((o) => o.createdAt).reduce((a, b) => a.isBefore(b) ? a : b);
        if (earliest.isBefore(startedAt)) {
          startedAt = earliest;
        }
      }

      final invoice = {
        'tableId': widget.table.id,
        'orders': [
          {
            'tableInfo': widget.table.id,
            'items': doneItems.map((item) => {
              'id': item.id,
              'name': item.name,
              'price': item.price,
              'quantity': item.quantity,
              'total': item.total,
              'tfp': item.tfp,
              'status': 'paid',
              'acceptedAt': item.acceptedAt != null ? Timestamp.fromDate(item.acceptedAt!) : null,
              'chefId': item.chefId,
            }).toList(),
            'totalAmount': grandTotal,
            'createdAt': Timestamp.fromDate(startedAt),
            'status': 'paid',
          }
        ],
        'grandTotal': grandTotal,
        'paymentMethod': paymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
        'startedAt': Timestamp.fromDate(startedAt), // Giờ bắt đầu gọi món
      };
      await FirebaseFirestore.instance.collection('invoices').add(invoice);

      // 4. Update orders in Firestore
      final batch = FirebaseFirestore.instance.batch();
      bool hasRemaining = false;

      for (var order in orders) {
        if (order.id == null || order.orderItems == null) continue;
        final docRef = FirebaseFirestore.instance.collection('orders').doc(order.id);
        
        final doneInThisOrder = order.orderItems!.where((item) => item.status == 'done' || item.status == 'pending').toList();
        final remainingInThisOrder = order.orderItems!.where((item) => item.status == 'cooking').toList();

        if (remainingInThisOrder.isEmpty) {
          // All items in this order are paid
          batch.update(docRef, {
            'status': 'paid',
            'items': order.orderItems!.map((item) => {
              'id': item.id,
              'name': item.name,
              'price': item.price,
              'quantity': item.quantity,
              'total': item.total,
              'tfp': item.tfp,
              'status': 'paid',
              'acceptedAt': item.acceptedAt != null ? Timestamp.fromDate(item.acceptedAt!) : null,
              'chefId': item.chefId,
            }).toList(),
          });
        } else {
          hasRemaining = true;
          double newTotal = 0;
          for (var item in remainingInThisOrder) {
            newTotal += item.total;
          }
          batch.update(docRef, {
            'items': remainingInThisOrder.map((item) => {
              'id': item.id,
              'name': item.name,
              'price': item.price,
              'quantity': item.quantity,
              'total': item.total,
              'tfp': item.tfp,
              'status': item.status,
              'acceptedAt': item.acceptedAt != null ? Timestamp.fromDate(item.acceptedAt!) : null,
              'chefId': item.chefId,
            }).toList(),
            'totalAmount': newTotal,
          });
        }
      }
      await batch.commit();

      // 5. Update table to empty if no remaining items
      if (!hasRemaining) {
        await FirebaseFirestore.instance.collection('tables').doc(widget.table.id).update({
          'status': 'empty',
          'entryTime': null,
        });
      }

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
        title: Text('Chi Tiết Gọi Món & Thanh Toán - Bàn ${widget.table.id}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('tableInfo', whereIn: [
              widget.table.id,
              widget.table.id.replaceAll('-', ''),
              if (widget.table.id.replaceAll('-', '').length >= 2)
                '${widget.table.id.replaceAll('-', '').substring(0, 1)}-${widget.table.id.replaceAll('-', '').substring(1)}'
            ].toSet().toList())
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data?.docs.map((doc) => OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList() ?? [];
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          final bool isOccupied = widget.table.status == 'occupied' || orders.isNotEmpty;

          final List<OrderItem> doneItems = []; // Thanh toán được (done + pending)
          final List<OrderItem> nonDoneItems = []; // Khóa thanh toán (cooking)

          for (var order in orders) {
            if (order.orderItems != null) {
              for (var item in order.orderItems!) {
                if (item.status == 'done' || item.status == 'pending') {
                  doneItems.add(item);
                } else if (item.status == 'cooking') {
                  nonDoneItems.add(item);
                }
              }
            }
          }

          double grandTotal = 0;
          for (var item in doneItems) {
            grandTotal += item.total;
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
                      const Text('Chi tiết món ăn theo trạng thái', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      const SizedBox(height: 16),
                      if (orders.isEmpty)
                        const Expanded(child: Center(child: Text('Bàn này chưa gọi món nào.')))
                      else
                        Expanded(
                          child: ListView(
                            children: [
                              // Món đã hoàn thành (Tính tiền)
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.green),
                                          SizedBox(width: 8),
                                          Text(
                                            'Món thanh toán đợt này (Đã xong / Chưa chế biến)',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      if (doneItems.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 8),
                                          child: Text('Chưa có món nào để thanh toán.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                                        )
                                      else
                                        ...doneItems.map((item) => ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text('${item.quantity} x ${_formatPrice(item.price)}'),
                                          trailing: Text(_formatPrice(item.total.toInt()), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                        )),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Món đang chế biến
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.hourglass_empty, color: Colors.orange),
                                          SizedBox(width: 8),
                                          Text(
                                            'Món đang chế biến (Khóa thanh toán)',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      if (nonDoneItems.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 8),
                                          child: Text('Không có món nào đang chế biến.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                                        )
                                      else
                                        ...nonDoneItems.map((item) {
                                          final String statusStr = item.status == 'cooking' ? 'Đang nấu' : 'Đang đợi';
                                          return ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: Text(item.name),
                                            subtitle: Text('${item.quantity} x ${_formatPrice(item.price)}'),
                                            trailing: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: item.status == 'cooking' ? Colors.orange.shade100 : Colors.red.shade100,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                statusStr,
                                                style: TextStyle(
                                                  color: item.status == 'cooking' ? Colors.orange.shade800 : Colors.red.shade800,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
                          onPressed: isOccupied ? null : () => _updateTableStatus('occupied'),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Mở bàn (Khách vào)'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: isOccupied ? Colors.grey.shade300 : null,
                          ),
                        ),
                      if (widget.table.status == 'empty')
                        const SizedBox(height: 16),
                      if (widget.table.status == 'empty')
                        ElevatedButton.icon(
                          onPressed: isOccupied ? null : () => _updateTableStatus('booked'),
                          icon: const Icon(Icons.book_online),
                          label: const Text('Đặt trước bàn'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16), 
                            backgroundColor: isOccupied ? Colors.grey.shade300 : Colors.orange,
                          ),
                        ),
                      if (widget.table.status == 'empty')
                        const SizedBox(height: 16),
                      if (widget.table.status == 'empty')
                        ElevatedButton.icon(
                          onPressed: isOccupied ? null : () => _updateTableStatus('locked'),
                          icon: const Icon(Icons.lock),
                          label: const Text('Khóa / Sửa chữa'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16), 
                            backgroundColor: isOccupied ? Colors.grey.shade300 : Colors.amber.shade700,
                          ),
                        ),
                      if (widget.table.status != 'empty')
                        ElevatedButton.icon(
                          onPressed: isOccupied ? null : () => _updateTableStatus('empty'),
                          icon: const Icon(Icons.clear),
                          label: Text(widget.table.status == 'locked' ? 'Mở khóa / Trống' : 'Hủy bàn / Trống'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16), 
                            backgroundColor: isOccupied ? Colors.grey.shade300 : Colors.grey,
                          ),
                        ),

                      const Spacer(),

                      // Checkout button
                      ElevatedButton.icon(
                        onPressed: doneItems.isEmpty || _isLoading ? null : () => _checkout(orders, doneItems, grandTotal),
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
