import 'package:test/test.dart';
import 'package:yaroorm/yaroorm.dart';
import 'package:yaroorm_tests/src/models.dart';
import 'package:yaroorm_tests/test_data.dart';

import 'package:yaroorm/src/reflection.dart';

import '../util.dart';

void runRelationsE2ETest(String connectionName) {
  final driver = DB.driver(connectionName);

  return group('with ${driver.type.name} driver', () {
    late User testUser1, anotherUser;

    final tableNames = [
      getEntityTableName<User>(),
      getEntityTableName<Post>(),
      getEntityTableName<PostComment>(),
    ];

    setUpAll(() async {
      await driver.connect();

      expect(driver.isOpen, isTrue);

      var hasTables = await Future.wait(tableNames.map(driver.hasTable));
      expect(hasTables.every((e) => e), isFalse);

      await runMigrator(connectionName, 'migrate');

      hasTables = await Future.wait(tableNames.map(driver.hasTable));
      expect(hasTables.every((e) => e), isTrue);

      testUser1 = await UserQuery.driver(driver).insert(NewUser(
        firstname: 'Baba',
        lastname: 'Tunde',
        age: 29,
        homeAddress: 'Owerri, Nigeria',
      ));
    });

    test('should add many posts for User', () async {
      await testUser1.posts.insertMany([
        NewPostForUser(title: 'Aoo bar 1', description: 'foo bar 4'),
        NewPostForUser(title: 'Bee Moo 2', description: 'foo bar 5'),
        NewPostForUser(title: 'Coo Kie 3', description: 'foo bar 6'),
      ]);

      final posts = await testUser1.posts.get(
        orderBy: [OrderPostBy.title(order: OrderDirection.desc)],
      );
      expect(posts, hasLength(3));
      expect(
          posts.map((e) => {
                'id': e.id,
                'title': e.title,
                'desc': e.description,
                'userId': e.userId
              }),
          [
            {'id': 3, 'title': 'Coo Kie 3', 'desc': 'foo bar 6', 'userId': 1},
            {'id': 2, 'title': 'Bee Moo 2', 'desc': 'foo bar 5', 'userId': 1},
            {'id': 1, 'title': 'Aoo bar 1', 'desc': 'foo bar 4', 'userId': 1}
          ]);
    });

    test('should fetch posts with owner', () async {
      final posts = await PostQuery.driver(driver)
          .withRelations((post) => [post.owner])
          .findMany();

      final owner = await posts.first.owner.value;
      expect(
        owner,
        isA<User>().having((p0) => p0.firstname, 'has firstname', isNotNull),
      );
    });

    test('should add comments for post', () async {
      final post = await testUser1.posts.first!;
      expect(post, isA<Post>());

      var comments = await post!.comments.get();
      expect(comments, isEmpty);

      await post.comments.insertMany([
        NewPostCommentForPost(comment: 'This post looks abit old'),
        NewPostCommentForPost(comment: 'oh, another comment'),
      ]);

      comments = await post.comments.get();

      expect(comments.every((e) => e.postId == post.id), isTrue);
      expect(
          comments.map((c) => {
                'id': c.id,
                'comment': c.comment,
                'postId': c.postId,
              }),
          [
            {'id': 1, 'comment': 'This post looks abit old', 'postId': 1},
            {'id': 2, 'comment': 'oh, another comment', 'postId': 1}
          ]);
    });

    test('should add post for another user', () async {
      final testuser = usersList.last;
      anotherUser = await UserQuery.driver(driver).insert(NewUser(
        firstname: testuser.firstname,
        lastname: testuser.lastname,
        age: testuser.age,
        homeAddress: testuser.homeAddress,
      ));

      expect(anotherUser.id, isNotNull);
      expect(anotherUser.id != testUser1.id, isTrue);

      var anotherUserPosts = await anotherUser.posts.get();
      expect(anotherUserPosts, isEmpty);

      await anotherUser.posts.insert(
        NewPostForUser(title: 'Another Post', description: 'wham bamn'),
      );
      anotherUserPosts = await anotherUser.posts.get();
      expect(anotherUserPosts, hasLength(1));

      final anotherUserPost = anotherUserPosts.first;
      expect(anotherUserPost.userId, anotherUser.id);

      await anotherUserPost.comments.insertMany([
        NewPostCommentForPost(comment: 'ah ah'),
        NewPostCommentForPost(comment: 'oh oh'),
      ]);

      expect(await anotherUserPost.comments.get(), hasLength(2));
    });

    test('should delete comments for post', () async {
      expect(testUser1, isNotNull);
      final posts = await testUser1.posts.get();
      expect(posts, hasLength(3));

      // ignore: curly_braces_in_flow_control_structures
      for (final post in posts) await post.comments.delete();

      for (final post in posts) {
        expect(await post.comments.get(), []);
      }

      await testUser1.posts.delete();

      expect(await testUser1.posts.get(), isEmpty);
    });

    tearDownAll(() async {
      await runMigrator(connectionName, 'migrate:reset');

      final hasTables = await Future.wait(tableNames.map(driver.hasTable));
      expect(hasTables.every((e) => e), isFalse);

      await driver.disconnect();
      expect(driver.isOpen, isFalse);
    });
  });
}
