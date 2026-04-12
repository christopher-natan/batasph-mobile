import 'package:batasph_mobile/pages/home/models/starter_question_model.dart';
import 'package:batasph_mobile/data/remote/api_client.dart';

class HomeStarterQuestionsService {
  final _client = ApiClient().client;

  Future<List<StarterQuestionModel>> getRandomQuestions({int limit = 5}) async {
    final response = await _client.get(
      '/starter-questions/random',
      queryParameters: {'limit': limit},
    );

    final data = response.data as List;
    return data
        .map(
          (item) => StarterQuestionModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
