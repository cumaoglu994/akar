import 'package:flutter/material.dart';

showSnakBar(context, String title) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.blueAccent,
      content: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      )));
}
