COMMIT := $(shell git rev-parse --short=8 HEAD)
BASE_IMAGE := bmltenabled/bmlt-ci-base
BASE_IMAGE_TAG := 7.4
BASE_IMAGE_BUILD_TAG := $(COMMIT)-$(shell date +%s)
VENDOR_AUTOLOAD := vendor/autoload.php
ifeq ($(CI)x, x)
	DOCKERFILE := Dockerfile-debug
	IMAGE := rootserver
	TAG := local
	COMPOSER_ARGS :=
	COMPOSER_PREFIX := docker run --pull=always -t --rm -v $(shell pwd):/code -w /code $(BASE_IMAGE):$(BASE_IMAGE_TAG)
	LINT_PREFIX := docker run -t --rm -v $(shell pwd):/code -w /code $(IMAGE):$(TAG)
else
	COMPOSER_ARGS := --classmap-authoritative
	ifeq ($(DEV)x, x)
		COMPOSER_ARGS := $(COMPOSER_ARGS) --no-dev
	endif
	COMPOSER_PREFIX :=
	LINT_PREFIX :=
	TEST_PREFIX := cd src &&
endif

help:  ## Print the help documentation
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

$(VENDOR_AUTOLOAD):
	$(COMPOSER_PREFIX) composer install $(COMPOSER_ARGS)

.PHONY: composer
composer: $(VENDOR_AUTOLOAD) ## Runs composer install

.PHONY: lint
lint:  ## PHP Lint
	$(LINT_PREFIX) vendor/squizlabs/php_codesniffer/bin/phpcs

.PHONY: lint-fix
lint-fix:  ## PHP Lint Fix
	$(LINT_PREFIX) vendor/squizlabs/php_codesniffer/bin/phpcbf

.PHONY: docker-publish-base
docker-publish-base:  ## Builds Base Docker Image
	docker buildx build --platform linux/amd64,linux/arm64/v8 -f docker/Dockerfile-ci-base-7.4 docker/ -t $(BASE_IMAGE):7.4 --push
    docker buildx build --platform linux/amd64,linux/arm64/v8 -f docker/Dockerfile-ci-base-8.2 docker/ -t $(BASE_IMAGE):8.2 --push
