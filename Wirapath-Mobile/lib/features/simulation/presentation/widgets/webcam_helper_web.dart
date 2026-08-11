import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class WebcamPreview extends StatefulWidget {
  const WebcamPreview({super.key});

  @override
  State<WebcamPreview> createState() => _WebcamPreviewState();
}

class _WebcamPreviewState extends State<WebcamPreview> {
  html.VideoElement? _videoElement;
  html.MediaStream? _localStream;
  late String _viewType;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _viewType = 'webcam-view-${DateTime.now().microsecondsSinceEpoch}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      _startStream();
      return _videoElement!;
    });
  }

  Future<void> _startStream() async {
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices != null) {
        final stream = await mediaDevices.getUserMedia({
          'video': {
            'facingMode': 'user',
            'width': {'ideal': 640},
            'height': {'ideal': 480}
          },
          'audio': true,
        });
        _localStream = stream;
        if (_videoElement != null) {
          _videoElement!.srcObject = stream;
        }
      } else {
        final stream = await html.window.navigator.getUserMedia(video: true, audio: true);
        _localStream = stream;
        if (_videoElement != null) {
          _videoElement!.srcObject = stream;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    try {
      _localStream?.getTracks().forEach((track) {
        track.stop();
      });
    } catch (_) {}
    if (_videoElement != null) {
      _videoElement!.srcObject = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              Text(
                'Camera/Mic access failed: $_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return HtmlElementView(viewType: _viewType);
  }
}
