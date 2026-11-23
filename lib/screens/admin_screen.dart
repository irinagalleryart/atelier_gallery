import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/gallery_data_controller.dart';
import '../controllers/locale_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/atelier_models.dart';
import '../services/puzzle_leaderboard_service.dart';
import '../services/supabase_service.dart';
import '../widgets/watercolor_background.dart';

/// Dedicated Web Admin Login and Management Panel accessible via `/admin`.
class AdminScreen extends StatefulWidget {
  final LocaleController localeController;
  final GalleryDataController dataController;

  const AdminScreen({
    super.key,
    required this.localeController,
    required this.dataController,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  User? _currentUser;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    if (SupabaseService.isInitialized) {
      _currentUser = SupabaseService.client.auth.currentUser;
      SupabaseService.client.auth.onAuthStateChange.listen((data) {
        if (mounted) {
          setState(() {
            _currentUser = data.session?.user;
            _isCheckingAuth = false;
          });
        }
      });
    }
    setState(() => _isCheckingAuth = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Web-only access guard requirement
    if (!kIsWeb) {
      return Scaffold(
        body: WatercolorBackground(
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.security, size: 48, color: Colors.amber),
                    const SizedBox(height: 16),
                    Text(
                      l10n.webOnlyAdminNotice,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
                      child: Text(l10n.home),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: WatercolorBackground(
        child: SafeArea(
          child: Column(
            children: [
              _AdminNavBar(
                localeController: widget.localeController,
                currentUser: _currentUser,
              ),
              Expanded(
                child: _isCheckingAuth
                    ? const Center(child: CircularProgressIndicator())
                    : _currentUser == null
                        ? _AdminLoginForm(
                            onLoginSuccess: () {
                              setState(() {
                                _currentUser = SupabaseService.client.auth.currentUser;
                              });
                            },
                          )
                        : _AdminDashboard(
                            dataController: widget.dataController,
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Admin Top Navigation Bar with layout-safe Expanded title and compact right controls
class _AdminNavBar extends StatelessWidget {
  final LocaleController localeController;
  final User? currentUser;

  const _AdminNavBar({
    required this.localeController,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMk = localeController.isMacedonian;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 12 : 24,
        vertical: 12,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l10n.home,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFF8F9FA)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.outlineVariant
                    : Colors.black.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.04,
                  ),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/branding/logo_iriart.png',
                height: isSmall ? 20 : 24,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.palette_outlined, size: 20, color: Color(0xFF7B5E4B)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isSmall ? l10n.adminPanel : '${l10n.appTitle} - ${l10n.adminPanel}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF2D2D2D),
                    fontSize: isSmall ? 14 : 16,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final theme = Theme.of(context);
                return Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? theme.colorScheme.outlineVariant : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _langBtn(context, 'MK', isMk, () => localeController.setLanguageCode('mk')),
                      _langBtn(context, 'EN', !isMk, () => localeController.setLanguageCode('en')),
                    ],
                  ),
                );
              }),
              if (currentUser != null) ...[
                SizedBox(width: isSmall ? 4 : 10),
                TextButton.icon(
                  onPressed: () async {
                    await SupabaseService.client.auth.signOut();
                  },
                  icon: const Icon(Icons.logout, size: 16),
                  label: isSmall ? const SizedBox.shrink() : Text(l10n.signOut),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmall ? 6 : 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _langBtn(BuildContext context, String label, bool selected, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? theme.colorScheme.primary : const Color(0xFF2D2D2D))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF666666)),
          ),
        ),
      ),
    );
  }
}

/// Clean Email + Password Admin Login Form (No public sign-up)
class _AdminLoginForm extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const _AdminLoginForm({required this.onLoginSuccess});

  @override
  State<_AdminLoginForm> createState() => _AdminLoginFormState();
}

class _AdminLoginFormState extends State<_AdminLoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login(AppLocalizations l10n) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (!SupabaseService.isInitialized) {
        throw Exception(l10n.supabaseNotConnected);
      }

      await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      widget.onLoginSuccess();
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 0,
            color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white.withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: isDark ? theme.colorScheme.outlineVariant : Colors.black.withValues(alpha: 0.08),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 48,
                    color: isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.adminLogin,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: l10n.email,
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _login(l10n),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _login(l10n),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isDark ? theme.colorScheme.primary : const Color(0xFF2D2D2D),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.signIn),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full Admin Dashboard with 3 Scrollable Management Tabs
class _AdminDashboard extends StatefulWidget {
  final GalleryDataController dataController;

  const _AdminDashboard({required this.dataController});

  @override
  State<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;

    return ListenableBuilder(
      listenable: widget.dataController,
      builder: (context, _) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? theme.colorScheme.outlineVariant : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B),
                unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF666666),
                indicatorColor: isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                tabs: [
                  _buildTab(Icons.palette_outlined, l10n.manageArtworks, isSmall),
                  _buildTab(Icons.person_outlined, l10n.manageArtistProfile, isSmall),
                  _buildTab(Icons.mark_email_unread_outlined, l10n.manageGuestbook, isSmall),
                  _buildTab(Icons.comment_outlined, l10n.manageArtworkComments, isSmall),
                  _buildTab(Icons.extension_outlined, l10n.managePuzzleScores, isSmall),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ArtworksManagementSection(dataController: widget.dataController),
                  _ArtistProfileSection(dataController: widget.dataController),
                  _GuestbookModerationSection(dataController: widget.dataController),
                  _ArtworkCommentsModerationSection(dataController: widget.dataController),
                  const _PuzzleScoresModerationSection(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTab(IconData icon, String label, bool isSmall) {
    return Tab(
      height: 44,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 12 : 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 1. Artworks Management Section (CRUD) with Wrap header for small screens
class _ArtworksManagementSection extends StatelessWidget {
  final GalleryDataController dataController;

  const _ArtworksManagementSection({required this.dataController});

  void _showArtworkForm(BuildContext context, [ArtworkModel? artwork]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ArtworkFormDialog(
        dataController: dataController,
        artwork: artwork,
      ),
    );
  }

  void _confirmDelete(BuildContext context, ArtworkModel artwork) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteArtwork),
        content: Text('${l10n.confirmDeleteArtwork}\n"${artwork.title}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await dataController.deleteArtwork(artwork.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.artworkDeleted)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.errorDeletingArtwork(e.toString()))),
                  );
                }
              }
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final artworks = dataController.artworks;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1020),
          child: Builder(builder: (context) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${l10n.manageArtworks} (${artworks.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showArtworkForm(context),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addArtwork),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B5E4B),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (artworks.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(child: Text(l10n.noArtworksFound)),
                    ),
                  )
                else
                  Card(
                    elevation: 0,
                    color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white.withValues(alpha: 0.95),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: isDark ? theme.colorScheme.outlineVariant : Colors.black.withValues(alpha: 0.08),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: artworks.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = artworks[index];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              width: 50,
                              height: 50,
                              color: isDark ? theme.colorScheme.surfaceContainer : Colors.grey.shade200,
                              child: item.imageUrl.isNotEmpty
                                  ? Image.network(
                                      item.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.palette_outlined),
                                    )
                                  : const Icon(Icons.palette_outlined),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.localizedTitle(Localizations.localeOf(context).languageCode),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              if (item.isFeatured) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    l10n.featured,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.amber.shade900,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            '${item.technique} • ${item.createdYear} • ${item.dimensions}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.grey.shade600,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                tooltip: l10n.editArtwork,
                                onPressed: () => _showArtworkForm(context, item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: l10n.deleteArtwork,
                                onPressed: () => _confirmDelete(context, item),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// Form Dialog for Creating or Editing Artwork with Image Picker & Supabase Storage upload
class _ArtworkFormDialog extends StatefulWidget {
  final GalleryDataController dataController;
  final ArtworkModel? artwork;

  const _ArtworkFormDialog({
    required this.dataController,
    this.artwork,
  });

  @override
  State<_ArtworkFormDialog> createState() => _ArtworkFormDialogState();
}

class _ArtworkFormDialogState extends State<_ArtworkFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleMkController;
  late TextEditingController _titleEnController;
  late TextEditingController _descriptionMkController;
  late TextEditingController _descriptionEnController;
  late TextEditingController _techniqueController;
  late TextEditingController _yearController;
  late TextEditingController _dimensionsController;
  late TextEditingController _imageUrlController;
  late bool _isFeatured;

  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.artwork;
    _titleMkController = TextEditingController(
      text: a?.titleMk.isNotEmpty == true
          ? a!.titleMk
          : (a?.title ?? ''),
    );
    _titleEnController = TextEditingController(
      text: a?.titleEn.isNotEmpty == true
          ? a!.titleEn
          : (a?.title ?? ''),
    );
    _descriptionMkController = TextEditingController(
      text: a?.descriptionMk.isNotEmpty == true
          ? a!.descriptionMk
          : (a?.description ?? ''),
    );
    _descriptionEnController = TextEditingController(
      text: a?.descriptionEn.isNotEmpty == true
          ? a!.descriptionEn
          : (a?.description ?? ''),
    );
    _techniqueController = TextEditingController(text: a?.technique ?? 'Oil on Canvas');
    _yearController = TextEditingController(text: (a?.createdYear ?? DateTime.now().year).toString());
    _dimensionsController = TextEditingController(text: a?.dimensions ?? '70 x 90 cm');
    _imageUrlController = TextEditingController(text: a?.imageUrl ?? '');
    _isFeatured = a?.isFeatured ?? false;
  }

  @override
  void dispose() {
    _titleMkController.dispose();
    _titleEnController.dispose();
    _descriptionMkController.dispose();
    _descriptionEnController.dispose();
    _techniqueController.dispose();
    _yearController.dispose();
    _dimensionsController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (file == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await file.readAsBytes();
      final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(' ', '_')}';

      final storage = SupabaseService.client.storage.from('artworks');
      await storage.uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$ext',
          upsert: true,
        ),
      );

      final publicUrl = storage.getPublicUrl(fileName);
      setState(() {
        _imageUrlController.text = publicUrl;
      });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.imageUploadFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final tEn = _titleEnController.text.trim();
      final tMk = _titleMkController.text.trim();
      final dEn = _descriptionEnController.text.trim();
      final dMk = _descriptionMkController.text.trim();

      await widget.dataController.saveArtwork(
        id: widget.artwork?.id,
        title: tEn.isNotEmpty ? tEn : (tMk.isNotEmpty ? tMk : 'Untitled'),
        titleMk: tMk,
        titleEn: tEn,
        description: dEn.isNotEmpty ? dEn : dMk,
        descriptionMk: dMk,
        descriptionEn: dEn,
        technique: _techniqueController.text.trim(),
        createdYear: int.tryParse(_yearController.text.trim()) ?? DateTime.now().year,
        dimensions: _dimensionsController.text.trim(),
        isFeatured: _isFeatured,
        imageUrl: _imageUrlController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.artworkSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorSavingArtwork(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.artwork != null;
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: size.width > 700 ? 600 : size.width * 0.9,
        constraints: BoxConstraints(maxHeight: size.height * 0.88),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? l10n.editArtwork : l10n.addArtwork,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _titleEnController,
                        decoration: InputDecoration(
                          labelText: l10n.titleEn,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) &&
                                _titleMkController.text.trim().isEmpty
                            ? l10n.requiredEnOrMk
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleMkController,
                        decoration: InputDecoration(
                          labelText: l10n.titleMk,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionEnController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: l10n.descriptionEn,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionMkController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: l10n.descriptionMk,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _techniqueController,
                              decoration: InputDecoration(
                                labelText: l10n.technique,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _yearController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.year,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dimensionsController,
                        decoration: InputDecoration(
                          labelText: l10n.dimensions,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: Text(l10n.isFeatured),
                        value: _isFeatured,
                        onChanged: (val) => setState(() => _isFeatured = val),
                      ),
                      const SizedBox(height: 16),
                      // Image Upload + Manual URL input
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isUploading ? null : _pickAndUploadImage,
                            icon: _isUploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.upload_file),
                            label: Text(_imageUrlController.text.isNotEmpty
                                ? l10n.changeImage
                                : l10n.uploadImage),
                          ),
                          const SizedBox(width: 12),
                          if (_imageUrlController.text.isNotEmpty)
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Image.network(
                                _imageUrlController.text,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 20),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: InputDecoration(
                          labelText: l10n.imageUrl,
                          hintText: 'https://...',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : () => _save(l10n),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D2D2D),
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 2. Artist Profile & Site Texts Section
class _ArtistProfileSection extends StatefulWidget {
  final GalleryDataController dataController;

  const _ArtistProfileSection({required this.dataController});

  @override
  State<_ArtistProfileSection> createState() => _ArtistProfileSectionState();
}

class _ArtistProfileSectionState extends State<_ArtistProfileSection> {
  late TextEditingController _nameEnController;
  late TextEditingController _nameMkController;
  late TextEditingController _schoolEnController;
  late TextEditingController _schoolMkController;
  late TextEditingController _bioEnController;
  late TextEditingController _bioMkController;
  late TextEditingController _techniquesEnController;
  late TextEditingController _techniquesMkController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.dataController.artistProfile;
    _nameEnController = TextEditingController(text: p.artistNameEn.isNotEmpty ? p.artistNameEn : p.artistName);
    _nameMkController = TextEditingController(text: p.artistNameMk);
    _schoolEnController = TextEditingController(text: p.artSchoolEn.isNotEmpty ? p.artSchoolEn : p.artSchool);
    _schoolMkController = TextEditingController(text: p.artSchoolMk);
    _bioEnController = TextEditingController(text: p.bioEn.isNotEmpty ? p.bioEn : p.bio);
    _bioMkController = TextEditingController(text: p.bioMk);
    _techniquesEnController = TextEditingController(text: p.favoriteTechniquesEn.isNotEmpty ? p.favoriteTechniquesEn : p.favoriteTechniques);
    _techniquesMkController = TextEditingController(text: p.favoriteTechniquesMk);
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameMkController.dispose();
    _schoolEnController.dispose();
    _schoolMkController.dispose();
    _bioEnController.dispose();
    _bioMkController.dispose();
    _techniquesEnController.dispose();
    _techniquesMkController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(AppLocalizations l10n) async {
    setState(() => _isSaving = true);
    try {
      final nameEn = _nameEnController.text.trim();
      final nameMk = _nameMkController.text.trim();
      final schoolEn = _schoolEnController.text.trim();
      final schoolMk = _schoolMkController.text.trim();
      final bioEn = _bioEnController.text.trim();
      final bioMk = _bioMkController.text.trim();
      final techEn = _techniquesEnController.text.trim();
      final techMk = _techniquesMkController.text.trim();

      await widget.dataController.saveArtistProfile(
        artistName: nameEn.isNotEmpty ? nameEn : (nameMk.isNotEmpty ? nameMk : 'Atelier Artist'),
        artistNameMk: nameMk,
        artistNameEn: nameEn,
        bio: bioEn.isNotEmpty ? bioEn : bioMk,
        bioMk: bioMk,
        bioEn: bioEn,
        artSchool: schoolEn.isNotEmpty ? schoolEn : schoolMk,
        artSchoolMk: schoolMk,
        artSchoolEn: schoolEn,
        favoriteTechniques: techEn.isNotEmpty ? techEn : techMk,
        favoriteTechniquesMk: techMk,
        favoriteTechniquesEn: techEn,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorSavingProfile(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
            elevation: 0,
            color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white.withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: isDark ? theme.colorScheme.outlineVariant : Colors.black.withValues(alpha: 0.08),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.manageArtistProfile,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameEnController,
                    decoration: InputDecoration(
                      labelText: l10n.artistNameEn,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameMkController,
                    decoration: InputDecoration(
                      labelText: l10n.artistNameMk,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _schoolEnController,
                    decoration: InputDecoration(
                      labelText: l10n.artSchoolEn,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _schoolMkController,
                    decoration: InputDecoration(
                      labelText: l10n.artSchoolMk,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _bioEnController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: l10n.bioEn,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bioMkController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: l10n.bioMk,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _techniquesEnController,
                    decoration: InputDecoration(
                      labelText: l10n.favoriteTechniquesEn,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _techniquesMkController,
                    decoration: InputDecoration(
                      labelText: l10n.favoriteTechniquesMk,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isSaving ? null : () => _saveProfile(l10n),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF7B5E4B),
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.saveProfile),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 3. Guestbook Moderation Section with responsive title row & manual refresh
class _GuestbookModerationSection extends StatefulWidget {
  final GalleryDataController dataController;

  const _GuestbookModerationSection({required this.dataController});

  @override
  State<_GuestbookModerationSection> createState() =>
      _GuestbookModerationSectionState();
}

class _GuestbookModerationSectionState extends State<_GuestbookModerationSection> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    widget.dataController.loadAllData();
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    try {
      await widget.dataController.loadAllData();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _confirmDelete(BuildContext context, GuestbookModel entry) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.confirmDeleteGuestbook),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await widget.dataController.deleteGuestbookEntry(entry.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.guestbookDeleted)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.errorDeletingEntry(e.toString()))),
                  );
                }
              }
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final entries = widget.dataController.allGuestbookEntries;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1020),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${l10n.manageGuestbook} (${entries.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    tooltip: l10n.refresh,
                    onPressed: _isRefreshing ? null : _refreshData,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (entries.isEmpty)
                Card(
                  elevation: 0,
                  color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white.withValues(alpha: 0.95),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: isDark ? theme.colorScheme.outlineVariant : Colors.black.withValues(alpha: 0.08),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(child: Text(l10n.noEntries)),
                  ),
                )
              else
                Card(
                  elevation: 0,
                  color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white.withValues(alpha: 0.95),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: isDark ? theme.colorScheme.outlineVariant : Colors.black.withValues(alpha: 0.08),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entries.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = entries[index];
                      return ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.authorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.isApproved
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item.isApproved ? l10n.approved : l10n.pendingApproval,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: item.isApproved
                                      ? Colors.green.shade900
                                      : Colors.orange.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            item.message,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () async {
                                try {
                                  await widget.dataController.toggleGuestbookApproval(
                                      item.id, item.isApproved);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(l10n.guestbookStatusUpdated)),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(l10n.errorUpdatingEntry(e.toString()))),
                                    );
                                  }
                                }
                              },
                              child: Text(
                                item.isApproved ? l10n.unapprove : l10n.approve,
                                style: TextStyle(
                                  color: item.isApproved ? Colors.orange : Colors.green,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDelete(context, item),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Artwork Comments Moderation Section in Admin Panel
class _ArtworkCommentsModerationSection extends StatefulWidget {
  final GalleryDataController dataController;

  const _ArtworkCommentsModerationSection({required this.dataController});

  @override
  State<_ArtworkCommentsModerationSection> createState() =>
      _ArtworkCommentsModerationSectionState();
}

class _ArtworkCommentsModerationSectionState
    extends State<_ArtworkCommentsModerationSection> {
  bool _isRefreshing = false;

  void _confirmDelete(BuildContext context, ArtworkCommentModel comment) {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.confirmDeleteComment),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await widget.dataController.deleteComment(comment.id);
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text(l10n.commentDeleted)),
                );
              }
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final comments = widget.dataController.allArtworkComments;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${l10n.manageArtworkComments} (${comments.length})',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    tooltip: l10n.refresh,
                    onPressed: () async {
                      setState(() => _isRefreshing = true);
                      await widget.dataController.loadAllData();
                      if (mounted) setState(() => _isRefreshing = false);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              comments.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: Text(l10n.noEntries),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final isDark = theme.brightness == Brightness.dark;
                        return Card(
                          elevation: 0,
                          color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white.withValues(alpha: 0.9),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: isDark ? theme.colorScheme.outlineVariant : Colors.black.withValues(alpha: 0.08),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      comment.authorName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: comment.isApproved
                                            ? Colors.green.shade50
                                            : Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: comment.isApproved
                                              ? Colors.green.shade300
                                              : Colors.orange.shade300,
                                        ),
                                      ),
                                      child: Text(
                                        comment.isApproved
                                            ? l10n.approved
                                            : l10n.pendingApproval,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: comment.isApproved
                                              ? Colors.green.shade800
                                              : Colors.orange.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  comment.commentText,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        final scaffoldMessenger =
                                            ScaffoldMessenger.of(context);
                                        await widget.dataController
                                            .toggleCommentApproval(
                                          comment.id,
                                          comment.isApproved,
                                        );
                                        if (mounted) {
                                          scaffoldMessenger
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  l10n.commentStatusUpdated),
                                            ),
                                          );
                                        }
                                      },
                                      icon: Icon(
                                        comment.isApproved
                                            ? Icons.close
                                            : Icons.check,
                                        size: 16,
                                      ),
                                      label: Text(
                                        comment.isApproved
                                            ? l10n.unapprove
                                            : l10n.approve,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: comment.isApproved
                                            ? Colors.orange.shade800
                                            : Colors.green.shade800,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _confirmDelete(context, comment),
                                      icon: const Icon(Icons.delete_outline,
                                          size: 16),
                                      label: Text(l10n.delete),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 5. Art Puzzle Nicknames & Scores Moderation Section
class _PuzzleScoresModerationSection extends StatefulWidget {
  const _PuzzleScoresModerationSection();

  @override
  State<_PuzzleScoresModerationSection> createState() =>
      __PuzzleScoresModerationSectionState();
}

class __PuzzleScoresModerationSectionState
    extends State<_PuzzleScoresModerationSection> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<PuzzleAdminScoreEntry> _scores = [];
  String? _errorMessage;
  int _viewMode = 0; // 0: By Nickname Summary, 1: All Score Runs

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadScores() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await PuzzleLeaderboardService.fetchAdminScoreEntries(
        searchQuery: _searchController.text.trim(),
        limit: 200,
      );
      if (mounted) {
        setState(() {
          _scores = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _confirmDeleteSingleScore(PuzzleAdminScoreEntry entry) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteEntry),
        content: Text(l10n.confirmDeletePuzzleScore),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await PuzzleLeaderboardService.deleteScoreEntry(entry.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.scoreEntryDeleted)),
                  );
                }
                _loadScores();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.errorDeletingPuzzleScore(e.toString())),
                    ),
                  );
                }
              }
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteNickname(String nickname, String nicknameNormalized) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteScoresForNickname),
        content: Text(l10n.confirmDeleteNicknameScores(nickname)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await PuzzleLeaderboardService.deleteAllScoresForNickname(
                    nicknameNormalized);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.nicknameScoresDeleted)),
                  );
                }
                _loadScores();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.errorDeletingPuzzleScore(e.toString())),
                    ),
                  );
                }
              }
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    // Group entries by normalized nickname for Summary mode
    final Map<String, _AdminNicknameGroup> groups = {};
    for (final s in _scores) {
      final key = s.nicknameNormalized;
      if (!groups.containsKey(key)) {
        groups[key] = _AdminNicknameGroup(s.nickname, key);
      }
      final g = groups[key]!;
      g.totalPoints += s.pointsEarned;
      g.count += 1;
      if (s.gridSize == 3 && s.pointsEarned > g.best3x3) g.best3x3 = s.pointsEarned;
      if (s.gridSize == 4 && s.pointsEarned > g.best4x4) g.best4x4 = s.pointsEarned;
      if (s.gridSize == 5 && s.pointsEarned > g.best5x5) g.best5x5 = s.pointsEarned;
      if (g.lastActive == null || s.createdAt.isAfter(g.lastActive!)) {
        g.lastActive = s.createdAt;
      }
    }
    final nicknameList = groups.values.toList()
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1020),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Controls
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${l10n.managePuzzleScores} (${_scores.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isDark ? theme.colorScheme.surfaceContainerHigh : const Color(0xFFF5F3EF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => setState(() => _viewMode = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _viewMode == 0
                                      ? (isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l10n.tabTotalPoints,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: _viewMode == 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _viewMode == 0
                                        ? (isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B))
                                        : (isDark ? Colors.white70 : Colors.grey.shade700),
                                  ),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(() => _viewMode = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _viewMode == 1
                                      ? (isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l10n.all,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: _viewMode == 1
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _viewMode == 1
                                        ? (isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B))
                                        : (isDark ? Colors.white70 : Colors.grey.shade700),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B),
                        ),
                        tooltip: l10n.refresh,
                        onPressed: _loadScores,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchNicknames,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _loadScores();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? theme.colorScheme.outlineVariant : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                onSubmitted: (_) => _loadScores(),
              ),

              const SizedBox(height: 16),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                  ),
                ),

              if (_isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      color: isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B),
                    ),
                  ),
                )
              else if (_scores.isEmpty)
                Card(
                  color: isDark ? theme.colorScheme.surfaceContainerHigh : null,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        l10n.noEntries,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                )
              else if (_viewMode == 0)
                // Nickname Summaries Mode
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: nicknameList.length,
                  itemBuilder: (context, index) {
                    final item = nicknameList[index];
                    return Card(
                      elevation: 0,
                      color: isDark ? theme.colorScheme.surfaceContainerHigh : null,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isDark ? theme.colorScheme.outlineVariant : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? theme.colorScheme.primaryContainer
                                    : const Color(0xFF7B5E4B).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? theme.colorScheme.onPrimaryContainer : const Color(0xFF7B5E4B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.nickname,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${l10n.scoresCount(item.count)} • 3x3: ${item.best3x3} pts | 4x4: ${item.best4x4} pts | 5x5: ${item.best5x5} pts',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${item.totalPoints} pts',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red, size: 20),
                                  tooltip: l10n.deleteAllNicknameScores,
                                  onPressed: () => _confirmDeleteNickname(
                                    item.nickname,
                                    item.nicknameNormalized,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              else
                // Individual Score Runs Mode
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _scores.length,
                  itemBuilder: (context, index) {
                    final item = _scores[index];
                    return Card(
                      elevation: 0,
                      color: isDark ? theme.colorScheme.surfaceContainerHigh : null,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isDark ? theme.colorScheme.outlineVariant : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: ListTile(
                        dense: isCompact,
                        title: Text(
                          item.nickname,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          '${item.gridSize}x${item.gridSize} • ${_formatTime(item.durationSeconds)} • ${item.movesCount} ${l10n.movesLabel.toLowerCase()}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '+${item.pointsEarned} pts',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFE2C2AA) : const Color(0xFF7B5E4B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 20),
                              tooltip: l10n.deleteEntry,
                              onPressed: () => _confirmDeleteSingleScore(item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminNicknameGroup {
  final String nickname;
  final String nicknameNormalized;
  int totalPoints = 0;
  int count = 0;
  int best3x3 = 0;
  int best4x4 = 0;
  int best5x5 = 0;
  DateTime? lastActive;

  _AdminNicknameGroup(this.nickname, this.nicknameNormalized);
}

