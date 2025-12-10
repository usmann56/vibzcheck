import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';

class UpdateProfileScreen extends StatefulWidget {
  final String? username;
  const UpdateProfileScreen({super.key, this.username});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _usernameFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late TextEditingController _usernameController;
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  bool _isUpdatingUsername = false;
  bool _isUpdatingPassword = false;
  // Playlist controls
  final TextEditingController _newPlaylistController = TextEditingController();
  String? _selectedPlaylistId;
  bool _isUpdatingPlaylist = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _newPlaylistController.dispose();
    super.dispose();
  }

  Future<void> _updateUsername() async {
    if (!_usernameFormKey.currentState!.validate()) return;

    setState(() => _isUpdatingUsername = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    await DatabaseService().updateUser(uid, {
      'username': _usernameController.text.trim(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Username updated successfully!')),
    );

    setState(() => _isUpdatingUsername = false);
  }

  Future<void> _updatePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isUpdatingPassword = true);

    final user = FirebaseAuth.instance.currentUser!;
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: _oldPasswordController.text.trim(),
    );

    try {
      // reauthenticate user with old password
      await user.reauthenticateWithCredential(cred);

      // update password
      await user.updatePassword(_newPasswordController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!')),
      );

      _oldPasswordController.clear();
      _newPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    }

    setState(() => _isUpdatingPassword = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // update username form
            Form(
              key: _usernameFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update Username',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter a username' : null,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isUpdatingUsername ? null : _updateUsername,
                    child: _isUpdatingUsername
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Update Username'),
                  ),
                ],
              ),
            ),
            const Divider(height: 40),

            // update password
            Form(
              key: _passwordFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update Password',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _oldPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Old Password',
                    ),
                    obscureText: true,
                    validator: (val) => val == null || val.isEmpty
                        ? 'Enter your old password'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                    ),
                    obscureText: true,
                    validator: (val) => val == null || val.length < 8
                        ? 'Password must be at least 8 characters'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isUpdatingPassword ? null : _updatePassword,
                    child: _isUpdatingPassword
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Update Password'),
                  ),
                ],
              ),
            ),

            const Divider(height: 40),

            // manage playlist (create/change) — placed under Update Password
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Playlist',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Existing playlists dropdown
                StreamBuilder<QuerySnapshot>(
                  stream: DatabaseService().getAllPlaylistsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    final docs = snapshot.data!.docs;
                    final items = docs
                        .map(
                          (d) => DropdownMenuItem<String>(
                            value: d.id,
                            child: Text(d.id),
                          ),
                        )
                        .toList();
                    return Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedPlaylistId,
                            items: items,
                            hint: const Text('Select existing playlist'),
                            onChanged: (val) => setState(() {
                              _selectedPlaylistId = val;
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed:
                              (_selectedPlaylistId == null ||
                                  _isUpdatingPlaylist)
                              ? null
                              : () async {
                                  await _setUserPlaylist(_selectedPlaylistId!);
                                },
                          child: _isUpdatingPlaylist
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Change'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Create new playlist
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newPlaylistController,
                        decoration: const InputDecoration(
                          labelText: 'New playlist name',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isUpdatingPlaylist
                          ? null
                          : () async {
                              final name = _newPlaylistController.text.trim();
                              if (name.isEmpty) return;
                              await DatabaseService().createPlaylistIfMissing(name);
                              await _setUserPlaylist(name);
                              _newPlaylistController.clear();
                            },
                      child: _isUpdatingPlaylist
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Create & Use'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setUserPlaylist(String id) async {
    setState(() => _isUpdatingPlaylist = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await DatabaseService().updateUserPlaylist(uid, id);
    setState(() => _isUpdatingPlaylist = false);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Playlist set to "$id"')));
    }
  }
}
