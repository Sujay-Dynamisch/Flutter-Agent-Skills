/// Flutter-aware skills and project rules for AI coding agents.
library;

export 'src/installer.dart'
    show AgentTarget, Installer, skillNames, upsertBlock;
export 'src/hook.dart' show handlePreToolUse;
export 'src/profile.dart' show ProjectProfile;
export 'src/pub_check.dart'
    show
        PackageReport,
        PubChecker,
        PubFetcher,
        Verdict,
        packagesFromCommand,
        packagesFromPubspecText;

/// The version of this package.
const packageVersion = '0.2.0';
