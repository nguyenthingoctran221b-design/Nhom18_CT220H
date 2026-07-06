import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order.dart';
import '../../core/utils/pdf_invoice_helper.dart';

/// Chế độ lọc hóa đơn
enum FilterMode { all, table, day, month }

/// Trung Tâm Quản Lý Hóa Đơn & Lịch Sử Giao Dịch (CashierHistoryScreen)
/// Cung cấp giao diện quản trị lịch sử hóa đơn nâng cao dành cho Thu ngân:
/// - Tìm kiếm thời gian thực: Theo Mã bàn hoặc Tên món ăn trong hóa đơn.
/// - Lọc theo chế độ: Tất cả, Theo Bàn (nhập mã bàn), Theo Ngày (chọn lịch), Theo Tháng (chọn dropdown).
/// - Hủy Hóa Đơn: Thực hiện xóa chứng từ hóa đơn lỗi trên Firestore.
/// - In Lại Hóa Đơn: Xuất trực tiếp PDF xem trước in lại hóa đơn bất kỳ lúc nào.
class CashierHistoryScreen extends StatefulWidget {
  final bool embedMode;
  const CashierHistoryScreen({super.key, this.embedMode = false});

  @override
  State<CashierHistoryScreen> createState() => _CashierHistoryScreenState();
}

class _CashierHistoryScreenState extends State<CashierHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _tableFilterController = TextEditingController();

  FilterMode _filterMode = FilterMode.all;
  String _tableFilter = '';
  DateTime _dayFilter = DateTime.now();
  int _monthFilter = DateTime.now().month;
  int _yearFilter = DateTime.now().year;
  String _searchKeyword = '';

  String _formatPrice(int price) {
    final formatted = price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$formatted ₫';
  }

  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'cash':
        return 'Tiền mặt';
      case 'ewallet':
        return 'Momo / ZaloPay';
      case 'bank':
        return 'Thẻ ngân hàng';
      default:
        return 'Không rõ';
    }
  }

  Future<void> _deleteInvoice(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận Hủy hóa đơn'),
        content: const Text('Hành động này sẽ xóa hoàn toàn hóa đơn khỏi cơ sở dữ liệu. Bạn có chắc chắn muốn hủy hóa đơn này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Quay lại', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy hóa đơn'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('invoices').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy hóa đơn thành công!')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tableFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm dd/MM/yyyy');

    final mainContent = Column(
      children: [
          // Filter Panel Box
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bộ lọc hóa đơn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 12),
                
                // Choice Chips
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: _filterMode == FilterMode.all,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: _filterMode == FilterMode.all ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                      onSelected: (val) {
                        if (val) setState(() => _filterMode = FilterMode.all);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Theo Bàn'),
                      selected: _filterMode == FilterMode.table,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: _filterMode == FilterMode.table ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                      onSelected: (val) {
                        if (val) setState(() => _filterMode = FilterMode.table);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Theo Ngày'),
                      selected: _filterMode == FilterMode.day,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: _filterMode == FilterMode.day ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                      onSelected: (val) {
                        if (val) setState(() => _filterMode = FilterMode.day);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Theo Tháng'),
                      selected: _filterMode == FilterMode.month,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: _filterMode == FilterMode.month ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                      onSelected: (val) {
                        if (val) setState(() => _filterMode = FilterMode.month);
                      },
                    ),
                  ],
                ),
                
                // Active filter input
                if (_filterMode == FilterMode.table) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tableFilterController,
                    onChanged: (val) {
                      setState(() {
                        _tableFilter = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Nhập số bàn cần lọc (ví dụ: A01, B05)...',
                      prefixIcon: const Icon(Icons.table_restaurant, color: AppColors.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ] else if (_filterMode == FilterMode.day) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _dayFilter,
                            firstDate: DateTime(2022),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _dayFilter = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
                        label: Text('Chọn ngày: ${DateFormat('dd/MM/yyyy').format(_dayFilter)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ] else if (_filterMode == FilterMode.month) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _monthFilter,
                          decoration: InputDecoration(
                            labelText: 'Tháng',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: List.generate(12, (i) => i + 1).map((m) {
                            return DropdownMenuItem(value: m, child: Text('Tháng $m'));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _monthFilter = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _yearFilter,
                          decoration: InputDecoration(
                            labelText: 'Năm',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: List.generate(5, (i) => DateTime.now().year - i).map((y) {
                            return DropdownMenuItem(value: y, child: Text('Năm $y'));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _yearFilter = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ],

                const Divider(height: 24),
                
                // General keyword search bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchKeyword = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên món ăn hoặc bàn...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: _searchKeyword.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchKeyword = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Invoices List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('invoices')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Không tìm thấy hóa đơn nào trong database.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                var docs = snapshot.data!.docs;

                // 1. Apply primary filter mode
                if (_filterMode == FilterMode.table && _tableFilter.isNotEmpty) {
                  final q = _tableFilter.toLowerCase().replaceAll('-', '');
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final tableId = (data['tableId'] ?? '').toString().toLowerCase().replaceAll('-', '');
                    return tableId.contains(q);
                  }).toList();
                } else if (_filterMode == FilterMode.day) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final ts = data['createdAt'] as Timestamp?;
                    if (ts == null) return false;
                    final date = ts.toDate();
                    return date.day == _dayFilter.day &&
                           date.month == _dayFilter.month &&
                           date.year == _dayFilter.year;
                  }).toList();
                } else if (_filterMode == FilterMode.month) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final ts = data['createdAt'] as Timestamp?;
                    if (ts == null) return false;
                    final date = ts.toDate();
                    return date.month == _monthFilter && date.year == _yearFilter;
                  }).toList();
                }

                // 2. Apply search keyword
                if (_searchKeyword.isNotEmpty) {
                  final kw = _searchKeyword.toLowerCase();
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final tableId = (data['tableId'] ?? '').toString().toLowerCase();
                    if (tableId.contains(kw)) return true;

                    // Match dishes inside orders list
                    final ordersList = data['orders'] as List<dynamic>? ?? [];
                    for (var orderMap in ordersList) {
                      final itemsList = orderMap['items'] as List<dynamic>? ?? [];
                      for (var itemMap in itemsList) {
                        final String name = (itemMap['name'] ?? '').toString().toLowerCase();
                        if (name.contains(kw)) return true;
                      }
                    }
                    return false;
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Không tìm thấy hóa đơn phù hợp.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final tableId = data['tableId'] ?? 'K/O';
                    final grandTotal = (data['grandTotal'] as num?)?.toDouble() ?? 0.0;
                    final paymentMethod = data['paymentMethod'] ?? 'cash';
                    
                    final createdAtTimestamp = data['createdAt'] as Timestamp?;
                    final startedAtTimestamp = data['startedAt'] as Timestamp?;
                    
                    final createdAt = createdAtTimestamp?.toDate() ?? DateTime.now();
                    final startedAt = startedAtTimestamp?.toDate();

                    final List<dynamic> ordersList = data['orders'] as List<dynamic>? ?? [];
                    final List<OrderItem> items = [];
                    for (var orderMap in ordersList) {
                      final itemsList = orderMap['items'] as List<dynamic>? ?? [];
                      for (var itemMap in itemsList) {
                        items.add(OrderItem.fromMap(itemMap as Map<String, dynamic>));
                      }
                    }

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(tableId, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(
                          'Bàn $tableId - ${_formatPrice(grandTotal.toInt())}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Text(
                          'Thanh toán lúc: ${dateFormat.format(createdAt)}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Giờ gọi món: ${startedAt != null ? dateFormat.format(startedAt) : 'Chưa cập nhật'}',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      'Hình thức: ${_getPaymentMethodText(paymentMethod)}',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                const Text(
                                  'Danh sách món ăn đã thanh toán:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                                ),
                                const SizedBox(height: 8),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: items.length,
                                  itemBuilder: (context, idx) {
                                    final item = items[idx];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${item.quantity} x ${item.name}', style: const TextStyle(fontSize: 14)),
                                          Text(_formatPrice(item.total.toInt()), style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            final dummyOrder = OrderModel(
                                              tableInfo: tableId,
                                              totalAmount: grandTotal,
                                              createdAt: createdAt,
                                            );
                                            PdfInvoiceHelper.generateAndPrintInvoice(
                                              [dummyOrder],
                                              tableId,
                                              overrideItems: items,
                                              overrideTotal: grandTotal,
                                            );
                                          },
                                          icon: const Icon(Icons.print, size: 18),
                                          label: const Text('In lại hóa đơn'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.secondary,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        TextButton.icon(
                                          onPressed: () => _deleteInvoice(doc.id),
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                          label: const Text('Hủy hóa đơn', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Tổng tiền: ${_formatPrice(grandTotal.toInt())}',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );

    if (widget.embedMode) {
      return mainContent;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trung Tâm Quản Lý Hóa Đơn & Lịch Sử Giao Dịch', style: TextStyle(fontFamily: 'Playfair Display', fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: mainContent,
    );
  }
}
