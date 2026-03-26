.PHONY: build validate check

build:
	@bash scripts/build.sh build

validate:
	@bash scripts/build.sh --validate

check:
	@bash scripts/build.sh --check
