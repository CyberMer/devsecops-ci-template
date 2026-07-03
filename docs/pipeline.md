# Pipeline design

## Philosophy: shift left, fail loud, tune deliberately

Every gate runs as early as it usefully can, and each maps to a distinct class
of risk. The goal is not "zero findings" — it is *no unreviewed HIGH/CRITICAL
reaches `main`*, with a clear, tunable path from report-only to blocking.

```
 commit / PR
     │
     ├─▶ SAST (Semgrep)        first-party code        → SARIF
     ├─▶ Secrets (Gitleaks)    full git history        → fail on leak
     ├─▶ SCA/IaC (Trivy)       deps · images · IaC     → SARIF
     │
     └─▶ DAST (OWASP ZAP)      running app (needs SAST+SCA green)
```

## Why these four

- **SAST — Semgrep.** Fast, language-aware, low false-positive registry packs.
  Custom rules encode team conventions the generic packs miss (privileged
  containers, plaintext internal `http://`, root Docker users).
- **Secrets — Gitleaks.** Scans the whole history with `fetch-depth: 0`, not
  just the diff — a secret committed once and "removed" is still in history and
  still compromised.
- **SCA / IaC — Trivy.** One tool, three scanners: dependency CVEs, container
  image CVEs, and Terraform/Kubernetes misconfiguration. Fewer moving parts than
  stitching separate tools together.
- **DAST — OWASP ZAP.** Static analysis can't see what the app actually serves.
  The baseline scan runs the real service and checks response headers, error
  disclosure, and common injection points. It runs *after* SAST/SCA so a broken
  build fails fast without spinning up a container.

## The severity gate

The template scans itself in **report-only** mode (`exit-code: 0`) so the
reference pipeline stays green while still surfacing findings. In a real project:

1. **Week 1** — report-only. Establish the baseline, triage what exists.
2. **Week 2+** — flip to block on `CRITICAL`.
3. **Steady state** — block on `CRITICAL,HIGH`; triage MEDIUM in review.

Onboarding a legacy repo at "block on everything" only teaches people to disable
the pipeline. Tighten deliberately.

## Extending

- **Sign & attest** — add image signing (cosign) and SBOM generation (Trivy
  `--format cyclonedx`) once you publish images.
- **Policy as code** — gate Terraform plans with OPA/Conftest before apply.
- **Dependency updates** — pair with Dependabot / Renovate so SCA findings have
  an automated remediation path.
