import 'package:test/test.dart';
import 'package:yaroorm/yaroorm.dart';
import 'package:yaroorm_tests/src/models.dart';
import 'package:yaroorm_tests/test_data.dart';

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

    // test('should add many posts for User', () async {
    //   await testUser1.posts.add(title: 'Aoo bar 1', description: 'foo bar 4');
    //   await testUser1.posts.add(title: 'Bee Moo 2', description: 'foo bar 5');
    //   await testUser1.posts.add(title: 'Coo Kie 3', description: 'foo bar 6');

    //   final posts = await testUser1.posts.get(
    //     orderBy: [OrderPostBy.title(OrderDirection.desc)],
    //   );
    //   expect(posts, hasLength(3));
    //   expect(
    //       posts.map((e) => {
    //             'id': e.id,
    //             'title': e.title,
    //             'desc': e.description,
    //             'userId': e.userId
    //           }),
    //       [
    //         {'id': 3, 'title': 'Coo Kie 3', 'desc': 'foo bar 6', 'userId': 1},
    //         {'id': 2, 'title': 'Bee Moo 2', 'desc': 'foo bar 5', 'userId': 1},
    //         {'id': 1, 'title': 'Aoo bar 1', 'desc': 'foo bar 4', 'userId': 1}
    //       ]);
    // });

    // test('should fetch posts with owners', () async {
    //   final posts = await PostQuery.driver(driver)
    //       .withRelations((post) => [post.owner])
    //       .findMany();
    //   final post = posts.first;

    //   final owner = await post.owner;
    //   final result = await owner.get();
    //   expect(owner.isUsingEntityCache, isTrue);
    //   expect(result, isA<User>());
    // });

    // test('should add comments for post', () async {
    //   final post = await testUser1.posts.first!;
    //   expect(post, isA<Post>());

    //   var comments = await post!.comments.get();
    //   expect(comments, isEmpty);

    //   await post.comments.add(comment: 'This post looks abit old');

    //   comments = await post.comments.get();
    //   expect(
    //       comments.map(
    //           (c) => {'id': c.id, 'comment': c.comment, 'postId': c.postId}),
    //       [
    //         {'id': 1, 'comment': 'This post looks abit old', 'postId': post.id}
    //       ]);

    //   await post.comments.add(comment: 'oh, another comment');
    // });

    // test('should add post for another user', () async {
    //   final testuser = usersList.last;
    //   anotherUser = await UserQuery.driver(driver).create(
    //     firstname: testuser.firstname,
    //     lastname: testuser.lastname,
    //     age: testuser.age,
    //     homeAddress: testuser.homeAddress,
    //   );

    //   expect(anotherUser.id, isNotNull);
    //   expect(anotherUser.id != testUser1.id, isTrue);

    //   var anotherUserPosts = await anotherUser.posts.get();
    //   expect(anotherUserPosts, isEmpty);

    //   await anotherUser.posts
    //       .add(title: 'Another Post', description: 'wham bamn');
    //   anotherUserPosts = await anotherUser.posts.get();
    //   expect(anotherUserPosts, hasLength(1));

    //   final anotherUserPost = anotherUserPosts.first;
    //   expect(anotherUserPost.userId, anotherUser.id);

    //   await anotherUserPost.comments.add(comment: 'ah ah');
    //   await anotherUserPost.comments.add(comment: 'oh oh');

    //   expect(await anotherUserPost.comments.get(), hasLength(2));
    // });

    // test('should delete comments for post', () async {
    //   expect(testUser1, isNotNull);
    //   final posts = await testUser1.posts.get();
    //   expect(posts, hasLength(3));

    //   // ignore: curly_braces_in_flow_control_structures
    //   for (final post in posts) await post.comments.delete();

    //   for (final post in posts) {
    //     expect(await post.comments.get(), []);
    //   }

    //   await testUser1.posts.delete();

    //   expect(await testUser1.posts.get(), isEmpty);
    // });

    tearDownAll(() async {
      await runMigrator(connectionName, 'migrate:reset');

      final hasTables = await Future.wait(tableNames.map(driver.hasTable));
      expect(hasTables.every((e) => e), isFalse);

      await driver.disconnect();
      expect(driver.isOpen, isFalse);
    });
  });
}
