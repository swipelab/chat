import 'package:app/core/router.dart';
import 'package:flutter/material.dart';

class UnknownPage with AppPage, AppPageView {
  UnknownPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Placeholder());
  }
}
