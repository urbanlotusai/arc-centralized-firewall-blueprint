# Contributing

Thanks for your interest in improving the **ARC Centralized Network Firewall Blueprint**.

## Ways to contribute

- **Report a bug or request a feature** — open a [GitHub Issue](../../issues).
- **Submit a change** — fork the repo and open a Pull Request.

## Pull request process

1. Fork and create a branch from `main`:
   ```bash
   git checkout -b feat/short-description
   ```
2. Format and validate before committing:
   ```bash
   terraform fmt -recursive
   terraform init -backend=false && terraform validate
   ```
3. Update `README.md` and `CHANGELOG.md` if inputs, outputs, or behavior changed.
4. Open a Pull Request describing what changed and why.

## Coding standards

- Pin module and provider versions explicitly.
- Explicitly set all parameters that control security or behavior.
- Document non-obvious cross-module references with a short comment.

## License

By contributing, you agree that your contributions are licensed under the [Apache License 2.0](LICENSE).

---

Maintained by **[SourceFuse](https://www.sourcefuse.com)** as part of the ARC blueprint family.
