import 'sound_service_stub.dart'
    if (dart.library.js) 'sound_service_web.dart';

class SoundService {
  static void playWheelTick() => playWheelTickImpl();
  static void playSlotSpin() => playSlotSpinImpl();
  static void playSlotStop() => playSlotStopImpl();
  static void playShakeRattle() => playShakeRattleImpl();
  static void playScratch() => playScratchImpl();
  static void playWinFanfare() => playWinFanfareImpl();
  static void playClaimSuccess() => playClaimSuccessImpl();
}
