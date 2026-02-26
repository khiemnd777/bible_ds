class RewardedAdService {
  bool _loaded = false;

  Future<void> loadRewardedAd() async {
    _loaded = true;
  }

  Future<bool> showRewardedAd({required void Function() onRewardEarned}) async {
    if (!_loaded) return false;
    onRewardEarned();
    _loaded = false;
    return true;
  }
}
