/// Counts consecutive frames that are missing one required item.
///
/// Fires once when the streak reaches [confirm], then stays quiet until the
/// item is seen again. There is no track id in the on-device model.
/// ponytail: one streak per item, not per person. Split by box if a site
/// has several people missing different gear in the same view.
class ViolationStreak {
  int _hardhat = 0;
  int _vest = 0;
  bool _hardhatOpen = false;
  bool _vestOpen = false;

  List<String> tick({
    required bool missingHardhat,
    required bool missingVest,
    required int confirm,
  }) {
    return [
      if (_one(missingHardhat, confirm, hardhat: true)) 'missing_hardhat',
      if (_one(missingVest, confirm, hardhat: false)) 'missing_vest',
    ];
  }

  bool _one(bool missing, int confirm, {required bool hardhat}) {
    if (!missing) {
      if (hardhat) {
        _hardhat = 0;
        _hardhatOpen = false;
      } else {
        _vest = 0;
        _vestOpen = false;
      }
      return false;
    }
    final open = hardhat ? _hardhatOpen : _vestOpen;
    if (open) return false;
    final next = (hardhat ? _hardhat : _vest) + 1;
    if (hardhat) {
      _hardhat = next;
    } else {
      _vest = next;
    }
    if (next < confirm) return false;
    if (hardhat) {
      _hardhatOpen = true;
    } else {
      _vestOpen = true;
    }
    return true;
  }
}
