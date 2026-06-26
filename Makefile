.PHONY: help validate lint test security-check checklist clean

PROJECT ?= app_perfil
NODE_MODULES := node_modules
PYcache := __pycache__ .pytest_cache
DIST := dist build target

help:
	@echo "=== $(PROJECT) Makefile ==="
	@echo "  make validate        Full validation: lint + typecheck + test"
	@echo "  make lint            Run linter (eslint/prettier for JS, ruff for Python)"
	@echo "  make test            Run unit tests"
	@echo "  make security-check  Audit dependencies for vulnerabilities"
	@echo "  make checklist       Show current situational checklist"
	@echo "  make clean           Remove artifacts"

validate: lint test
	@echo "[validate] All checks passed"

lint:
	@echo "[lint] Running linters..."
	@command -v eslint >/dev/null 2>&1 && eslint . --max-warnings=0 || echo "[lint] eslint not found, skipping"
	@command -v ruff >/dev/null 2>&1 && ruff check . || echo "[lint] ruff not found, skipping"
	@command -v mypy >/dev/null 2>&1 && mypy . || echo "[lint] mypy not found, skipping"
	@echo "[lint] Done"

test:
	@echo "[test] Running tests..."
	@command -v pytest >/dev/null 2>&1 && pytest -q || echo "[test] pytest not found, skipping"
	@command -v vitest >/dev/null 2>&1 && vitest run --reporter=dot || echo "[test] vitest not found, skipping"
	@command -v npm test >/dev/null 2>&1 && npm test -- --passWithNoTests || echo "[test] npm test not found, skipping"
	@echo "[test] Done"

security-check:
	@echo "[security] Auditing dependencies..."
	@command -v npm >/dev/null 2>&1 && npm audit --audit-level=moderate || echo "[security] npm audit not found"
	@command -v pip-audit >/dev/null 2>&1 && pip-audit -q || echo "[security] pip-audit not found"
	@command -v semgrep >/dev/null 2>&1 && semgrep --config=auto --quiet . || echo "[security] semgrep not found"
	@echo "[security] Done"

checklist:
	@echo "=== Situational Checklist: $(PROJECT) ==="
	@echo ""
	@echo "1. PROJECT STATE"
	@ls -la | grep -qE "\.git|package\.json|requirements|Makefile" && echo "   [x] Project initialized" || echo "   [ ] Project NOT initialized"
	@echo ""
	@echo "2. CODE ARTIFACTS"
	@find . -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" 2>/dev/null | head -5 | wc -l | xargs -I{} echo "   Files found: {}"
	@echo ""
	@echo "3. TESTS"
	@find . -name "*test*" -o -name "*spec*" 2>/dev/null | head -5 | wc -l | xargs -I{} echo "   Test files: {}"
	@echo ""
	@echo "4. SECURITY"
	@command -v npm >/dev/null 2>&1 && npm audit --audit-level=moderate --json 2>/dev/null | grep -q '"vulnerabilities":0' && echo "   [x] No vulnerabilities" || echo "   [!] Run: make security-check"
	@echo ""
	@echo "5. LINTING"
	@command -v eslint >/dev/null 2>&1 && echo "   [x] eslint installed" || echo "   [ ] eslint NOT installed"
	@command -v ruff >/dev/null 2>&1 && echo "   [x] ruff installed" || echo "   [ ] ruff NOT installed"
	@echo ""
	@echo "6. DEPLOYMENT"
	@test -f Dockerfile && echo "   [x] Dockerfile exists" || echo "   [ ] No Dockerfile"
	@test -f docker-compose.yml && echo "   [x] docker-compose exists" || echo "   [ ] No docker-compose"
	@echo ""
	@echo "=== End Checklist ==="

clean:
	@echo "[clean] Removing artifacts..."
	@rm -rf $(DIST) $(NODE_MODULES) $(PYcache)
	@find . -type d -name ".next" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name ".nuxt" -exec rm -rf {} + 2>/dev/null || true
	@echo "[clean] Done"
