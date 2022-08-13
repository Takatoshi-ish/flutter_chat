import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import './main.dart';
import './post.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('チャット'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Post>>(
              // stream プロパティに snapshots() を与えると、コレクションの中のドキュメントをリアルタイムで監視することができます。
              stream: postsReference.snapshots(),
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
                    return Text(post.text);
                  },
                );
              },
            ),
          ),
          TextFormField(
            onFieldSubmitted: (text) {
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
            },
          ),
        ],
      ),
    );
  }
}
