# Repository guidance

## Public repository policy

Treat this repository, all branches, pull requests, commit messages, and Git history as public. It is intended for public distribution; never rely on its current visibility to protect sensitive data.

- Never commit passwords, API keys, access tokens, private keys, authentication cookies, connection strings containing credentials, or real credential examples.
- Never commit local `.env` files, OMP/Copilot credentials or session data, secret-scan reports, or machine-generated build results. Ignore rules are a convenience, not a security boundary; tracked files remain tracked.
- Keep secrets outside the repository and inject them at runtime. Never put secret values in Nix expressions, derivation arguments, generated `/etc` files, shell commands, or `environment.sessionVariables`: Nix can copy them into publicly readable store paths.
- Provider API credentials must come from the user's runtime environment or an external secret manager, not this configuration.
- Hostnames, LAN addresses, usernames, Azure resource endpoints, and commit-author email addresses are not necessarily credentials, but they disclose personal infrastructure or identity. Obtain the owner's approval before introducing such details. Existing values are not permission to add more.
- Do not print secrets in tool output, logs, documentation, or reports. Keep scanner output redacted. Never test a discovered credential against a live service.
- Before committing or pushing, run both `gitleaks dir --redact=100 .` and `gitleaks git --redact=100 --log-opts=--all .`. Review new and changed files manually as well; a clean scanner result is not proof that no secret exists.
- If a credential is found, stop publication and notify the owner without reproducing its value. Removing it from the latest file does not remove it from history. The owner must revoke or rotate exposed credentials; do not rewrite or force-push history without explicit approval.

## Ownership and changes

- `jonyee` owns this repository. Public read access does not grant permission to push or merge; outside changes are proposals until the owner approves them.
- Do not change repository visibility, collaborator access, deploy keys, branch rules, GitHub Actions permissions, or other remote settings without explicit approval. Do not commit, push, merge, or publish releases unless requested.
- Preserve unrelated working-copy changes. This checkout uses Jujutsu with a Git backend; use the existing workflow rather than resetting, cleaning, or rewriting it.
- Never run `install.sh`, `nixos-rebuild switch`, or privileged setup against the current host merely to validate a change. Use an isolated environment, or request approval for an actual system change.

## Project structure and verification

- `flake.nix` exports `nixos-aarch64` and `nixos-x86_64`; preserve support for both architectures.
- `configuration.nix` imports the Copilot and OMP modules. Keep packages declarative and preserve pinned source hashes.
- `install.sh` is the fresh NixOS-WSL entry point. Keep the README command synchronized with it. Preserve the original `/etc/nixos` backup, the compatibility symlink, and refusal to overwrite an existing installation.
- Keep installer execution inside `main`, called at the end, so a partially downloaded function body does not perform setup. Treat paths derived from `HOME` as quoted data, never interpolated shell source.
- For shell changes, run `bash -n install.sh`, ShellCheck, and isolated installer scenarios. For Nix changes, evaluate both configurations and exercise the affected package or service without switching the host system.
- Keep changes narrowly scoped. Do not remove personal configuration, disable security checks, or change authentication behavior as an incidental cleanup.
