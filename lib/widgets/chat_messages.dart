import 'package:chat_app/widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser!;

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chat')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (ctx, chatSnapshot) {
        if (chatSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No messages yet...'),
          );
        }

        if (chatSnapshot.hasError) {
          return const Center(
            child: Text('Something went wrong!'),
          );
        }

        final msgs = chatSnapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 40, left: 13, right: 13),
          reverse: true,
          itemCount: msgs.length,
          itemBuilder: (context, index) {
            final msg = msgs[index].data();
            final nextMsg =
                index + 1 < msgs.length ? msgs[index + 1].data() : null;
            final currentMsgUserId = msg['userId'];
            final nextMsgUserId = nextMsg != null ? nextMsg['userId'] : null;
            final isNextUserSame = nextMsgUserId == currentMsgUserId;

            if (isNextUserSame) {
              return MessageBubble.next(
                message: msg['text'],
                isMe: authenticatedUser.uid == msg['userId'],
              );
            } else {
              return MessageBubble.first(
                userImage: msg['userPhotoUrl'],
                username: msg['userName'],
                message: msg['text'],
                isMe: authenticatedUser.uid == msg['userId'],
              );
            }
          },
        );
      },
    );
  }
}
