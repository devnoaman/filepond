// import 'dart:io';

// abstract class ChatController {
//   Future<void> addFile(File message, {int? index});

//   /// Replaces an [oldMessage] with a [newMessage].
//   Future<void> updateMessage(Message oldMessage, Message newMessage);

//   /// Removes a specific [message] from the list.
//   Future<void> removeMessage(Message message);

//   /// Replaces the entire message list with the provided [messages].
//   Future<void> setMessages(List<Message> messages);

//   /// Gets the current list of messages.
//   List<Message> get messages;

//   /// A stream that emits [ChatOperation] objects whenever the message list changes.
//   /// UI components can listen to this stream to react to updates.
//   Stream<ChatOperation> get operationsStream;

//   /// Releases resources used by the controller (e.g., closes streams).
//   void dispose();
// }
