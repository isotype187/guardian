# Guardian git wrapper.
# The canonical git metadata lives at vcs\.git (the project-root .git is
# write-protected in this sandbox). This wrapper sets GIT_DIR so every
# git invocation works transparently from the project root.
param([Parameter(ValueFromRemainingArguments=$true)]$Args)
$GuardianRoot = "D:\Nexus98_Guardian"
$gitDir = Join-Path $GuardianRoot "vcs\.git"
$env:GIT_DIR = $gitDir
& git.exe @Args
