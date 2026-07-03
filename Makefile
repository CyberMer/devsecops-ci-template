# Run the same security gates locally that CI runs — no push required.
# Each target uses the official container image so there is nothing to install
# beyond Docker.

.PHONY: help sast secrets sca dast all app-build

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

sast: ## Semgrep static analysis
	docker run --rm -v "$(PWD):/src" semgrep/semgrep semgrep \
		--config p/default --config p/security-audit \
		--config /src/semgrep/custom-rules.yml /src

secrets: ## Gitleaks secret scan
	docker run --rm -v "$(PWD):/repo" zricethezav/gitleaks:latest \
		detect --source /repo --config /repo/.gitleaks.toml --redact -v

sca: ## Trivy dependency + IaC + secret scan
	docker run --rm -v "$(PWD):/repo" aquasec/trivy:latest \
		fs /repo --scanners vuln,misconfig,secret --severity CRITICAL,HIGH

app-build: ## Build the sample app image
	docker build -t sample-app ./examples/app

dast: app-build ## OWASP ZAP baseline against the running sample app
	docker run -d --rm -p 8080:8080 --name sample-app sample-app
	sleep 5
	-docker run --rm --network host -v "$(PWD)/.zap:/zap/wrk:rw" \
		ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
		-t http://localhost:8080 -c rules.tsv -a
	docker stop sample-app

all: sast secrets sca dast ## Run every gate
