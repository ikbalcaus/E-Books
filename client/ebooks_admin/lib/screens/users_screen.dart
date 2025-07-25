import "package:ebooks_admin/models/roles/role.dart";
import "package:ebooks_admin/models/users/user.dart";
import "package:ebooks_admin/models/search_result.dart";
import "package:ebooks_admin/providers/auth_provider.dart";
import "package:ebooks_admin/providers/roles_provider.dart";
import "package:ebooks_admin/providers/users_provider.dart";
import "package:ebooks_admin/screens/master_screen.dart";
import "package:ebooks_admin/utils/globals.dart";
import "package:ebooks_admin/utils/helpers.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

class UsersScreen extends StatefulWidget {
  final String? userName;
  const UsersScreen({super.key, this.userName});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late UsersProvider _usersProvider;
  late RolesProvider _rolesProvider;
  SearchResult<User>? _users;
  SearchResult<Role>? _roles;
  bool _isLoading = true;
  int _currentPage = 1;
  String _orderBy = "Username (A-Z)";
  String _isDeleted = "All users";
  Map<String, dynamic> _currentFilter = {};
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userNameController.text = widget.userName ?? "";
    _currentFilter = {"UserName": widget.userName ?? ""};
    _usersProvider = context.read<UsersProvider>();
    _rolesProvider = context.read<RolesProvider>();
    _fetchUsers();
    _fetchRoles();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _userNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearch(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildResultView(),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  Future _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _usersProvider.getPaged(
        page: _currentPage,
        filter: _currentFilter,
      );
      if (!mounted) return;
      setState(() => _users = users);
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

  Future _fetchRoles() async {
    try {
      final roles = await _rolesProvider.getPaged();
      if (!mounted) return;
      setState(() => _roles = roles);
    } catch (ex) {
      if (!mounted) return;
      Helpers.showErrorMessage(context, ex);
    } finally {
      if (!mounted) return;
    }
  }

  Future _showAssignRoleDialog(int userId) async {
    String? selectedRoleId = _roles!.resultList.first.roleId.toString();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Assign role"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButton<String>(
                isExpanded: true,
                value: selectedRoleId,
                onChanged: (String? newValue) {
                  selectedRoleId = newValue!;
                },
                items: _roles!.resultList.map((role) {
                  return DropdownMenuItem<String>(
                    value: role.roleId.toString(),
                    child: Text(
                      role.name!,
                      style: const TextStyle(fontWeight: FontWeight.normal),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await _rolesProvider.assignRole(
                    userId,
                    int.parse(selectedRoleId!),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    Helpers.showSuccessMessage(context);
                  }
                } catch (ex) {
                  Helpers.showErrorMessage(context, ex);
                }
              },
              child: const Text("Assign"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future _showVerifyPublisherDialog(int id, bool notVerified) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: notVerified
              ? const Text("Confirm verify publisher")
              : const Text("Confirm unverify publisher"),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await _usersProvider.verifyPublisher(id);
                  await _fetchUsers();
                  if (context.mounted) {
                    Navigator.pop(context);
                    Helpers.showSuccessMessage(context);
                  }
                } catch (ex) {
                  Helpers.showErrorMessage(context, ex);
                }
              },
              child: notVerified
                  ? const Text("Verify")
                  : const Text("Unverify"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future _showDeleteUserDialog(int id) async {
    String reason = "";
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm delete"),
          content: TextField(
            decoration: const InputDecoration(
              labelText: "Enter reason for deleting...",
            ),
            onChanged: (value) => reason = value,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (reason.trim().isNotEmpty) {
                  try {
                    await _usersProvider.adminDelete(id, reason);
                    await _fetchUsers();
                    if (context.mounted) {
                      Navigator.pop(context);
                      Helpers.showSuccessMessage(context);
                    }
                  } catch (ex) {
                    Helpers.showErrorMessage(context, ex);
                  }
                }
              },
              child: const Text("Delete"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future _showUndoDeleteUserDialog(int id) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm undo delete"),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await _usersProvider.adminDelete(id, null);
                  await _fetchUsers();
                  if (context.mounted) {
                    Navigator.pop(context);
                    Helpers.showSuccessMessage(context);
                  }
                } catch (ex) {
                  Helpers.showErrorMessage(context, ex);
                }
              },
              child: const Text("Undo delete"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.all(Globals.spacing),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: "First name"),
            ),
          ),
          const SizedBox(width: Globals.spacing),
          Expanded(
            child: TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: "Last name"),
            ),
          ),
          const SizedBox(width: Globals.spacing),
          Expanded(
            child: TextField(
              controller: _userNameController,
              decoration: const InputDecoration(labelText: "User name"),
            ),
          ),
          const SizedBox(width: Globals.spacing),
          Expanded(
            child: TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
          ),
          const SizedBox(width: Globals.spacing),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _isDeleted,
              onChanged: (value) {
                _isDeleted = value!;
              },
              items: ["All users", "Not deleted", "Deleted"].map((
                String value,
              ) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.normal),
                  ),
                );
              }).toList(),
              decoration: const InputDecoration(labelText: "Is deleted"),
            ),
          ),
          const SizedBox(width: Globals.spacing),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _orderBy,
              onChanged: (value) {
                _orderBy = value!;
              },
              items: ["Username (A-Z)", "Username (Z-A)"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.normal),
                  ),
                );
              }).toList(),
              decoration: const InputDecoration(labelText: "Sort by"),
            ),
          ),
          const SizedBox(width: Globals.spacing),
          ElevatedButton(
            onPressed: () async {
              _currentPage = 1;
              _currentFilter = {
                "FirstName": _firstNameController.text,
                "LastName": _lastNameController.text,
                "UserName": _userNameController.text,
                "Email": _emailController.text,
                "OrderBy": _orderBy,
              };
              await _fetchUsers();
            },
            child: const Text("Search"),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        child: DataTable(
          columns: [
            const DataColumn(label: Text("Image")),
            const DataColumn(label: Text("First name")),
            const DataColumn(label: Text("Last name")),
            const DataColumn(label: Text("User name")),
            const DataColumn(label: Text("Email")),
            const DataColumn(label: Text("Deletion reason")),
            if (AuthProvider.role == "Admin")
              const DataColumn(label: Text("Actions")),
          ],
          rows:
              _users?.resultList
                  .map(
                    (user) => DataRow(
                      cells: [
                        DataCell(
                          Image.network(
                            "${Globals.apiAddress}/images/users/${user.filePath}.webp",
                            width: 50,
                            height: 50,
                            errorBuilder: (context, error, stackTrace) =>
                                const Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Icon(Icons.account_box, size: 40),
                                ),
                          ),
                        ),
                        DataCell(Text(user.firstName ?? "")),
                        DataCell(Text(user.lastName ?? "")),
                        DataCell(Text(user.userName ?? "")),
                        DataCell(Text(user.email ?? "")),
                        DataCell(
                          SizedBox(
                            width: 180,
                            child: Text(
                              user.deletionReason ?? "",
                              softWrap: true,
                            ),
                          ),
                        ),
                        if (AuthProvider.role == "Admin")
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.admin_panel_settings),
                                  tooltip: "Assign role",
                                  onPressed: () async {
                                    await _showAssignRoleDialog(user.userId!);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.verified,
                                    color: user.publisherVerifiedById != null
                                        ? Colors.green
                                        : null,
                                  ),
                                  tooltip: user.publisherVerifiedById == null
                                      ? "Verify publisher"
                                      : "Unverify publisher",
                                  onPressed: () async {
                                    await _showVerifyPublisherDialog(
                                      user.userId!,
                                      user.publisherVerifiedById == null,
                                    );
                                  },
                                ),
                                if (user.deletionReason == null)
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    tooltip: "Delete user",
                                    onPressed: () async {
                                      await _showDeleteUserDialog(user.userId!);
                                    },
                                  ),
                                if (user.deletionReason != null)
                                  IconButton(
                                    icon: const Icon(Icons.restore),
                                    tooltip: "Undo delete",
                                    onPressed: () async {
                                      await _showUndoDeleteUserDialog(
                                        user.userId!,
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  )
                  .toList() ??
              [],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (_users == null || _users!.totalPages <= 1) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Globals.spacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () async {
                    _isLoading = true;
                    _currentPage -= 1;
                    await _fetchUsers();
                  }
                : null,
          ),
          Text("Page $_currentPage of ${_users!.totalPages}"),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _users!.totalPages
                ? () async {
                    _isLoading = true;
                    _currentPage += 1;
                    await _fetchUsers();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
