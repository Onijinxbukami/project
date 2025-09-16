import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomDropdown extends StatefulWidget {
  final ValueNotifier<int> selectedValue;
  final List<int> items;
  final VoidCallback updateDOB;

  const CustomDropdown({
    Key? key,
    required this.selectedValue,
    required this.items,
    required this.updateDOB,
  }) : super(key: key);

  @override
  _CustomDropdownState createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  late int tempSelectedValue; // Giá trị tạm thời

  @override
  void initState() {
    super.initState();
    tempSelectedValue = widget.selectedValue.value;
  }

  void showPicker(BuildContext context) {
    FocusScope.of(context).unfocus();
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            // Thanh điều khiển
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context), // Đóng picker
                    child: Text("Cancel", style: TextStyle(color: Colors.red)),
                  ),
                  TextButton(
                    onPressed: () {
                      widget.selectedValue.value = tempSelectedValue; // ✅ Cập nhật giá trị
                      widget.updateDOB(); // ✅ Cập nhật DOB
                      Navigator.pop(context);
                    },
                    child: Text("OK", style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
            ),
            // Picker chính
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: widget.items.indexOf(widget.selectedValue.value),
                ),
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  tempSelectedValue = widget.items[index]; // Lưu giá trị tạm thời
                },
                children: widget.items
                    .map((item) => Center(
                        child: Text(item.toString(),
                            style: TextStyle(fontSize: 18))))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.selectedValue,
      builder: (context, value, child) {
        return GestureDetector(
          onTap: () => showPicker(context),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value.toString(), style: TextStyle(fontSize: 16)),
                Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}
