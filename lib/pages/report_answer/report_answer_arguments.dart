import 'package:batasph_mobile/data/models/chat_message_model.dart';

class ReportAnswerArguments {
  final ChatMessageModel questionMessage;
  final ChatMessageModel answerMessage;

  const ReportAnswerArguments({
    required this.questionMessage,
    required this.answerMessage,
  });
}
