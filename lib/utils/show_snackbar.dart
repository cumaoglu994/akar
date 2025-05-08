import 'package:flutter/material.dart';



  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              const Text('جاري حذف الإعلان، يرجى الانتظار...'),
            ],
          ),
        );
      },
    );
  }
