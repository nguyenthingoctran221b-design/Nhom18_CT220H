import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/app_colors.dart';
import '../../models/table_model.dart';
import '../../core/utils/dummy_data_generator.dart';
import 'menu_management_screen.dart';

/// Hệ Thống Quản Trị & Báo Cáo Doanh Thu (ManagerDashboard)
/// Bảng điều khiển quản trị tối cao của Nhà hàng dành cho Quản lý.
/// Cung cấp 3 phân hệ cốt lõi:
/// - 1. Phân hệ Báo cáo Doanh thu (Tab 0): Xem KPI bán hàng, Biểu đồ tuần và Biểu đồ đường so sánh 7 ngày.
/// - 2. Phân hệ Quản trị Bàn ăn & Khu vực (Tab 1): Thêm bàn, sửa khu vực/số thứ tự, xóa bàn ăn.
/// - 3. Phân hệ Thực đơn Catalog (Tab 2): Quản trị thêm, sửa, xóa các món ăn, thiết lập giá và tình trạng còn món.
class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _selectedIndex = 0; // 0: Doanh thu, 1: Bàn ăn, 2: Món ăn
  String _selectedArea = 'All'; // Filter bàn: 'All', 'A', 'B', 'C'

  // Controllers cho Thêm bàn ăn (Table management)
  final TextEditingController _tableIdCtrl = TextEditingController();
  final TextEditingController _tableNumberCtrl = TextEditingController();
  String _newTableArea = 'A';

  double _calculateTotalRevenue(List<QueryDocumentSnapshot> invoices) {
    double total = 0;
    for (var doc in invoices) {
      total += (doc['grandTotal'] as num).toDouble();
    }
    return total;
  }

  void _calculateWeeklyRevenue(List<QueryDocumentSnapshot> invoices, List<double> thisMonthWeeks, List<double> lastMonthWeeks) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    final lastMonthDate = DateTime(now.year, now.month - 1, 1);
    final prevMonth = lastMonthDate.month;
    final prevYear = lastMonthDate.year;

    for (var doc in invoices) {
      final data = doc.data() as Map<String, dynamic>;
      final createdAtField = data['createdAt'];
      if (createdAtField == null) continue;
      
      final DateTime date = (createdAtField as Timestamp).toDate();
      final double grandTotal = (data['grandTotal'] as num?)?.toDouble() ?? 0.0;
      
      int weekIdx = 0;
      if (date.day <= 7) weekIdx = 0;
      else if (date.day <= 14) weekIdx = 1;
      else if (date.day <= 21) weekIdx = 2;
      else weekIdx = 3;

      if (date.month == currentMonth && date.year == currentYear) {
        thisMonthWeeks[weekIdx] += grandTotal;
      } else if (date.month == prevMonth && date.year == prevYear) {
        lastMonthWeeks[weekIdx] += grandTotal;
      }
    }
  }

  void _calculateDailyRevenue7Days(List<QueryDocumentSnapshot> invoices, List<double> thisMonthDays, List<double> lastMonthDays) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    final lastMonthDate = DateTime(now.year, now.month - 1, 1);
    final prevMonth = lastMonthDate.month;
    final prevYear = lastMonthDate.year;

    for (var doc in invoices) {
      final data = doc.data() as Map<String, dynamic>;
      final createdAtField = data['createdAt'];
      if (createdAtField == null) continue;
      
      final DateTime date = (createdAtField as Timestamp).toDate();
      final double grandTotal = (data['grandTotal'] as num?)?.toDouble() ?? 0.0;
      
      if (date.day >= 1 && date.day <= 7) {
        int dayIdx = date.day - 1;
        if (date.month == currentMonth && date.year == currentYear) {
          thisMonthDays[dayIdx] += grandTotal;
        } else if (date.month == prevMonth && date.year == prevYear) {
          lastMonthDays[dayIdx] += grandTotal;
        }
      }
    }
  }

  @override
  void dispose() {
    _tableIdCtrl.dispose();
    _tableNumberCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════
  //  DIALOGS FOR TABLE MANAGEMENT
  // ═══════════════════════════════════════════════
  Future<void> _showAddTableDialog() async {
    _tableIdCtrl.clear();
    _tableNumberCtrl.clear();
    _newTableArea = 'A';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Thêm bàn ăn mới', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _tableIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mã bàn (ví dụ: A21, C15)',
                      prefixIcon: Icon(Icons.table_restaurant),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _newTableArea,
                    decoration: const InputDecoration(labelText: 'Khu vực'),
                    items: ['A', 'B', 'C'].map((area) {
                      return DropdownMenuItem(value: area, child: Text('Khu vực $area'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          _newTableArea = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tableNumberCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số thứ tự bàn (ví dụ: 21)',
                      prefixIcon: Icon(Icons.format_list_numbered),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  onPressed: () async {
                    final id = _tableIdCtrl.text.trim().toUpperCase();
                    final numVal = int.tryParse(_tableNumberCtrl.text.trim()) ?? 0;

                    if (id.isEmpty || numVal <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập thông tin hợp lệ.')),
                      );
                      return;
                    }

                    final doc = await FirebaseFirestore.instance.collection('tables').doc(id).get();
                    if (doc.exists) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mã bàn đã tồn tại.')),
                        );
                      }
                      return;
                    }

                    final newTable = TableModel(
                      id: id,
                      area: _newTableArea,
                      number: numVal,
                      status: 'empty',
                    );

                    await FirebaseFirestore.instance.collection('tables').doc(id).set(newTable.toMap());
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã thêm bàn $id thành công!')),
                      );
                    }
                  },
                  child: const Text('Thêm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showChangeTableStatusDialog(TableModel table) async {
    // Quản lý không được thay đổi trạng thái bàn đang có khách hoặc đã đặt trước
    if (table.status == 'occupied' || table.status == 'booked') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Không thể thay đổi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text('Bàn ${table.id} đang ${table.status == 'occupied' ? 'có khách' : 'được đặt trước'}. Quản lý không thể trực tiếp thay đổi trạng thái này.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      return;
    }

    // Chỉ cho phép khóa (empty -> locked) hoặc mở khóa (locked -> empty)
    final isCurrentlyLocked = table.status == 'locked';
    final title = isCurrentlyLocked ? 'Mở khóa bàn ${table.id}' : 'Khóa bàn ${table.id}';
    final content = isCurrentlyLocked
        ? 'Bạn có chắc chắn muốn mở khóa bàn ${table.id}? Bàn sẽ trở lại trạng thái Trống.'
        : 'Bạn có chắc chắn muốn khóa bàn ${table.id}? Khách hàng và thu ngân sẽ không thể tương tác với bàn này.';
    final actionText = isCurrentlyLocked ? 'Mở khóa' : 'Khóa bàn';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrentlyLocked ? Colors.green : AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newStatus = isCurrentlyLocked ? 'empty' : 'locked';
                await FirebaseFirestore.instance.collection('tables').doc(table.id).update({
                  'status': newStatus,
                  'entryTime': null,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã cập nhật trạng thái bàn ${table.id}')),
                  );
                }
              },
              child: Text(actionText),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTable(TableModel table) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa bàn'),
        content: Text('Bạn có chắc chắn muốn xóa bàn ${table.id} khỏi hệ thống?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('tables').doc(table.id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa bàn ${table.id}')),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════
  //  EXPORT MONTHLY REPORT PDF METHOD
  // ═══════════════════════════════════════════════
  Future<void> _exportMonthlyReport(List<QueryDocumentSnapshot> invoices, int month, int year) async {
    final monthlyInvoices = invoices.where((doc) {
      final createdAtField = doc['createdAt'];
      if (createdAtField == null) return false;
      final DateTime date = (createdAtField as Timestamp).toDate();
      return date.month == month && date.year == year;
    }).toList();

    if (monthlyInvoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không có dữ liệu hóa đơn nào cho Tháng $month/$year.')),
      );
      return;
    }

    double totalRevenue = 0;
    double cashRevenue = 0;
    double ewalletRevenue = 0;
    double bankRevenue = 0;

    final Map<String, int> dishQuantities = {};

    for (var doc in monthlyInvoices) {
      final data = doc.data() as Map<String, dynamic>;
      final grandTotal = (data['grandTotal'] as num?)?.toDouble() ?? 0.0;
      totalRevenue += grandTotal;

      final method = data['paymentMethod'] ?? 'cash';
      if (method == 'cash') {
        cashRevenue += grandTotal;
      } else if (method == 'ewallet') {
        ewalletRevenue += grandTotal;
      } else if (method == 'bank') {
        bankRevenue += grandTotal;
      }

      final ordersList = data['orders'] as List<dynamic>? ?? [];
      for (var orderMap in ordersList) {
        final itemsList = orderMap['items'] as List<dynamic>? ?? [];
        for (var itemMap in itemsList) {
          final String name = itemMap['name'] ?? '';
          final int quantity = (itemMap['quantity'] as num?)?.toInt() ?? 0;
          if (name.isNotEmpty && quantity > 0) {
            dishQuantities[name] = (dishQuantities[name] ?? 0) + quantity;
          }
        }
      }
    }

    final double avgValue = monthlyInvoices.isNotEmpty ? totalRevenue / monthlyInvoices.length : 0.0;

    final sortedDishes = dishQuantities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topDishes = sortedDishes.take(10).toList();

    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text('SEN VÀNG FOOD', style: pw.TextStyle(font: fontBold, fontSize: 24, color: PdfColors.amber800)),
                ),
                pw.Center(
                  child: pw.Text('BÁO CÁO DOANH THU THÁNG $month/$year', style: pw.TextStyle(font: fontBold, fontSize: 18)),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text('Ngày lập báo cáo: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey600)),
                ),
                pw.Divider(height: 24),

                pw.Text('I. TÓM TẮT CHỈ SỐ DOANH THU', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                pw.SizedBox(height: 12),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Chỉ số', style: pw.TextStyle(font: fontBold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Giá trị', style: pw.TextStyle(font: fontBold), textAlign: pw.TextAlign.right)),
                      ]
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Tổng doanh thu', style: pw.TextStyle(font: font))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(_formatPrice(totalRevenue.toInt()), style: pw.TextStyle(font: fontBold, color: PdfColors.green800), textAlign: pw.TextAlign.right)),
                      ]
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Tổng số lượng đơn', style: pw.TextStyle(font: font))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${monthlyInvoices.length} đơn', style: pw.TextStyle(font: font), textAlign: pw.TextAlign.right)),
                      ]
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Giá trị trung bình đơn', style: pw.TextStyle(font: font))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(_formatPrice(avgValue.toInt()), style: pw.TextStyle(font: font), textAlign: pw.TextAlign.right)),
                      ]
                    ),
                  ]
                ),
                pw.SizedBox(height: 24),

                pw.Text('II. CƠ CẤU DOANH THU THEO HÌNH THỨC THANH TOÁN', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                pw.SizedBox(height: 12),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Hình thức', style: pw.TextStyle(font: fontBold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Doanh thu', style: pw.TextStyle(font: fontBold), textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Tỷ lệ %', style: pw.TextStyle(font: fontBold), textAlign: pw.TextAlign.right)),
                      ]
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Tiền mặt', style: pw.TextStyle(font: font))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(_formatPrice(cashRevenue.toInt()), style: pw.TextStyle(font: font), textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${totalRevenue > 0 ? (cashRevenue / totalRevenue * 100).toStringAsFixed(1) : 0}%', style: pw.TextStyle(font: font), textAlign: pw.TextAlign.right)),
                      ]
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('MoMo / ZaloPay', style: pw.TextStyle(font: font))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(_formatPrice(ewalletRevenue.toInt()), style: pw.TextStyle(font: font), textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${totalRevenue > 0 ? (ewalletRevenue / totalRevenue * 100).toStringAsFixed(1) : 0}%', style: pw.TextStyle(font: font), textAlign: pw.TextAlign.right)),
                      ]
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Thẻ Ngân Hàng', style: pw.TextStyle(font: font))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(_formatPrice(bankRevenue.toInt()), style: pw.TextStyle(font: font), textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${totalRevenue > 0 ? (bankRevenue / totalRevenue * 100).toStringAsFixed(1) : 0}%', style: pw.TextStyle(font: font), textAlign: pw.TextAlign.right)),
                      ]
                    ),
                  ]
                ),
                pw.SizedBox(height: 24),

                pw.Text('III. TOP 10 MÓN ĂN BÁN CHẠY TRONG THÁNG', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                pw.SizedBox(height: 12),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('STT', style: pw.TextStyle(font: fontBold), textAlign: pw.TextAlign.center)),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Tên món ăn', style: pw.TextStyle(font: fontBold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Số lượng', style: pw.TextStyle(font: fontBold), textAlign: pw.TextAlign.right)),
                      ]
                    ),
                    for (int i = 0; i < topDishes.length; i++)
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${i + 1}', style: pw.TextStyle(font: font), textAlign: pw.TextAlign.center)),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(topDishes[i].key, style: pw.TextStyle(font: font))),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${topDishes[i].value} phần', style: pw.TextStyle(font: fontBold), textAlign: pw.TextAlign.right)),
                        ]
                      ),
                  ]
                ),
                pw.Spacer(),

                pw.Align(
                  alignment: pw.Alignment.bottomRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Người lập báo cáo (Ký tên)', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                      pw.SizedBox(height: 48),
                      pw.Text('Quản lý hệ thống', style: pw.TextStyle(font: font, fontSize: 12)),
                    ]
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'BaoCaoDoanhThu_Thang_${month}_$year',
    );
  }

  Future<void> _showSelectMonthReportDialog(List<QueryDocumentSnapshot> invoices) async {
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Xuất báo cáo doanh thu tháng', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedMonth,
                    decoration: const InputDecoration(labelText: 'Chọn Tháng'),
                    items: List.generate(12, (index) => index + 1).map((m) {
                      return DropdownMenuItem(value: m, child: Text('Tháng $m'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedMonth = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedYear,
                    decoration: const InputDecoration(labelText: 'Chọn Năm'),
                    items: List.generate(5, (index) => DateTime.now().year - index).map((y) {
                      return DropdownMenuItem(value: y, child: Text('Năm $y'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedYear = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                    _exportMonthlyReport(invoices, selectedMonth, selectedYear);
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Xuất PDF'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════
  //  UI TABS BUILDERS
  // ═══════════════════════════════════════════════
  Widget _buildRevenueTab(List<QueryDocumentSnapshot> invoices) {
    final totalRevenue = _calculateTotalRevenue(invoices);
    final double averageOrderValue = invoices.isNotEmpty ? totalRevenue / invoices.length : 0.0;

    // Calculate weekly arrays
    final List<double> thisMonthWeeks = [0, 0, 0, 0];
    final List<double> lastMonthWeeks = [0, 0, 0, 0];
    _calculateWeeklyRevenue(invoices, thisMonthWeeks, lastMonthWeeks);

    final double maxWeekly = [...thisMonthWeeks, ...lastMonthWeeks].reduce((a, b) => a > b ? a : b);

    // Calculate 7-day daily arrays
    final List<double> thisMonthDays = List.filled(7, 0.0);
    final List<double> lastMonthDays = List.filled(7, 0.0);
    _calculateDailyRevenue7Days(invoices, thisMonthDays, lastMonthDays);

    final double maxDaily = [...thisMonthDays, ...lastMonthDays].reduce((a, b) => a > b ? a : b);

    // --- Parse top popular dishes ---
    final Map<String, int> dishQuantities = {};
    for (var doc in invoices) {
      final data = doc.data() as Map<String, dynamic>;
      final ordersList = data['orders'] as List<dynamic>? ?? [];
      for (var orderMap in ordersList) {
        final itemsList = orderMap['items'] as List<dynamic>? ?? [];
        for (var itemMap in itemsList) {
          final String name = itemMap['name'] ?? '';
          final int quantity = (itemMap['quantity'] as num?)?.toInt() ?? 0;
          if (name.isNotEmpty && quantity > 0) {
            dishQuantities[name] = (dishQuantities[name] ?? 0) + quantity;
          }
        }
      }
    }

    final sortedDishes = dishQuantities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topDishes = sortedDishes.take(15).toList();

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Hệ Thống Quản Trị & Báo Cáo Doanh Thu', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showSelectMonthReportDialog(invoices),
                icon: const Icon(Icons.print),
                label: const Text('Xuất báo cáo tháng', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // KPI Cards
          Row(
            children: [
              _buildKpiCard('Tổng doanh thu', _formatPrice(totalRevenue.toInt()), Icons.monetization_on, Colors.green),
              const SizedBox(width: 16),
              _buildKpiCard('Tổng số đơn', '${invoices.length} đơn', Icons.receipt_long, Colors.blue),
              const SizedBox(width: 16),
              _buildKpiCard('Trung bình đơn', _formatPrice(averageOrderValue.toInt()), Icons.calculate, Colors.orange),
            ],
          ),
          const SizedBox(height: 24),

          // Charts and Top dishes
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left: Charts
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Weekly Revenue of Current Month
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Doanh thu theo tuần (Tháng này)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              const SizedBox(height: 12),
                              Expanded(
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: maxWeekly > 0 ? maxWeekly * 1.2 : 1000000,
                                    barTouchData: BarTouchData(
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipColor: (_) => AppColors.primary,
                                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                          return BarTooltipItem(
                                            _formatPrice(rod.toY.toInt()),
                                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          );
                                        },
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 28,
                                          getTitlesWidget: (double value, TitleMeta meta) {
                                            final int index = value.toInt();
                                            return SideTitleWidget(
                                              meta: meta,
                                              child: Text('Tuần ${index + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    barGroups: List.generate(4, (i) {
                                      return BarChartGroupData(
                                        x: i,
                                        barRods: [
                                          BarChartRodData(
                                            toY: thisMonthWeeks[i],
                                            color: AppColors.primary,
                                            width: 24,
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(6),
                                              topRight: Radius.circular(6),
                                            ),
                                          )
                                        ],
                                      );
                                    }),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Comparison Chart (This month vs Last Month)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('So sánh với tháng trước', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  Row(
                                    children: [
                                      Container(width: 10, height: 10, color: Colors.grey.shade400),
                                      const SizedBox(width: 4),
                                      const Text('Tháng trước', style: TextStyle(fontSize: 11)),
                                      const SizedBox(width: 12),
                                      Container(width: 10, height: 10, color: AppColors.secondary),
                                      const SizedBox(width: 4),
                                      const Text('Tháng này', style: TextStyle(fontSize: 11)),
                                    ],
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: LineChart(
                                  LineChartData(
                                    lineTouchData: LineTouchData(
                                      touchTooltipData: LineTouchTooltipData(
                                        getTooltipColor: (_) => AppColors.primary,
                                        getTooltipItems: (touchedSpots) {
                                          return touchedSpots.map((spot) {
                                            final isThisMonth = spot.barIndex == 1;
                                            final legend = isThisMonth ? 'Tháng này' : 'Tháng trước';
                                            return LineTooltipItem(
                                              '$legend (Ngày ${spot.x.toInt() + 1})\n${_formatPrice(spot.y.toInt())}',
                                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                            );
                                          }).toList();
                                        },
                                      ),
                                    ),
                                    gridData: const FlGridData(show: true),
                                    titlesData: FlTitlesData(
                                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 28,
                                          getTitlesWidget: (double value, TitleMeta meta) {
                                            final int day = value.toInt() + 1;
                                            if (day >= 1 && day <= 7) {
                                              return SideTitleWidget(
                                                meta: meta,
                                                child: Text('N. $day', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                              );
                                            }
                                            return const SizedBox();
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border.all(color: Colors.grey.shade300, width: 1),
                                    ),
                                    minX: 0,
                                    maxX: 6,
                                    minY: 0,
                                    maxY: maxDaily > 0 ? maxDaily * 1.2 : 1000000,
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: List.generate(7, (i) => FlSpot(i.toDouble(), lastMonthDays[i])),
                                        isCurved: true,
                                        color: Colors.grey.shade400,
                                        barWidth: 4,
                                        isStrokeCapRound: true,
                                        dotData: const FlDotData(show: true),
                                        belowBarData: BarAreaData(show: false),
                                      ),
                                      LineChartBarData(
                                        spots: List.generate(7, (i) => FlSpot(i.toDouble(), thisMonthDays[i])),
                                        isCurved: true,
                                        color: AppColors.secondary,
                                        barWidth: 4,
                                        isStrokeCapRound: true,
                                        dotData: const FlDotData(show: true),
                                        belowBarData: BarAreaData(show: false),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right: Popular dishes
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Top 15 món ăn yêu thích nhất', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        const SizedBox(height: 24),
                        Expanded(
                          child: topDishes.isEmpty
                              ? const Center(child: Text('Chưa có dữ liệu gọi món'))
                              : _buildTopDishesList(topDishes),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTablesTab(List<TableModel> tables) {
    final displayTables = _selectedArea == 'All' 
        ? tables 
        : tables.where((t) => t.area == _selectedArea).toList();

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quản Trị Bàn Ăn & Khu Vực', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _showAddTableDialog,
                icon: const Icon(Icons.add),
                label: const Text('Thêm bàn mới', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: ['All', 'A', 'B', 'C'].map((area) {
              final isSel = _selectedArea == area;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ChoiceChip(
                  label: Text(area == 'All' ? 'Tất cả khu vực' : 'Khu vực $area', 
                      style: TextStyle(color: isSel ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                  selected: isSel,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedArea = area;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: displayTables.isEmpty
                ? const Center(child: Text('Không có bàn ăn nào trong khu vực này.'))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: displayTables.length,
                    itemBuilder: (context, index) {
                      final table = displayTables[index];
                      Color color;
                      String statusText;

                      if (table.status == 'occupied') {
                        color = Colors.red.shade400;
                        statusText = 'Có khách';
                      } else if (table.status == 'booked') {
                        color = Colors.orange.shade400;
                        statusText = 'Đã đặt';
                      } else if (table.status == 'locked') {
                        color = Colors.amber.shade700;
                        statusText = 'Khóa/Sửa chữa';
                      } else {
                        color = Colors.green.shade400;
                        statusText = 'Trống';
                      }

                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () => _showChangeTableStatusDialog(table),
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
                                ],
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(table.id, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(statusText, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (table.status == 'empty')
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  icon: const Icon(Icons.close, color: Colors.white, size: 16),
                                  onPressed: () => _deleteTable(table),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  MAIN BUILD METHOD
  // ═══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tables').snapshots(),
      builder: (context, tablesSnapshot) {
        final List<TableModel> allTables = [];
        if (tablesSnapshot.hasData) {
          for (var doc in tablesSnapshot.data!.docs) {
            allTables.add(TableModel.fromMap(doc.id, doc.data() as Map<String, dynamic>));
          }
          allTables.sort((a, b) => a.id.compareTo(b.id));
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Hệ Thống Quản Trị & Báo Cáo Doanh Thu', style: TextStyle(fontFamily: 'Playfair Display', fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/'); 
                },
              ),
            ],
          ),
          body: Row(
            children: [
              // Left Sidebar Navigation
              Container(
                width: 250,
                color: Colors.white,
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    const Icon(Icons.admin_panel_settings, size: 80, color: AppColors.primary),
                    const SizedBox(height: 16),
                    const Text('Quản lý chung', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 32),
                    
                    ListTile(
                      leading: const Icon(Icons.dashboard),
                      title: const Text('Doanh thu'),
                      selected: _selectedIndex == 0,
                      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                      selectedColor: AppColors.primary,
                      onTap: () => setState(() => _selectedIndex = 0),
                    ),
                    ListTile(
                      leading: const Icon(Icons.table_restaurant),
                      title: const Text('Quản lý Bàn ăn'),
                      selected: _selectedIndex == 1,
                      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                      selectedColor: AppColors.primary,
                      onTap: () => setState(() => _selectedIndex = 1),
                    ),
                    ListTile(
                      leading: const Icon(Icons.restaurant_menu),
                      title: const Text('Quản lý Món ăn'),
                      selected: _selectedIndex == 2,
                      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                      selectedColor: AppColors.primary,
                      onTap: () => setState(() => _selectedIndex = 2),
                    ),
                  ],
                ),
              ),
              
              // Right Content Area
              Expanded(
                child: _selectedIndex == 2
                    ? const MenuManagementScreen()
                    : _selectedIndex == 1
                        ? _buildTablesTab(allTables)
                        : StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('invoices').orderBy('createdAt', descending: true).snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                              }

                              final invoices = snapshot.data?.docs ?? [];
                              return _buildRevenueTab(invoices);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTopDishesList(List<MapEntry<String, int>> topDishes) {
    final double maxQty = topDishes.isNotEmpty ? topDishes.first.value.toDouble() : 1.0;

    return ListView.builder(
      itemCount: topDishes.length,
      itemBuilder: (context, index) {
        final entry = topDishes[index];
        final name = entry.key;
        final qty = entry.value;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${index + 1}. $name',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$qty phần',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  widthFactor: qty / maxQty,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
