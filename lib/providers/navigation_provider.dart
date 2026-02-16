
import 'package:flutter_riverpod/flutter_riverpod.dart';


final navigationIndexProvider = StateProvider<int>((ref) => 0);


final pendingSelectedUserProvider = StateProvider<String?>((ref) => null);
final pendingSelectedItemProvider = StateProvider<String?>((ref) => null);