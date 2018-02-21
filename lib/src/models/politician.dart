library blood_money.src.models.politician;

import 'package:angel_model/angel_model.dart';
import 'package:angel_serialize/angel_serialize.dart';

part 'politician.g.dart';

@serializable
class _Politician extends Model {
  String name, imageUrl, position, state, bio, tweetId, phone, email, twitter;
  num moneyFromNra;
}
