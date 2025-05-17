import 'dart:convert';
import 'dart:io';

import 'package:app/blocs/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:stated/stated.dart';

class CallSignaling {
  Future<Map> getTurnCredential(String host, int port) async {
    HttpClient client = HttpClient(context: SecurityContext());
    client.badCertificateCallback = (
      X509Certificate cert,
      String host,
      int port,
    ) {
      debugPrint(
        'getTurnCredential: Allow self-signed certificate => $host:$port. ',
      );
      return true;
    };
    var url =
        'https://$host:$port/api/turn?service=turn&username=flutter-webrtc';
    var request = await client.getUrl(Uri.parse(url));
    var response = await request.close();
    var responseBody = await response.transform(Utf8Decoder()).join();
    debugPrint('getTurnCredential:response => $responseBody.');
    Map data = JsonDecoder().convert(responseBody);
    return data;
  }

  final Map<String, dynamic> _config = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  final Map<String, dynamic> _dcConstraints = {
    'mandatory': {'OfferToReceiveAudio': false, 'OfferToReceiveVideo': false},
    'optional': [],
  };

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'url': 'stun:stun.l.google.com:19302'},
      /*
       * turn server configuration example.
      {
        'url': 'turn:123.45.67.89:3478',
        'username': 'change_to_real_user',
        'credential': 'change_to_real_secret'
      },
      */
    ],
  };
}

class CallPage with Emitter, AppPage, AppPageView {
  CallPage({required this.callId}) {
    init();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    super.dispose();
  }

  Future<void> init() async {
    await _localRenderer.initialize();
    _localRenderer.srcObject = await createStream('video', false);
    signaling.getTurnCredential('host', 'port');
    notifyListeners();
  }

  Future<MediaStream> createStream(
    String media,
    bool userScreen, {
    BuildContext? context,
  }) async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': userScreen ? false : true,
      'video':
          userScreen
              ? true
              : {
                'mandatory': {
                  'minWidth':
                      '640', // Provide your own width, height and frame rate here
                  'minHeight': '480',
                  'minFrameRate': '30',
                },
                'facingMode': 'user',
                'optional': [],
              },
    };
    late MediaStream stream;
    if (userScreen) {
      // if (WebRTC.platformIsDesktop) {
      //   final source = await showDialog<DesktopCapturerSource>(
      //     context: context!,
      //     builder: (context) => ScreenSelectDialog(),
      //   );
      //   stream = await navigator.mediaDevices.getDisplayMedia(<String, dynamic>{
      //     'video': source == null
      //         ? true
      //         : {
      //       'deviceId': {'exact': source.id},
      //       'mandatory': {'frameRate': 30.0}
      //     }
      //   });
      // } else {
      stream = await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
      // }
    } else {
      stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    }

    // onLocalStream?.call(stream);
    return stream;
  }

  final String callId;
  final ListEmitter<String> stream = ListEmitter(['call started']);
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final CallSignaling signaling = CallSignaling();

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
              child: RTCVideoView(_localRenderer, mirror: false),
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
