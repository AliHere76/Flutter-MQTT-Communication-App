import 'constant.dart';
import 'package:mongo_dart/mongo_dart.dart';

class MongoDatabase {
  static late Db _db;
  static late DbCollection _collection;

  static Future<void> connect() async {
    _db = await Db.create(MONGO_URL);
    await _db.open();
    _collection = _db.collection(COLLECTION_NAME);
    print(await _collection.find().toList());
  }

  Future<bool> isUsernameTaken(String username) async {
    var user = await _collection.findOne(where.eq('username', username));
    return user != null;
  }

  Future<void> registerUser(String username, String password) async {
    await _collection.insertOne({'username': username, 'password': password});
  }

  Future<bool> loginUser(String username, String password) async {
    var user = await _collection.findOne(where
        .eq('username', username)
        .eq('password', password));
    return user != null;
  }
}
