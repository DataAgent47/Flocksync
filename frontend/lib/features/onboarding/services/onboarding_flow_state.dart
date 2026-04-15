// Originally used in demo to track onboarding flow state, now used for data persistence b/w steps.
class OnboardingFlowState {
  const OnboardingFlowState({
    this.step = 1,
    this.usedInviteCode = false,
    this.isManagement = false,
    this.errorMessage,
  });

  final int step;
  final bool usedInviteCode;
  final bool isManagement;
  final String? errorMessage;

  OnboardingFlowState copyWith({
    int? step,
    bool? usedInviteCode,
    bool? isManagement,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OnboardingFlowState(
      step: step ?? this.step,
      usedInviteCode: usedInviteCode ?? this.usedInviteCode,
      isManagement: isManagement ?? this.isManagement,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  OnboardingFlowState goTo(int nextStep) {
    return copyWith(step: nextStep, clearError: true);
  }

  OnboardingFlowState startResident() {
    return copyWith(
      step: 2,
      usedInviteCode: false,
      isManagement: false,
      clearError: true,
    );
  }

  OnboardingFlowState startManagement() {
    return copyWith(
      step: 8,
      isManagement: true,
      usedInviteCode: false,
      clearError: true,
    );
  }

  OnboardingFlowState state3Invite(bool nextUsedInviteCode, int nextStep) {
    return copyWith(
      step: nextStep,
      usedInviteCode: nextUsedInviteCode,
      isManagement: false,
      clearError: true,
    );
  }

  OnboardingFlowState goBack() {
    final previousStep = switch (step) {
      2 => 1,
      3 => 2,
      4 => isManagement ? 8 : (usedInviteCode ? 3 : 7),
      5 => 4,
      6 => 5,
      7 => 2,
      8 => 1,
      9 => 8,
      10 => 9,
      11 => 10,
      12 => 9,
      _ => 1,
    };

    return goTo(previousStep);
  }
}
