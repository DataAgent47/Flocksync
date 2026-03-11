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

  OnboardingFlowState goTo(int nextStep) {
    return OnboardingFlowState(
      step: nextStep,
      usedInviteCode: usedInviteCode,
      isManagement: isManagement,
    );
  }

  OnboardingFlowState startResident() {
    return const OnboardingFlowState(step: 2, usedInviteCode: false);
  }

  OnboardingFlowState startManagement() {
    return const OnboardingFlowState(step: 8, isManagement: true);
  }

  OnboardingFlowState state3Invite(bool nextUsedInviteCode, int nextStep) {
    return OnboardingFlowState(
      step: nextStep,
      usedInviteCode: nextUsedInviteCode,
      isManagement: false,
    );
  }

  OnboardingFlowState state8Address(String address, int nextStep) {
    if (address.trim().isEmpty) {
      return OnboardingFlowState(
        step: step,
        usedInviteCode: usedInviteCode,
        isManagement: isManagement,
        errorMessage: 'Please enter your building address.',
      );
    }

    return OnboardingFlowState(
      step: nextStep,
      usedInviteCode: usedInviteCode,
      isManagement: isManagement,
    );
  }

  OnboardingFlowState clearError() {
    if (errorMessage == null) {
      return this;
    }

    return OnboardingFlowState(
      step: step,
      usedInviteCode: usedInviteCode,
      isManagement: isManagement,
    );
  }

  OnboardingFlowState goBack() {
    return switch (step) {
      2 => goTo(1),
      3 => goTo(2),
      4 => goTo(isManagement ? 8 : (usedInviteCode ? 3 : 7)),
      5 => goTo(4),
      6 => goTo(5),
      7 => goTo(2),
      8 => goTo(1),
      9 => goTo(8),
      10 => goTo(9),
      11 => goTo(10),
      12 => goTo(9),
      _ => goTo(1),
    };
  }
}
