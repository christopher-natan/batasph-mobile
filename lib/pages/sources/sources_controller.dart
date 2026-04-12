import 'package:get/get.dart';
import 'package:batasph_mobile/data/models/law_source_model.dart';
import 'package:batasph_mobile/services/sources_service.dart';

class SourcesController extends GetxController {
  final _sourcesService = Get.find<SourcesService>();

  List<LawSourceModel> get sources => _sourcesService.sources;
}
