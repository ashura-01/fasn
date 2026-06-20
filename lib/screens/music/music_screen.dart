import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/app_theme.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});
  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> with SingleTickerProviderStateMixin {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _player = AudioPlayer();
  List<SongModel> _songs = [];
  List<SongModel> _playlist = []; // valid URI songs actually in player
  bool _hasPermission = false;
  bool _loading = true;
  int _currentIndex = -1;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _shuffleOn = false;
  LoopMode _loopMode = LoopMode.off;
  late AnimationController _vinylCtrl;

  @override
  void initState() {
    super.initState();
    _vinylCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    _requestPermission();
    _player.positionStream.listen((p) => setState(() => _position = p));
    _player.durationStream.listen((d) => setState(() => _duration = d ?? Duration.zero));
    _player.playingStream.listen((p) {
      setState(() => _isPlaying = p);
      if (p) _vinylCtrl.repeat(); else _vinylCtrl.stop();
    });
    _player.currentIndexStream.listen((i) {
      if (i != null) setState(() => _currentIndex = i);
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.audio.request();
    if (status.isGranted) {
      setState(() => _hasPermission = true);
      await _loadSongs();
    } else {
      setState(() { _hasPermission = false; _loading = false; });
    }
  }

  Future<void> _loadSongs() async {
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    setState(() {
      _songs = songs.where((s) => s.duration != null && s.duration! > 10000).toList();
      _loading = false;
    });
  }

  Future<void> _playSong(int index) async {
    if (_songs.isEmpty) return;
    _playlist = _songs.where((s) => s.uri != null && s.uri!.isNotEmpty).toList();
    if (_playlist.isEmpty) return;
    // Remap index to valid songs list
    final validIndex = _playlist.indexOf(_songs[index]);
    final playIndex = validIndex >= 0 ? validIndex : 0;
    final playlist = ConcatenatingAudioSource(
      children: _playlist
          .map((s) => AudioSource.uri(Uri.parse(s.uri!)))
          .toList(),
    );
    try {
      await _player.setAudioSource(playlist, initialIndex: playIndex);
      await _player.play();
    } catch (e) {
      debugPrint('Error playing song: $e');
    }
  }

  SongModel? get _current =>
      _currentIndex >= 0 && _currentIndex < _playlist.length ? _playlist[_currentIndex]
      : _currentIndex >= 0 && _currentIndex < _songs.length ? _songs[_currentIndex] : null;

  String _formatDuration(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  void dispose() {
    _player.dispose();
    _vinylCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(children: [
        _buildHeader(),
        if (_current != null) _buildNowPlaying(),
        Expanded(child: _buildSongList()),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 16),
      color: AppTheme.surface,
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Music Player',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 26, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            Text('${_songs.length} songs',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppTheme.textSecondary)),
          ]),
        ),
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: AppTheme.primaryLight.withOpacity(0.4), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.music_note_rounded, color: AppTheme.primaryDark, size: 22),
        ),
      ]),
    );
  }

  Widget _buildNowPlaying() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8FA3), Color(0xFFFFB6C1)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.primaryDark.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(children: [
        Row(children: [
          // Vinyl disc
          RotationTransition(
            turns: _vinylCtrl,
            child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Colors.black87, Colors.grey.shade800, AppTheme.primaryDark, Colors.white,
                ], stops: const [0.2, 0.4, 0.7, 1.0]),
              ),
              child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                _current?.title ?? 'Unknown',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                _current?.artist ?? 'Unknown Artist',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white.withOpacity(0.8)),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        // Seek bar
        Column(children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              trackHeight: 3,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: _duration.inMilliseconds > 0
                  ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
                  : 0.0,
              onChanged: (v) {
                final pos = Duration(milliseconds: (v * _duration.inMilliseconds).round());
                _player.seek(pos);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(children: [
              Text(_formatDuration(_position), style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white.withOpacity(0.9))),
              const Spacer(),
              Text(_formatDuration(_duration), style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white.withOpacity(0.9))),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        // Controls
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Shuffle
          IconButton(
            icon: Icon(Icons.shuffle_rounded, color: _shuffleOn ? Colors.white : Colors.white.withOpacity(0.5), size: 22),
            onPressed: () async {
              setState(() => _shuffleOn = !_shuffleOn);
              await _player.setShuffleModeEnabled(_shuffleOn);
            },
          ),
          // Previous
          IconButton(
            icon: Icon(Icons.skip_previous_rounded, color: Colors.white, size: 30),
            onPressed: () => _player.seekToPrevious(),
          ),
          // Play/Pause
          GestureDetector(
            onTap: () => _isPlaying ? _player.pause() : _player.play(),
            child: Container(
              width: 58, height: 58,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: AppTheme.primaryDark, size: 32,
              ),
            ),
          ),
          // Next
          IconButton(
            icon: Icon(Icons.skip_next_rounded, color: Colors.white, size: 30),
            onPressed: () => _player.seekToNext(),
          ),
          // Loop
          IconButton(
            icon: Icon(
              _loopMode == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
              color: _loopMode != LoopMode.off ? Colors.white : Colors.white.withOpacity(0.5),
              size: 22,
            ),
            onPressed: () async {
              final next = _loopMode == LoopMode.off
                  ? LoopMode.all
                  : _loopMode == LoopMode.all
                      ? LoopMode.one
                      : LoopMode.off;
              setState(() => _loopMode = next);
              await _player.setLoopMode(next);
            },
          ),
        ]),
      ]),
    );
  }

  Widget _buildSongList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryDark));
    }
    if (!_hasPermission) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.music_off_rounded, size: 56, color: AppTheme.primary.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text('Storage permission required', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            const Text('Please grant storage access to play your music.', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppTheme.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Open Settings'),
              onPressed: () => openAppSettings(),
            ),
          ]),
        ),
      );
    }
    if (_songs.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.library_music_rounded, size: 56, color: AppTheme.primary.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text('No songs found', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, color: AppTheme.textSecondary)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: _songs.length,
      itemBuilder: (ctx, i) {
        final song = _songs[i];
        final isPlaying = _currentIndex == i && _isPlaying;
        final isCurrent = _currentIndex == i;
        return GestureDetector(
          onTap: () => _playSong(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isCurrent ? AppTheme.primaryLight.withOpacity(0.35) : AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCurrent ? AppTheme.primaryDark.withOpacity(0.3) : AppTheme.divider,
                width: isCurrent ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              // Art placeholder
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isCurrent ? AppTheme.primaryDark.withOpacity(0.15) : AppTheme.primaryLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPlaying ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
                  color: isCurrent ? AppTheme.primaryDark : AppTheme.textHint,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(song.title,
                    style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600,
                      color: isCurrent ? AppTheme.primaryDark : AppTheme.textPrimary,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  Text(song.artist ?? 'Unknown Artist',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppTheme.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ]),
              ),
              if (song.duration != null)
                Text(
                  _formatDuration(Duration(milliseconds: song.duration!)),
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppTheme.textHint),
                ),
            ]),
          ),
        );
      },
    );
  }
}
