class OnboardingFlowState {
  const OnboardingFlowState({
    this.step = 1,
    this.usedInviteCode = false,
    this.errorMessage,
  });

  final int step;
  final bool usedInviteCode;
  final String? errorMessage;

  OnboardingFlowState goTo(int nextStep) {
    return OnboardingFlowState(step: nextStep, usedInviteCode: usedInviteCode);
  }

  OnboardingFlowState state3Invite(bool nextUsedInviteCode, int nextStep) {
    return OnboardingFlowState(
      step: nextStep,
      usedInviteCode: nextUsedInviteCode,
    );
  }

  OnboardingFlowState state8Address(String address, int nextStep) {
    if (address.trim().isEmpty) {
      return OnboardingFlowState(
        step: step,
        usedInviteCode: usedInviteCode,
        errorMessage: 'Please enter your building address.',
      );
    }

    return OnboardingFlowState(step: nextStep, usedInviteCode: usedInviteCode);
  }

  OnboardingFlowState clearError() {
    if (errorMessage == null) {
      return this;
    }

    return OnboardingFlowState(step: step, usedInviteCode: usedInviteCode);
  }

  OnboardingFlowState goBack() {
    return switch (step) {
      2 => goTo(1),
      3 => goTo(2),
      4 => goTo(usedInviteCode ? 3 : 7),
      5 => goTo(4),
      6 => goTo(5),
      7 => goTo(2),
      8 => goTo(1),
      9 => goTo(8),
      10 => goTo(9),
      11 => goTo(10),
      _ => goTo(1),
    };
  }
}
