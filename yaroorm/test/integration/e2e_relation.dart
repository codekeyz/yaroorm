import 'package:test/test.dart';
import 'package:yaroorm/yaroorm.dart';

import '../fixtures/migrator.dart';
import '../fixtures/test_data.dart';

void runRelationsE2ETest(String connectionName) {
  final driver = DB.driver(connectionName);

  final tables = [User, Post, PostComment].map((e) => getEntityTableName(e));

  test('tables names', () => expect(tables, ['users', 'posts', 'post_comments']));

  return group('with ${driver.type.name} driver', () {
    User? testUser1, anotherUser;

    setUpAll(() async {
      await driver.connect();

      expect(driver.isOpen, isTrue);

      var hasTables = await Future.wait(tables.map(driver.hasTable));
      expect(hasTables.every((e) => e), isFalse);

      await runMigrator(connectionName, 'migrate');

      hasTables = await Future.wait(tables.map(driver.hasTable));
      expect(hasTables.every((e) => e), isTrue);

      testUser1 = await usersTestData.first.withDriver(driver).save();
      expect(testUser1, isA<User>().having((p0) => p0.id, 'has primary key', 1));
    });

    test('should add many posts for User', () async {
      final postsToAdd = <Post>[
        Post('Foo Bar 1', 'foo bar 4'),
        Post('Mee Moo 2', 'foo bar 5'),
        Post('Coo Kie 3', 'foo bar 6'),
      ];

      await testUser1!.posts.addAll(postsToAdd);

      final posts = await testUser1!.posts.get();
      expect(posts, hasLength(3));
      expect(posts.every((e) => e.createdAt != null && e.updatedAt != null && e.userId == testUser1!.id), isTrue);
      expect(posts.map((e) => {'id': e.id, 'title': e.title, 'desc': e.description, 'userId': e.userId!}), [
        {'id': 1, 'title': 'Foo Bar 1', 'desc': 'foo bar 4', 'userId': 1},
        {'id': 2, 'title': 'Mee Moo 2', 'desc': 'foo bar 5', 'userId': 1},
        {'id': 3, 'title': 'Coo Kie 3', 'desc': 'foo bar 6', 'userId': 1}
      ]);
    });

    test('should add comments for post', () async {
      final post = await testUser1!.posts.first();
      expect(post, isA<Post>());

      var comments = await post!.comments.get();
      expect(comments, isEmpty);

      final c = PostComment('this post looks abit old')..id = 'some_random_uuid_32893782738';
      await post.comments.add(c);

      comments = await post.comments.get();
      expect(comments.map((e) => {'id': c.id, 'comment': c.comment, 'postId': e.postId}), [
        {'id': 'some_random_uuid_32893782738', 'comment': 'this post looks abit old', 'postId': 1}
      ]);

      await post.comments.add(PostComment('oh, another comment')..id = 'jagaban_299488474773_uuid_3i848');
      comments = await post.comments.get();
      expect(comments, hasLength(2));
      expect(comments.map((e) => {'id': e.id, 'comment': e.comment, 'postId': e.postId}), [
        {'id': 'some_random_uuid_32893782738', 'comment': 'this post looks abit old', 'postId': 1},
        {'id': 'jagaban_299488474773_uuid_3i848', 'comment': 'oh, another comment', 'postId': 1}
      ]);
    });

    test('should add post for another user', () async {
      anotherUser = await usersTestData.last.withDriver(driver).save();
      final user = anotherUser as User;

      expect(user.id, isNotNull);
      expect(user.id != testUser1!.id, isTrue);

      var anotherUserPosts = await user.posts.get();
      expect(anotherUserPosts, isEmpty);

      await user.posts.add(Post('Another Post', 'wham bamn bamn'));
      anotherUserPosts = await user.posts.get();
      expect(anotherUserPosts, hasLength(1));

      final anotherUserPost = anotherUserPosts.first;
      expect(anotherUserPost.userId!, anotherUser!.id!);

      await anotherUserPost.comments.addAll([
        PostComment('ah ah')..id = '_id_394',
        PostComment('oh oh')..id = '_id_394885',
      ]);

      expect(await anotherUserPost.comments.get(), hasLength(2));
    });

    test('should delete comments for post', () async {
      expect(testUser1, isNotNull);
      final posts = await testUser1!.posts.get();
      expect(posts, hasLength(3));

      // ignore: curly_braces_in_flow_control_structures
      for (final post in posts) await post.comments.delete();

      expect(await Future.wait(posts.map((e) => e.comments.get())), [[], [], []]);

      await testUser1!.posts.delete();

      expect(await testUser1!.posts.get(), isEmpty);

      final anotherUserPosts = await anotherUser!.posts.get();
      expect(anotherUserPosts, hasLength(1));

      expect(await anotherUserPosts.first.comments.get(), hasLength(2));
    });

    tearDownAll(() async {
      await runMigrator(connectionName, 'migrate:reset');

      final hasTables = await Future.wait(tables.map(driver.hasTable));
      expect(hasTables.every((e) => e), isFalse);

      await driver.disconnect();
      expect(driver.isOpen, isFalse);
    });
  });
}
