import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import './main.dart';
import './post.dart';
import 'my_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Future<void> sendPost(String text) async {
    // まずは user という変数にログイン中のユーザーデータを格納します
    final user = FirebaseAuth.instance.currentUser!;

    final posterId = user.uid; // ログイン中のユーザーのIDがとれます
    final posterName = user.displayName!; // Googleアカウントの名前がとれます
    final posterImageUrl = user.photoURL!; // Googleアカウントのアイコンデータがとれます

    // 先ほど作った postsReference からランダムなIDのドキュメントリファレンスを作成します
    // doc の引数を空にするとランダムなIDが採番されます
    final newDocumentReference = postsReference.doc();

    final newPost = Post(
      text: text,
      createdAt: Timestamp.now(), // 投稿日時は現在とします
      posterName: posterName,
      posterImageUrl: posterImageUrl,
      posterId: posterId,
      reference: newDocumentReference,
    );

    // 先ほど作った newDocumentReference のset関数を実行するとそのドキュメントにデータが保存されます。
    // 引数として Post インスタンスを渡します。
    // 通常は Map しか受け付けませんが、withConverter を使用したことにより Post インスタンスを受け取れるようになります。
    newDocumentReference.set(newPost);
  }

  final controller = TextEditingController();

  /// この dispose 関数はこのWidgetが使われなくなったときに実行されます。
  @override
  void dispose() {
    // TextEditingController は使われなくなったら必ず dispose する必要があります。
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold 全体を GestureDetector で囲むことでタップ可能になります。
    return GestureDetector(
      onTap: () {
        // キーボードを閉じたい時はこれを呼びます。
        primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('チャット'),
          // actions プロパティにWidgetを与えると右端に表示されます。
          actions: [
            // tap 可能にするために InkWell を使います。
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return const MyPage();
                    },
                  ),
                );
              },
              child: CircleAvatar(
                backgroundImage: NetworkImage(
                  FirebaseAuth.instance.currentUser!.photoURL!,
                ),
              ),
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Post>>(
                // stream プロパティに snapshots() を与えると、コレクションの中のドキュメントをリアルタイムで監視することができます。
                stream: postsReference.orderBy('createdAt').snapshots(),
                // ここで受け取っている snapshot に stream で流れてきたデータ入っています。
                builder: (context, snapshot) {
                  // docs には Collection に保存されたすべてのドキュメントが入ります。
                  // 取得までには時間がかかるのではじめは null が入っています。
                  // null の場合は空配列が代入されるようにしています。
                  final docs = snapshot.data?.docs ?? [];
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      // data() に Post インスタンスが入っています。
                      // これは withConverter を使ったことにより得られる恩恵です。
                      // 何もしなければこのデータ型は Map になります。
                      final post = docs[index].data();
                      return PostWidget(post: post);
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextFormField(
                // 上で作ったコントローラーを与えます。
                controller: controller,
                decoration: InputDecoration(
                  // 未選択時の枠線
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.amber),
                  ),
                  // 選択時の枠線
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.amber,
                      width: 2,
                    ),
                  ),
                  // 中を塗りつぶす色
                  fillColor: Colors.amber[50],
                  // 中を塗りつぶすかどうか
                  filled: true,
                ),
                onFieldSubmitted: (text) {
                  sendPost(text);
                  // 入力中の文字列を削除します。
                  controller.clear();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PostWidget extends StatelessWidget {
  const PostWidget({
    Key? key,
    required this.post,
  }) : super(key: key);

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(
              post.posterImageUrl,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      post.posterName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      // toDate() で Timestamp から DateTime に変換できます。
                      DateFormat('MM/dd HH:mm').format(post.createdAt.toDate()),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        // 角丸にするにはこれを追加します。
                        // 4 の数字を大きくするともっと丸くなります。
                        borderRadius: BorderRadius.circular(4),
                        // 色はここで変えられます
                        // [100] この数字を小さくすると色が薄くなります。
                        color: FirebaseAuth.instance.currentUser!.uid ==
                                post.posterId
                            ? Colors.amber[100]
                            : Colors.blue[100],
                      ),
                      child: Text(post.text),
                    ),

                    /// 編集ボタン
                    if (FirebaseAuth.instance.currentUser!.uid == post.posterId)
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton(
                            onPressed: () {
                              // 削除は reference に対して delete() を呼ぶだけでよい。
                              post.reference.delete();
                            },
                            icon: const Icon(Icons.delete),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
