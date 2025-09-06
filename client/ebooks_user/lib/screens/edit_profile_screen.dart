import "dart:convert";
import "dart:io";
import "package:ebooks_user/models/users/user.dart";
import "package:ebooks_user/providers/auth_provider.dart";
import "package:ebooks_user/providers/users_provider.dart";
import "package:ebooks_user/screens/master_screen.dart";
import "package:ebooks_user/screens/profile_screen.dart";
import "package:ebooks_user/utils/globals.dart";
import "package:ebooks_user/utils/helpers.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "package:provider/provider.dart";

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late UsersProvider _usersProvider;
  final _formKey = GlobalKey<FormState>();
  User? _user;
  bool _isLoading = true;
  Map<String, List<String>> _fieldErrors = {};
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _usersProvider = context.read<UsersProvider>();
    _fetchUser();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future _fetchUser() async {
    setState(() => _isLoading = true);
    try {
      final user = await _usersProvider.getById(AuthProvider.userId ?? 0);
      if (!mounted) return;
      setState(() {
        _user = user;
        _firstNameController.text = _user?.firstName ?? "";
        _lastNameController.text = _user?.lastName ?? "";
      });
    } catch (ex) {
      if (!mounted) return;
      Helpers.showErrorMessage(context, ex);
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future _pickImage() async {
    File? selectedFile;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        selectedFile = File(picked.path);
      }
    } else {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        selectedFile = File(result.files.single.path!);
      }
    }
    if (selectedFile != null) {
      setState(() {
        _imageFile = selectedFile;
      });
    }
  }

  Future _saveChanges() async {
    setState(() => _fieldErrors.clear());
    if (_newPasswordController.text.isNotEmpty &&
        _newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _fieldErrors["ConfirmPassword"] = ["Passwords do not match"];
      });
      return;
    }
    Map<String, dynamic> request = {
      "firstName": _firstNameController.text,
      "lastName": _lastNameController.text,
    };
    if (_newPasswordController.text.isNotEmpty) {
      request.addAll({
        "oldPassword": _oldPasswordController.text,
        "newPassword": _newPasswordController.text,
      });
    }
    if (_imageFile != null) {
      request["imageFile"] = _imageFile!;
    }
    try {
      await _usersProvider.editUser(AuthProvider.userId ?? 0, request);
      if (mounted) {
        Helpers.showSuccessMessage(context, "Profile edited successfully");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
          (_) => false,
        );
      }
    } catch (ex) {
      try {
        final Map<String, dynamic> data = jsonDecode(ex.toString());
        final errors = data["errors"] as Map<String, dynamic>;
        setState(() {
          _fieldErrors = errors.map((key, value) {
            final List<String> messages = List<String>.from(value);
            return MapEntry(key, messages);
          });
        });
      } catch (ex) {
        setState(() {
          _fieldErrors = {
            "general": ["An error occurred. Please try again"],
          };
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      showBackButton: true,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildResultView(),
    );
  }

  Widget _buildResultView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color.fromARGB(255, 24, 22, 32)
                : Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  "Edit Profile",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async => await _pickImage(),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    child: ClipOval(
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: _imageFile != null
                            ? Image.file(_imageFile!, fit: BoxFit.cover)
                            : (_user?.filePath != null
                                  ? Image.network(
                                      "${Globals.apiAddress}/images/users/${_user!.filePath}.webp?t=${DateTime.now().millisecondsSinceEpoch}",
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.camera_alt,
                                        size: 40,
                                        color: Colors.grey[800],
                                      ),
                                    )
                                  : Icon(
                                      Icons.camera_alt,
                                      size: 0,
                                      color: Colors.grey[800],
                                    )),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: InputDecoration(
                          labelText: "First Name",
                          errorText: _fieldErrors["FirstName"]?.first,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: InputDecoration(
                          labelText: "Last Name",
                          errorText: _fieldErrors["LastName"]?.first,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _oldPasswordController,
                  decoration: InputDecoration(
                    labelText: "Old Password",
                    errorText: _fieldErrors["OldPassword"]?.first,
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(
                    labelText: "New Password",
                    errorText: _fieldErrors["NewPassword"]?.first,
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: "Confirm New Password",
                    errorText: _fieldErrors["ConfirmPassword"]?.first,
                  ),
                  obscureText: true,
                ),
                if (_fieldErrors.containsKey("general")) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _fieldErrors["general"]!
                          .map(
                            (msg) => Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                msg,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async => await _saveChanges(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Globals.backgroundColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    child: const Text(
                      "Save Changes",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
