import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class RiveAsset {
  final String artboard;
  final String stateMachineName;
  final String title;
  final String src;
  late SMIBool? status;

  RiveAsset(
    this.artboard,
    this.stateMachineName,
    this.title,
    this.src, {
    this.status,
  });

  set setStatus(SMIBool state) {
    status = state;
  }
}
