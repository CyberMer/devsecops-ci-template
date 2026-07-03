# devsecops-ci-template

A little security pipeline I put together to drop into my projects. It runs four
checks on every push so I don't ship obvious security problems by accident:

- **Semgrep** looks at the code for bad patterns
- **Gitleaks** makes sure I didn't commit a password or a key
- **Trivy** checks dependencies, Docker images and Terraform for known issues
- **OWASP ZAP** pokes at the running app to see what it exposes

It works on both GitHub Actions and GitLab CI, and you can run everything locally
with `make`.

## Try it

```bash
make          # see all the commands
make sast     # code scan
make secrets  # secret scan
make sca      # dependencies + infra
make dast     # scan the running sample app
make all      # everything
```

You only need Docker — each check runs from its official image, nothing to install.

## Using it in your own repo

Copy the pipeline file for your platform and the config folders:

- GitHub → `.github/workflows/security.yml`
- GitLab → `.gitlab-ci.yml`
- plus `semgrep/`, `.zap/` and `.gitleaks.toml`

There's a small sample app and some Terraform in `examples/` that the pipeline
scans — they're written to be clean, so a green run shows what "good" looks like.

## Tweaking it

- Custom Semgrep rules live in `semgrep/custom-rules.yml`
- Trivy severity threshold is at the top of the pipeline files (start with
  report-only, then turn on blocking once you've cleaned things up)
- ZAP pass/fail per alert is in `.zap/rules.tsv`
- Paths to ignore for secret scanning are in `.gitleaks.toml`

More notes on how it fits together in `docs/pipeline.md`.
