import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/office_timer_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late OfficeTimerService _timerService;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _timerService = OfficeTimerService();
    // Listen to changes in the service (e.g. valid data loaded) to update UI
    _timerService.addListener(_onServiceUpdate);

    // Start a ticker to update the UI every second for the Duration count
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(
          () {},
        ); // Trigger rebuild to update duration text (and break text)
      }
    });
  }

  void _onServiceUpdate() {
    setState(() {});
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _timerService.removeListener(_onServiceUpdate);
    _timerService.dispose();
    super.dispose();
  }

  void _handleCheckIn() async {
    try {
      await _timerService.checkIn();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checked in successfully! 🚀')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  void _handleCheckOut() async {
    try {
      if (!_timerService.isCheckedIn) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please check in first!')));
        return;
      }
      await _timerService.checkOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checked out. See you later! 👋')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM').format(now);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF121212), const Color(0xFF1E1E1E)]
                : [const Color(0xFFF3F4F6), const Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Office Tracker',
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  dateStr,
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Main Status Card
                Expanded(child: _buildStatusCard()),

                const SizedBox(height: 40),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        label: 'Check In',
                        color: const Color(0xFF4CAF50), // Green
                        icon: Icons.login,
                        onTap: _handleCheckIn,
                        isDisabled: _timerService.isCheckedIn,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildActionButton(
                        label: 'Check Out',
                        color: const Color(0xFFE53935), // Red
                        icon: Icons.logout,
                        onTap: _handleCheckOut,
                        isDisabled: !_timerService.isCheckedIn,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final duration = _timerService.currentDuration;
    final isGoalMet = _timerService.isGoalMet;

    // Formatting duration
    String formatDuration(Duration d) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
      String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
      return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }

    String formatTime(DateTime? dt) {
      if (dt == null) return "--:--";
      return DateFormat('h:mm a').format(dt);
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Stack(
        children: [
          if (isGoalMet)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF4CAF50)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFF4CAF50), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      "GOAL COMPLETED",
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF4CAF50),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Timer Display
                Text(
                  "Total Duration",
                  style: GoogleFonts.outfit(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatDuration(duration),
                  style: GoogleFonts.outfit(
                    color: isGoalMet
                        ? const Color(0xFF4CAF50)
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),

                const SizedBox(height: 32),

                // Break Stats
                if (_timerService.breaks.isNotEmpty)
                  Expanded(child: _buildBreakList())
                else
                  Spacer(),

                // Grid stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        "Check In",
                        formatTime(_timerService.checkInTime),
                        Icons.login_rounded,
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.white10),
                    Expanded(
                      child: _buildStatItem(
                        "Check Out",
                        formatTime(_timerService.checkOutTime),
                        Icons.logout_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBreakList() {
    final breaks = _timerService.breaks.reversed.toList(); // Show newest first
    final totalBreak = _timerService.totalBreakDuration;

    String formatDuration(Duration d) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
      return "${twoDigits(d.inHours)}:$twoDigitMinutes"; // H:MM compact
    }

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Breaks",
                style: GoogleFonts.outfit(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Total: ${formatDuration(totalBreak)}",
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150, // Limit height
            child: ListView.separated(
              itemCount: breaks.length,
              separatorBuilder: (c, i) =>
                  Divider(color: Colors.white.withValues(alpha: 0.05)),
              itemBuilder: (context, index) {
                final b = breaks[index];
                final isCurrent = b.end == null;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        isCurrent ? Icons.coffee : Icons.check_circle_outline,
                        color: isCurrent
                            ? Colors.orange
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.3),
                        size: 16,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "${DateFormat('h:mm a').format(b.start)} - ${b.end != null ? DateFormat('h:mm a').format(b.end!) : 'Now'}",
                          style: GoogleFonts.outfit(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        formatDuration(b.duration),
                        style: GoogleFonts.outfit(
                          color: isCurrent
                              ? Colors.orange
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDisabled,
  }) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 64,
        decoration: BoxDecoration(
          color: isDisabled ? color.withValues(alpha: 0.1) : color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDisabled
              ? []
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isDisabled ? Colors.white38 : Colors.white),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isDisabled ? Colors.white38 : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
