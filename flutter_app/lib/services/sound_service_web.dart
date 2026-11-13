// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

void playWheelTickImpl() {
  try {
    js.context.callMethod('playWheelTick');
  } catch (_) {}
}

void playSlotSpinImpl() {
  try {
    js.context.callMethod('playSlotSpin');
  } catch (_) {}
}

void playSlotStopImpl() {
  try {
    js.context.callMethod('playSlotStop');
  } catch (_) {}
}

void playShakeRattleImpl() {
  try {
    js.context.callMethod('playShakeRattle');
  } catch (_) {}
}

void playScratchImpl() {
  try {
    js.context.callMethod('playScratch');
  } catch (_) {}
}

void playWinFanfareImpl() {
  try {
    js.context.callMethod('playWinFanfare');
  } catch (_) {}
}

void playClaimSuccessImpl() {
  try {
    js.context.callMethod('playClaimSuccess');
  } catch (_) {}
}
