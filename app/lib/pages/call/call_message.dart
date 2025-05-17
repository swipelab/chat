class PeersCallEvent {}

class OfferCallEvent {}

class AnswerCallEvent {}

class CandidateCallEvent {}

class LeaveCallEvent {}

class ByeCallEvent {}

class KeepAliveEvent {}

class CallEvent {
  final PeersCallEvent? peers;
  final OfferCallEvent? offer;
  final AnswerCallEvent? answer;
  final CandidateCallEvent? candidate;
  final LeaveCallEvent? leave;
  final ByeCallEvent? bye;
  final KeepAliveEvent? keepAlive;

  CallEvent({
    this.peers,
    this.offer,
    this.answer,
    this.candidate,
    this.leave,
    this.bye,
    this.keepAlive,
  });
}
