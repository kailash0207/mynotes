import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mynotes/helpers/loading/loading_screen_controller.dart';

class LoadingScreen {
  factory LoadingScreen() => _instance;
  static final LoadingScreen _instance = LoadingScreen._getInstance();
  LoadingScreen._getInstance();

  LoadingScreenController? controller;

  LoadingScreenController showOVerlay(
      {required BuildContext context, required String text}) {
    final streamController = StreamController<String>();
    streamController.add(text);

    final state = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    final overlay = OverlayEntry(
      builder: (context) {
        return Material(
            color: Colors.black.withAlpha(150),
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: size.width * 0.8,
                    maxHeight: size.height * 0.8,
                    minWidth: size.width * 0.5),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        StreamBuilder(
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Text(
                                  snapshot.data as String,
                                  textAlign: TextAlign.center,
                                );
                              } else {
                                return Container();
                              }
                            },
                            stream: streamController.stream)
                      ],
                    ),
                  ),
                ),
              ),
            ));
      },
    );

    state?.insert(overlay);

    return LoadingScreenController(
      closeLoadingScreen: () {
        streamController.close();
        overlay.remove();
        return true;
      },
      updateLoadingScreen: (text) {
        streamController.add(text);
        return true;
      },
    );
  }

  void hide() {
    controller?.closeLoadingScreen();
    controller = null;
  }

  void show({required BuildContext context, required String text}) {
    if (controller?.updateLoadingScreen(text) ?? false) {
      return;
    } else {
      controller = showOVerlay(context: context, text: text);
    }
  }
}
