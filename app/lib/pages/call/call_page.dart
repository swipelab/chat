import 'package:app/app.dart';
import 'package:app/blocs/router.dart';
import 'package:app/pages/call/call_signaling.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:stated/stated.dart';

class CallPage with Emitter, AppPage, AppPageView {
  CallPage({required this.callId}) {
    init();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    signaling.dispose();
    super.dispose();
  }

  Future<void> init() async {
    await signaling.createLocalStream();

    await signaling.connect();
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    _localRenderer.srcObject = signaling.localStream;
    notifyListeners();
  }

  final int callId;
  final ListEmitter<String> stream = ListEmitter(['call started']);
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  late final CallSignaling signaling = CallSignaling(
    callId: callId,
    selfId: app.session.session!.userId,
    onAddRemoteStream: handleAddRemoteStream,
  );

  void handleAddRemoteStream(MediaStream stream) {
    _remoteRenderer.srcObject = stream;
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video Call'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.black45,
              ),
              margin: EdgeInsets.all(16),
              child: RTCVideoView(_localRenderer, mirror: true),
            ),
          ),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.black45,
              ),
              margin: EdgeInsets.all(16),
              child: RTCVideoView(_remoteRenderer, mirror: false),
            ),
          ),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.black45,
              ),
              margin: EdgeInsets.all(16),
              child: ListenableBuilder(
                listenable: stream,
                builder: (context, _) {
                  return ListView.builder(
                    itemBuilder:
                        (context, index) =>
                            ListTile(title: Text(stream[index])),
                    itemCount: stream.length,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
