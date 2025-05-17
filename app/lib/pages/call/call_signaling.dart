import 'dart:convert';

import 'package:app/app.dart';
import 'package:app/core/core.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallSignaling {
  CallSignaling({
    required this.callId,
    required this.selfId,
    this.onAddRemoteStream,
  });

  final int callId;
  final int selfId;

  MediaStream? _localStream;

  MediaStream? get localStream => _localStream;

  RTCPeerConnection? pc;

  Socket? _socket;

  void Function(MediaStream)? onAddRemoteStream;

  Future<void> join() async {
    final peerConnectionConfig = {
      ..._p2pIceServers,
      ...{'sdpSemantics': 'unified-plan'},
    };

    RTCPeerConnection peerConnection =
        pc = await createPeerConnection(peerConnectionConfig, _p2pConstraints);

    peerConnection.onTrack = (event) {
      if (event.track.kind == 'video') {
        onAddRemoteStream?.call(event.streams[0]);
      }
    };
    if (_localStream == null) {
      logger.i('localStream is broken');
    }
    if (pc == null) {
      logger.i('peer connection is broken');
    }
    _localStream!.getTracks().forEach((track) async {
      await peerConnection.addTrack(track, _localStream!);
    });

    peerConnection.onIceCandidate = (candidate) async {
      const delay = Duration(seconds: 2);
      await Future.delayed(
        delay,
        () => _send({
          'event': 'candidate',
          'data': {
            'sdpMLineIndex': candidate.sdpMLineIndex,
            'sdpMid': candidate.sdpMid,
            'candidate': candidate.candidate,
          },
        }),
      );
    };

    peerConnection.onIceConnectionState = (state) {};
    peerConnection.onRemoveStream = (stream) {};
  }

  Future<void> connect() async {
    final socket = Socket(
      url: '/api/call/$callId',
      onOpen: () {},
      onMessage: (e) async {
        final json = jsonDecode(e);
        final event = json['event'] as String?;
        final data = json['data'] as Map<String, dynamic>;
        switch (event) {
          case 'peer':
            {
              await join();
              await _createOffer();
            }
          case 'offer':
            {
              await join();
              pc?.setRemoteDescription(
                RTCSessionDescription(data['sdp'], data['type']),
              );
              await _createAnswer();
            }
          case 'answer':
            {
              pc?.setRemoteDescription(
                RTCSessionDescription(data['sdp'], data['type']),
              );
            }
          case 'candidate':
            {
              pc?.addCandidate(
                RTCIceCandidate(
                  data['candidate'],
                  data['sdpMid'],
                  data['sdpMLineIndex'],
                ),
              );
            }
        }
      },
      onClose: (code, reason) {
        logger.i('Closed by server [$code => $reason]!');
      },
    );
    _socket = socket;
    await socket.connect();
  }

  Future<void> createLocalStream() async {
    _localStream = await _createLocalStream();
  }

  Future<MediaStream> _createLocalStream([bool userScreen = false]) async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': userScreen ? false : true,
      'video':
          userScreen
              ? true
              : {
                'mandatory': {
                  'minWidth': '640',
                  'minHeight': '480',
                  'minFrameRate': '30',
                },
                'facingMode': 'user',
                'optional': [],
              },
    };

    return await navigator.mediaDevices.getUserMedia(mediaConstraints);
  }

  Future<void> _createOffer() async {
    try {
      final offer = await pc?.createOffer();
      if (offer == null) return;

      await pc?.setLocalDescription(_fixSdp(offer));
      _send({
        'event': 'offer',
        'data': {'sdp': offer.sdp, 'type': offer.type},
      });
    } catch (e, s) {
      logger.e(e, stackTrace: s);
    }
  }

  Future<void> _createAnswer() async {
    try {
      final answer = await pc?.createAnswer({});
      if (answer == null) return;

      await pc?.setLocalDescription(_fixSdp(answer));
      _send({
        'event': 'answer',
        'data': {'sdp': answer.sdp, 'type': answer.type},
      });
    } catch (e, s) {
      logger.e(e, stackTrace: s);
    }
  }

  RTCSessionDescription _fixSdp(RTCSessionDescription s) {
    s.sdp = s.sdp?.replaceAll(
      'profile-level-id=640c1f',
      'profile-level-id=42e032',
    );
    return s;
  }

  final Map<String, dynamic> _p2pConstraints = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  final Map<String, dynamic> _p2pIceServers = {
    'iceServers': [
      {'url': 'stun:stun.l.google.com:19302'},
    ],
  };

  void _send(Map<String, Object> json) => _socket?.send(jsonEncode(json));

  void dispose() {
    _socket?.close();
    _localStream?.dispose();
    pc?.dispose();
  }
}
