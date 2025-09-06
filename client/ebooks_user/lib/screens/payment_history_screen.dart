import "package:ebooks_user/models/purchases/purchase.dart";
import "package:ebooks_user/models/search_result.dart";
import "package:ebooks_user/providers/purchases_provider.dart";
import "package:ebooks_user/screens/master_screen.dart";
import "package:ebooks_user/screens/publisher_screen.dart";
import "package:ebooks_user/utils/helpers.dart";
import "package:ebooks_user/widgets/not_logged_in_view.dart";
import "package:flutter/material.dart";
import "package:ebooks_user/providers/auth_provider.dart";
import "package:provider/provider.dart";

class PaymentHistoryScreen extends StatefulWidget {
  final int publisherId;
  const PaymentHistoryScreen({super.key, required this.publisherId});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  late PurchasesProvider _purchasesProvider;
  SearchResult<Purchase>? _purchases;
  int _currentPage = 1;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (AuthProvider.isLoggedIn) {
      _purchasesProvider = context.read<PurchasesProvider>();
      _fetchPurchases();
      _scrollController.addListener(_scrollListener);
    }
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading &&
          (_purchases?.resultList.length ?? 0) < (_purchases?.count ?? 0)) {
        _currentPage++;
        _fetchPurchases(append: true);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (!AuthProvider.isLoggedIn) {
      content = Center(child: NotLoggedInView());
    } else if (_isLoading && (_purchases?.resultList.isEmpty ?? true)) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_purchases?.count == 0) {
      content = const Center(child: Text("Your payment history is empty"));
    } else {
      content = _buildResultView();
    }
    return MasterScreen(showBackButton: true, child: content);
  }

  Future _fetchPurchases({bool append = false}) async {
    setState(() => _isLoading = true);
    try {
      final purchases = await _purchasesProvider.getPaged(page: _currentPage);
      if (!mounted) return;
      setState(() {
        if (append && _purchases != null) {
          _purchases?.resultList.addAll(purchases.resultList);
          _purchases?.count = purchases.count;
        } else {
          _purchases = purchases;
        }
      });

      // Provjera ako lista nije dovoljno duga da popuni ekran
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_scrollController.hasClients) return;

        final maxScroll = _scrollController.position.maxScrollExtent;
        if (!_isLoading &&
            (_purchases?.resultList.length ?? 0) < (_purchases?.count ?? 0) &&
            maxScroll <= 0) {
          _currentPage++;
          _fetchPurchases(append: true);
        }
      });
    } catch (ex) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Helpers.showErrorMessage(context, ex);
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Widget _buildResultView() {
    final items = _purchases?.resultList ?? [];
    return ListView.builder(
      controller: _scrollController,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final purchase = items[index];
        final isLast = index == items.length - 1;
        return Column(
          children: [
            ListTile(
              title: Text(purchase.book?.title ?? ""),
              subtitle: Text(
                purchase.user!.userId == widget.publisherId
                    ? purchase.publisher?.userName ?? ""
                    : purchase.user?.userName ?? "",
              ),
              trailing: Text(
                purchase.user!.userId == widget.publisherId
                    ? "-${purchase.totalPrice?.toStringAsFixed(2)}€"
                    : "+${purchase.totalPrice?.toStringAsFixed(2)}€",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: purchase.user!.userId == widget.publisherId
                      ? Colors.red
                      : Colors.green,
                ),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PublisherScreen(
                    publisherId: purchase.user!.userId == widget.publisherId
                        ? purchase.publisher!.userId!
                        : purchase.user!.userId!,
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            if (isLast) const Divider(height: 0.1),
          ],
        );
      },
    );
  }
}
