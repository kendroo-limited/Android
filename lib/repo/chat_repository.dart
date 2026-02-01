// import '../model/conversation.dart';
// import '../model/message.dart';
// import '../model/user_model.dart';
//
// abstract class IChatRepository {
//   Future<List<Conversation>> fetchInbox();
//   Future<List<Message>> fetchMessages(String conversationId, OdooUser peer);
//   Future<Message> sendMessage({
//     required String conversationId,
//     required String text,
//     required OdooUser sender,
//   });
// }
//

import 'package:http/http.dart' as http;

import '../model/conversation.dart';
import '../model/message.dart';
import '../model/user_model.dart';

abstract class IChatRepository {
  Future<List<Conversation>> fetchInbox();
  Future<List<Message>> fetchMessages(String conversationId, OdooUser peer);

  Future<Message> sendMessage({
    required String conversationId,
    required String text,
    required OdooUser sender,
    List<String>? attachmentIds,
  });

  Future<List<UploadedAttachment>> uploadAttachments({
    required String conversationId,
    required List<PickedAttachment> picked,
  });


  Future<List<OdooUser>> fetchChatPartners();

  Future<Conversation> getOrCreateDirectChannel({
    required int partnerId,
    required String partnerName,
  });
}



class UploadedAttachment {
  final String id;
  final String name;
  final String url;
  final String mimeType;
  final int size;
  final bool isImage;
  UploadedAttachment({
    required this.id,
    required this.name,
    this.url = '',
    this.mimeType = '',
    this.size = 0,
    this.isImage = false,
  });


}
