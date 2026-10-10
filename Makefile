.PHONY: all build_renderer generate app install install-debug dmg release delete-release

all: app

web-renderer/node_modules/.dependencies-installed: web-renderer/package.json web-renderer/package-lock.json
	cd web-renderer && npm ci --no-audit --no-fund --loglevel=warn
	touch $@

build_renderer: web-renderer/node_modules/.dependencies-installed
	cd web-renderer && npm run build

generate: build_renderer
	@if ! command -v xcodegen >/dev/null; then \
		echo "Error: xcodegen is not installed. Please install it with 'brew install xcodegen'"; \
		exit 1; \
	fi
	@if [ ! -f .version ]; then echo "1.0.0" > .version; fi
	@full_v=$$(cat .version); \
	major=$$(echo $$full_v | cut -d'.' -f1); \
	minor=$$(echo $$full_v | cut -d'.' -f2); \
	build=$$(echo $$full_v | cut -d'.' -f3); \
	echo "Generating Project with Version: $$full_v (Major: $$major, Minor: $$minor, Build: $$build)"; \
	MARKETING_VERSION=$$full_v CURRENT_PROJECT_VERSION=$$build xcodegen generate --quiet

app: check_toolchain generate
	@echo "🔨 Building application in $(or $(CONFIGURATION),Release) configuration..."
	@xcodebuild -project FluxMarkdown.xcodeproj -scheme Markdown -configuration $(or $(CONFIGURATION),Release) -destination 'platform=macOS,arch=arm64' $(if $(LOCAL_DEPLOYMENT_TARGET),MACOSX_DEPLOYMENT_TARGET=$(LOCAL_DEPLOYMENT_TARGET)) build -quiet 2> build_error.log || (cat build_error.log; rm -f build_error.log; exit 1)
	@rm -f build_error.log
	@echo "✅ Build completed: $(or $(CONFIGURATION),Release) configuration"

install:
	@echo "🚀 Building and installing Release configuration..."; \
	make app CONFIGURATION=Release && \
	./scripts/install.sh Release true development

install-debug:
	@echo "🚀 Building and installing Debug configuration..."; \
	make app CONFIGURATION=Debug && \
	./scripts/install.sh Debug true development

dmg:
	./scripts/create_dmg.sh

release:
	./scripts/release.sh $(filter-out $@,$(MAKECMDGOALS))

delete-release:
	./scripts/delete_release.sh $(filter-out $@,$(MAKECMDGOALS))

%:
	@:

.PHONY: check_toolchain clean
check_toolchain:
	@./scripts/check-build-toolchain.sh $(or $(LOCAL_DEPLOYMENT_TARGET),11.0)

clean:
	xcodebuild -project FluxMarkdown.xcodeproj -scheme Markdown clean
