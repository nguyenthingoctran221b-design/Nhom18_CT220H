import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/order.dart';
import 'package:intl/intl.dart';

class PdfInvoiceHelper {
  static Future<void> generateAndPrintInvoice(
    List<OrderModel> orders,
    String tableInfo, {
    List<OrderItem>? overrideItems,
    double? overrideTotal,
  }) async {
    final pdf = pw.Document();

    // Lấy font hỗ trợ tiếng Việt
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    // Tính tổng tất cả các đơn
    double grandTotal = overrideTotal ?? 0;
    final allItems = overrideItems ?? <OrderItem>[];
    
    if (overrideItems == null) {
      for (var order in orders) {
        if (order.orderItems != null) {
          final doneItems = order.orderItems!.where((item) => item.status == 'done').toList();
          allItems.addAll(doneItems);
          for (var item in doneItems) {
            grandTotal += item.total;
          }
        }
      }
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Định dạng giấy in bill 80mm
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('SEN VÀNG INDOCHINE', style: pw.TextStyle(font: fontBold, fontSize: 16)),
              pw.SizedBox(height: 4),
              pw.Text('HOÁ ĐƠN TẠM TÍNH', style: pw.TextStyle(font: fontBold, fontSize: 14)),
              pw.SizedBox(height: 8),
              pw.Text('Bàn: $tableInfo', style: pw.TextStyle(font: font, fontSize: 12)),
              pw.Text('Ngày: ${dateFormat.format(DateTime.now())}', style: pw.TextStyle(font: font, fontSize: 10)),
              pw.Divider(),
              pw.SizedBox(height: 8),
              
              // List items
              pw.ListView.builder(
                itemCount: allItems.length,
                itemBuilder: (context, index) {
                  final item = allItems[index];
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text('${item.quantity} x ${item.name}', style: pw.TextStyle(font: font, fontSize: 10)),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(_formatPrice(item.total.toInt()), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: font, fontSize: 10)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 4),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TỔNG CỘNG:', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                  pw.Text(_formatPrice(grandTotal.toInt()), style: pw.TextStyle(font: fontBold, fontSize: 12)),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Text('Cảm ơn quý khách!', style: pw.TextStyle(font: font, fontSize: 10)),
              pw.Text('Hẹn gặp lại!', style: pw.TextStyle(font: font, fontSize: 10)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'HoaDon_$tableInfo',
    );
  }

  static String _formatPrice(int price) {
    final formatted = price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$formatted ₫';
  }
}
