import "package:ebooks_user/providers/questions_provider.dart";
import "package:ebooks_user/screens/master_screen.dart";
import "package:ebooks_user/utils/globals.dart";
import "package:ebooks_user/utils/helpers.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  late QuestionsProvider _questionsProvider;
  final TextEditingController _questionController = TextEditingController();

  final List<Map<String, String>> _faqList = [
    {
      "question": "How do I purchase a book?",
      "answer":
          "Select a book and click the \"Buy\" button. You can pay using your Credit Card or Paypal.",
    },
    {
      "question": "Can I read books offline?",
      "answer":
          "Currently no, but we are planning to add offline reading in the future.",
    },
    {
      "question": "How do I change my password?",
      "answer": "Go to your profile, click on \"Edit profile\" and change it.",
    },
    {
      "question": "Can I get a refund for a book?",
      "answer":
          "Refunds are available within 7 days of purchase if the book has not been downloaded.",
    },
    {
      "question": "How do I contact support?",
      "answer":
          "You can contact support using the \"Help and Support\" section in your profile or send a question through the FAQ page.",
    },
    {
      "question": "How do I follow a publisher?",
      "answer":
          "Visit the publisher's page and click the \"Follow\" button to get updates on their new books.",
    },
    {
      "question": "How do I add books to my wishlist?",
      "answer":
          "Click on the three dots icons, and then click \"Add to wishlist\".",
    },
    {
      "question": "Are there discounts on books?",
      "answer":
          "Some books may have discounts. Check the book details to see if a discount is active.",
    },
    {
      "question": "Is my personal data safe?",
      "answer":
          "Yes, we follow strict security protocols to protect your data and never share it with third parties.",
    },
    {
      "question": "Can I share books with friends?",
      "answer":
          "No, books are for personal use only and sharing is not allowed due to copyright rules.",
    },
    {
      "question": "How can I rate a book?",
      "answer":
          "Open the book details page and scroll down to the rating section to give your feedback.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _questionsProvider = context.read<QuestionsProvider>();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(showBackButton: true, child: _buildResultView());
  }

  Future _submitQuestion() async {
    if (_questionController.text.trim().isNotEmpty) {
      try {
        await _questionsProvider.post({
          "message": _questionController.text,
        }, null);
        Helpers.showSuccessMessage(context, "Question has been sent");
        Navigator.pop(context);
      } catch (ex) {
        Helpers.showErrorMessage(context, ex);
      }
    }
  }

  Widget _buildResultView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Column(
        children: [
          const Text(
            "Frequently asked questions",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _faqList.length,
              itemBuilder: (context, index) {
                return ExpansionTile(
                  title: Text(_faqList[index]["question"] ?? ""),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(_faqList[index]["answer"] ?? ""),
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(width: 5),
              Expanded(
                child: TextField(
                  controller: _questionController,
                  decoration: const InputDecoration(
                    labelText: "Still have a question? Ask here...",
                    contentPadding: EdgeInsets.symmetric(horizontal: 6),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () async => await _submitQuestion(),
                icon: const Icon(Icons.send),
                tooltip: "Send",
                color: Globals.backgroundColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
