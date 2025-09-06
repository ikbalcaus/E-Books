import "dart:convert";
import "dart:io";
import "package:ebooks_user/models/authors/author.dart";
import "package:ebooks_user/models/books/book.dart";
import "package:ebooks_user/models/genres/genre.dart";
import "package:ebooks_user/models/languages/language.dart";
import "package:ebooks_user/models/search_result.dart";
import "package:ebooks_user/providers/authors_provider.dart";
import "package:ebooks_user/providers/books_provider.dart";
import "package:ebooks_user/providers/genres_provider.dart";
import "package:ebooks_user/providers/languages_provider.dart";
import "package:ebooks_user/screens/master_screen.dart";
import "package:ebooks_user/screens/profile_screen.dart";
import "package:ebooks_user/utils/globals.dart";
import "package:ebooks_user/utils/helpers.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:image_picker/image_picker.dart";
import "package:provider/provider.dart";
import "package:reorderables/reorderables.dart";

class EditBookScreen extends StatefulWidget {
  final int? bookId;
  const EditBookScreen({super.key, this.bookId});

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  late BooksProvider _booksProvider;
  late AuthorsProvider _authorsProvider;
  late GenresProvider _genresProvider;
  late LanguagesProvider _languagesProvider;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _pagesController = TextEditingController();
  final _authorController = TextEditingController();
  final _genreController = TextEditingController();
  final _languageController = TextEditingController();
  Book? _book;
  SearchResult<Author>? _authors;
  SearchResult<Genre>? _genres;
  SearchResult<Language>? _languages;
  List<Author> _selectedAuthors = [];
  List<Genre> _selectedGenres = [];
  Language? _selectedLanguage;
  File? _imageFile;
  File? _bookPdfFile;
  File? _summaryPdfFile;
  bool _isLoading = true;
  Map<String, List<String>> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _booksProvider = context.read<BooksProvider>();
    _authorsProvider = context.read<AuthorsProvider>();
    _genresProvider = context.read<GenresProvider>();
    _languagesProvider = context.read<LanguagesProvider>();
    if (widget.bookId != null) {
      _fetchBook();
    } else {
      _isLoading = false;
    }
    _fetchAuthors();
    _fetchGenres();
    _fetchLanguages();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _pagesController.dispose();
    _authorController.dispose();
    _genreController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  Future _fetchBook() async {
    try {
      final book = await _booksProvider.getById(widget.bookId ?? 0);
      if (!mounted) return;
      setState(() {
        _book = book;
        _titleController.text = book.title ?? "";
        _descriptionController.text = book.description ?? "";
        _priceController.text =
            (book.price?.toString().replaceAll(".0", "") ?? "");
        _pagesController.text = book.numberOfPages?.toString() ?? "";
        _selectedAuthors = book.authors ?? [];
        _selectedGenres = book.genres ?? [];
        _selectedLanguage = book.language;
      });
    } catch (ex) {
      Helpers.showErrorMessage(context, ex);
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future _fetchAuthors() async {
    try {
      final authors = await _authorsProvider.getPaged();
      if (!mounted) return;
      setState(() {
        _authors = authors;
      });
    } catch (ex) {
      Helpers.showErrorMessage(context, ex);
    }
  }

  Future _fetchGenres() async {
    try {
      final genres = await _genresProvider.getPaged();
      if (!mounted) return;
      setState(() {
        _genres = genres;
      });
    } catch (ex) {
      Helpers.showErrorMessage(context, ex);
    }
  }

  Future _fetchLanguages() async {
    try {
      final languages = await _languagesProvider.getPaged();
      if (!mounted) return;
      setState(() {
        _languages = languages;
      });
    } catch (ex) {
      Helpers.showErrorMessage(context, ex);
    }
  }

  void _showAuthorsDialog() {
    final TextEditingController newAuthorController = TextEditingController();
    List<Author> filteredAuthors = [];
    void filterAuthors(String input) {
      filteredAuthors = (_authors?.resultList ?? <Author>[]).where((author) {
        final isNotSelected = !_selectedAuthors.any(
          (x) => x.authorId == author.authorId,
        );
        return isNotSelected &&
            author.name!.toLowerCase().contains(input.toLowerCase());
      }).toList();
    }

    filterAuthors("");
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Select Authors"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newAuthorController,
                            decoration: const InputDecoration(
                              hintText: "Type author name",
                            ),
                            onChanged: (value) {
                              setStateDialog(() {
                                filterAuthors(value);
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            final input = newAuthorController.text.trim();
                            if (input.isEmpty) return;
                            final alreadySelected = _selectedAuthors.any(
                              (author) =>
                                  author.name!.toLowerCase() ==
                                  input.toLowerCase(),
                            );
                            if (!alreadySelected) {
                              setState(() {
                                _selectedAuthors.add(
                                  Author(authorId: -1, name: input),
                                );
                              });
                              newAuthorController.clear();
                              setStateDialog(() {
                                filterAuthors("");
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: filteredAuthors.isEmpty
                          ? const Center(child: Text("No authors found"))
                          : ListView.builder(
                              itemCount: filteredAuthors.length,
                              itemBuilder: (context, index) {
                                final author = filteredAuthors[index];
                                return ListTile(
                                  title: Text(author.name!),
                                  onTap: () {
                                    setState(() {
                                      _selectedAuthors.add(author);
                                    });
                                    setStateDialog(() {
                                      filterAuthors(newAuthorController.text);
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    ReorderableWrap(
                      spacing: 8,
                      runSpacing: 4,
                      needsLongPressDraggable: false,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          final item = _selectedAuthors.removeAt(oldIndex);
                          _selectedAuthors.insert(newIndex, item);
                        });
                        setStateDialog(() {});
                      },
                      children: _selectedAuthors
                          .map(
                            (author) => Chip(
                              label: Text(author.name!),
                              onDeleted: () {
                                setState(() {
                                  _selectedAuthors.remove(author);
                                });
                                setStateDialog(() {
                                  filterAuthors(newAuthorController.text);
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGenresDialog() {
    final TextEditingController newGenreController = TextEditingController();
    List<Genre> filteredGenres = [];
    void filterGenres(String input) {
      filteredGenres = (_genres?.resultList ?? <Genre>[]).where((genre) {
        final isNotSelected = !_selectedGenres.any(
          (x) => x.genreId == genre.genreId,
        );
        return isNotSelected &&
            genre.name!.toLowerCase().contains(input.toLowerCase());
      }).toList();
    }

    filterGenres("");
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Select Genres"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newGenreController,
                            decoration: const InputDecoration(
                              hintText: "Type genre",
                            ),
                            onChanged: (value) {
                              setStateDialog(() {
                                filterGenres(value);
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            final input = newGenreController.text.trim();
                            if (input.isEmpty) return;
                            final alreadySelected = _selectedGenres.any(
                              (genre) =>
                                  genre.name!.toLowerCase() ==
                                  input.toLowerCase(),
                            );
                            if (!alreadySelected) {
                              setState(() {
                                _selectedGenres.add(
                                  Genre(genreId: -1, name: input),
                                );
                              });
                              newGenreController.clear();
                              setStateDialog(() {
                                filterGenres("");
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: filteredGenres.isEmpty
                          ? const Center(child: Text("No genres found"))
                          : ListView.builder(
                              itemCount: filteredGenres.length,
                              itemBuilder: (context, index) {
                                final genre = filteredGenres[index];
                                return ListTile(
                                  title: Text(genre.name!),
                                  onTap: () {
                                    setState(() {
                                      _selectedGenres.add(genre);
                                    });
                                    setStateDialog(() {
                                      filterGenres(newGenreController.text);
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    ReorderableWrap(
                      spacing: 8,
                      runSpacing: 4,
                      needsLongPressDraggable: false,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          final item = _selectedGenres.removeAt(oldIndex);
                          _selectedGenres.insert(newIndex, item);
                        });
                        setStateDialog(() {});
                      },
                      children: _selectedGenres
                          .map(
                            (genre) => Chip(
                              label: Text(genre.name!),
                              onDeleted: () {
                                setState(() {
                                  _selectedGenres.remove(genre);
                                });
                                setStateDialog(() {
                                  filterGenres(newGenreController.text);
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLanguageDialog() {
    final TextEditingController newLanguageController = TextEditingController();
    List<Language> filteredLanguages = [];
    void filterLanguages(String input) {
      filteredLanguages = (_languages?.resultList ?? <Language>[]).where((
        lang,
      ) {
        return lang.name!.toLowerCase().contains(input.toLowerCase());
      }).toList();
    }

    filterLanguages("");
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Select Language"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newLanguageController,
                            decoration: const InputDecoration(
                              hintText: "Type language name",
                            ),
                            onChanged: (value) {
                              setStateDialog(() {
                                filterLanguages(value);
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            final input = newLanguageController.text.trim();
                            if (input.isEmpty) return;
                            final existing = (_languages?.resultList ?? [])
                                .firstWhere(
                                  (lang) =>
                                      lang.name!.toLowerCase() ==
                                      input.toLowerCase(),
                                  orElse: () =>
                                      Language(languageId: -1, name: input),
                                );

                            setState(() {
                              _selectedLanguage = existing;
                            });

                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: filteredLanguages.isEmpty
                          ? const Center(child: Text("No languages found"))
                          : ListView.builder(
                              itemCount: filteredLanguages.length,
                              itemBuilder: (context, index) {
                                final language = filteredLanguages[index];
                                return ListTile(
                                  title: Text(language.name!),
                                  onTap: () {
                                    setState(() {
                                      _selectedLanguage = language;
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future _pickImage() async {
    File? selectedFile;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) selectedFile = File(picked.path);
    } else {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        selectedFile = File(result.files.single.path!);
      }
    }
    if (selectedFile != null) {
      setState(() => _imageFile = selectedFile);
    }
  }

  Future _pickPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["pdf"],
    );
    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  Future _saveChanges() async {
    setState(() => _fieldErrors.clear());
    Map<String, dynamic> request = {
      "title": _titleController.text,
      "description": _descriptionController.text,
      "price": (double.tryParse(_priceController.text) ?? 0) / 10,
      "numberOfPages": int.tryParse(_pagesController.text),
      "authors": jsonEncode(
        _selectedAuthors.map((author) => author.name).toList(),
      ),
      "genres": jsonEncode(_selectedGenres.map((genre) => genre.name).toList()),
      "language": _selectedLanguage?.name,
    };
    if (_imageFile != null) request["imageFile"] = _imageFile!;
    if (_bookPdfFile != null) {
      request["bookPdfFile"] = _bookPdfFile!;
    }
    if (_summaryPdfFile != null) {
      request["summaryPdfFile"] = _summaryPdfFile!;
    }
    try {
      await _booksProvider.editBook(widget.bookId, request);
      if (mounted) {
        Helpers.showSuccessMessage(context, "Book updated successfully");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
          (_) => false,
        );
      }
    } catch (ex) {
      try {
        final data = Map<String, dynamic>.from(ex as dynamic);
        final errors = data["errors"] as Map<String, dynamic>;
        setState(() {
          _fieldErrors = errors.map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          );
        });
      } catch (_) {
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 300,
                  height: 450,
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : (_book?.filePath != null
                            ? Image.network(
                                "${Globals.apiAddress}/images/books/${_book!.filePath}.webp?t=${DateTime.now().millisecondsSinceEpoch}",
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image, size: 300),
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 60,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              )),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Title",
                errorText: _fieldErrors["Title"]?.first,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Description",
                errorText: _fieldErrors["Description"]?.first,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: "Price (€)",
                errorText: _fieldErrors["Price"]?.first,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pagesController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: "Number of Pages",
                errorText: _fieldErrors["NumberOfPages"]?.first,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _showAuthorsDialog(),
              child: InputDecorator(
                decoration: InputDecoration(labelText: "Authors"),
                child: Text(
                  _selectedAuthors.isEmpty
                      ? "No authors selected"
                      : _selectedAuthors
                            .map((author) => author.name)
                            .join(", "),
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _showGenresDialog(),
              child: InputDecorator(
                decoration: InputDecoration(labelText: "Genres"),
                child: Text(
                  _selectedGenres.isEmpty
                      ? "No genres selected"
                      : _selectedGenres.map((genre) => genre.name).join(", "),
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _showLanguageDialog,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: "Language"),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedLanguage?.name ?? "No language selected",
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_selectedLanguage != null)
                      GestureDetector(
                        onTap: () => setState(() => _selectedLanguage = null),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.clear, size: 20),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final file = await _pickPdfFile();
                  if (file != null) {
                    setState(() => _bookPdfFile = file);
                  }
                },
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(
                  _bookPdfFile != null
                      ? "Book PDF selected"
                      : "Select Book PDF",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final file = await _pickPdfFile();
                  if (file != null) {
                    setState(() => _summaryPdfFile = file);
                  }
                },
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(
                  _summaryPdfFile != null
                      ? "Summary PDF selected"
                      : "Select Summary PDF",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_fieldErrors.containsKey("general"))
              ..._fieldErrors["general"]!.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    e,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ),
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
    );
  }
}
