import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/menu_data.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  Future<void> _showEditDialog({MenuItem? item}) async {
    final isEditing = item != null;
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final priceCtrl = TextEditingController(text: item?.price.toString() ?? '');
    final descCtrl = TextEditingController(text: item?.description ?? '');
    final tfpCtrl = TextEditingController(text: item?.tfp.toString() ?? '10');
    final categoryCtrl = TextEditingController(text: item?.category ?? 'Khác');
    final imgUrlCtrl = TextEditingController(text: item?.imageUrl ?? '');

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Sửa món ăn' : 'Thêm món ăn mới'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên món')),
                  const SizedBox(height: 8),
                  TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Danh mục (Thực đơn chính, Đồ uống,...)')),
                  const SizedBox(height: 8),
                  TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Giá (VND)'), keyboardType: TextInputType.number),
                  const SizedBox(height: 8),
                  TextField(controller: tfpCtrl, decoration: const InputDecoration(labelText: 'Thời gian làm (phút)'), keyboardType: TextInputType.number),
                  const SizedBox(height: 8),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả')),
                  const SizedBox(height: 8),
                  TextField(controller: imgUrlCtrl, decoration: const InputDecoration(labelText: 'Link Ảnh (URL)')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
            ElevatedButton(
              onPressed: () async {
                final newItem = {
                  'name': nameCtrl.text.trim(),
                  'category': categoryCtrl.text.trim(),
                  'price': int.tryParse(priceCtrl.text) ?? 0,
                  'tfp': int.tryParse(tfpCtrl.text) ?? 10,
                  'description': descCtrl.text.trim(),
                  'imageUrl': imgUrlCtrl.text.trim(),
                  'isAvailable': item?.isAvailable ?? true,
                  'ingredients': item?.ingredients ?? [],
                };

                if (isEditing) {
                  await FirebaseFirestore.instance.collection('menu').doc(item.id).update(newItem);
                } else {
                  // Add new doc with random ID
                  await FirebaseFirestore.instance.collection('menu').add(newItem);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: const Text('Bạn có chắc muốn xoá món này khỏi thực đơn?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Xoá')
          ),
        ],
      )
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('menu').doc(id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Thực đơn'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        onPressed: () => _showEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('menu').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data?.docs.map((doc) => MenuItem.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList() ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(item.imageUrl.isNotEmpty ? item.imageUrl : 'https://via.placeholder.com/150'),
                  ),
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${item.category}  |  ${item.price}đ  |  TFP: ${item.tfp}p'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: item.isAvailable,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          FirebaseFirestore.instance.collection('menu').doc(item.id).update({'isAvailable': val});
                        },
                      ),
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditDialog(item: item)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteItem(item.id)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
