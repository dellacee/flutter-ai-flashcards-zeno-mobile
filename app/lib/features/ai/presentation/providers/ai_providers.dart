import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/features/ai/data/ai_api_client.dart';

final aiApiClientProvider = Provider<AiApiClient>((ref) => AiApiClient());
