import 'package:flutter/material.dart';

import 'layouts_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: _GridButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LayoutsPage()),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GridButton extends StatelessWidget {
  const _GridButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: const SizedBox(
          width: 168,
          height: 168,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GridMark(),
              SizedBox(height: 22),
              Text(
                'Grid',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridMark extends StatelessWidget {
  const _GridMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 40,
      child: Column(
        children: [
          _GridBar(),
          SizedBox(height: 5),
          _GridBar(),
          SizedBox(height: 5),
          _GridBar(),
        ],
      ),
    );
  }
}

class _GridBar extends StatelessWidget {
  const _GridBar();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.white,
      child: SizedBox(height: 8, width: 40),
    );
  }
}
