import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';

/// A dark-themed horizontal temperature slider widget.
/// Range: 20 °C – 90 °C. Default: 25 °C.
/// Matches the reference design with a dark track and white thumb.
class TemperatureSlider extends StatefulWidget {
  const TemperatureSlider({
    super.key,
    required this.enabled,
    required this.onUpdateTemp,
  });

  /// When false the slider and button are greyed out.
  final bool enabled;

  /// Called when the user presses UPDATE TEMP with the selected value.
  final Future<void> Function(int temperature) onUpdateTemp;

  @override
  State<TemperatureSlider> createState() => _TemperatureSliderState();
}

class _TemperatureSliderState extends State<TemperatureSlider> {
  double _temperature = 25;
  bool _sending = false;
  bool _isSliding = false;

  @override
  void initState() {
    super.initState();
    BleService.instance.syncData.addListener(_onSyncDataUpdated);
  }

  @override
  void dispose() {
    BleService.instance.syncData.removeListener(_onSyncDataUpdated);
    super.dispose();
  }

  void _onSyncDataUpdated() {
    final sd = BleService.instance.syncData.value;
    if (sd != null && !_isSliding) {
      if (mounted && _temperature != (sd.temperature?.toDouble() ?? _temperature)) {
        setState(() => _temperature = sd.temperature?.toDouble() ?? _temperature);
      }
    }
  }

  Future<void> _handleUpdate() async {
    if (_sending || !widget.enabled) return;
    setState(() => _sending = true);
    await widget.onUpdateTemp(_temperature.round());
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = widget.enabled && !_sending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────
        Row(
          children: [
            Icon(Icons.thermostat,
                size: 22,
                color: enabled ? theme.colorScheme.primary : Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Temperature Control',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: enabled ? null : Colors.grey,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Temperature display ─────────────────────────────────
        Center(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: enabled ? theme.colorScheme.primary : Colors.grey,
              ),
              children: [
                TextSpan(text: '${_temperature.round()}'),
                TextSpan(
                  text: ' °C',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: enabled
                        ? theme.colorScheme.primary.withAlpha(180)
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── Min / Max labels ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('20 °C',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey)),
              Text('60 °C',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey)),
            ],
          ),
        ),

        // ── Dark slider (matches reference image) ───────────────
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.grey.shade900,
            inactiveTrackColor:
                enabled ? Colors.grey.shade800 : Colors.grey.shade400,
            thumbColor: Colors.white,
            overlayColor: Colors.white24,
            trackHeight: 12,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 14),
            overlayShape:
                const RoundSliderOverlayShape(overlayRadius: 22),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: _temperature.clamp(20, 60),
            min: 20,
            max: 60,
            divisions: 40,
            label: '${_temperature.round()} °C',
            onChangeStart: (v) => _isSliding = true,
            onChangeEnd: (v) => _isSliding = false,
            onChanged: enabled
                ? (v) => setState(() => _temperature = v)
                : null,
          ),
        ),

        const SizedBox(height: 16),

        // ── UPDATE TEMP button ──────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: enabled ? _handleUpdate : null,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: _sending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'UPDATE TEMP',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
