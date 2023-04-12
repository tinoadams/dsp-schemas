.PHONY: help
help:
	@cat $(MAKEFILE_LIST) | grep -E "^[^[:space:]]*: *.*## *" | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

local-schema-config-%: ## For a given subject, build then register and deploy packages locally eg. make local-schema-config-test-topic
	scripts/exec-subject-mvn.bash "package schema-registry:set-compatibility@set-compatibility \
		schema-registry:test-compatibility@test-compatibility schema-registry:register@register \
		deploy" "local" "0.0-snapshot" "./subjects/$*"

local-topic-config-%: ## For a given topic, configure it locally eg. make local-topic-config-test-topic
	scripts/configure-topic.bash "./topics/$*"

ci-package: ## Uses env var RELEASE_TAG to package libraries for all subjects that have changed since the previous release eg. make ci-package RELEASE_TAG=non-prod/1.1
	scripts/foreach-changed-subject.bash ./subjects "$$RELEASE_TAG" BY_VERSION \
		scripts/exec-subject-mvn.bash "validate package"

ci-register: ## Uses env var RELEASE_TAG to register/update all subjects that have changed since the previous release with the registry eg. make ci-register RELEASE_TAG=non-prod/1.1
	scripts/foreach-changed-subject.bash ./subjects "$$RELEASE_TAG" BY_VERSION \
		scripts/exec-subject-mvn.bash "schema-registry:set-compatibility@set-compatibility schema-registry:test-compatibility@test-compatibility schema-registry:register@register"

ci-publish: ## Uses env var RELEASE_TAG to publish libraries for all subjects that have changed since the previous release to the artefact storage eg. make ci-publish RELEASE_TAG=non-prod/1.1
	scripts/foreach-changed-subject.bash ./subjects "$$RELEASE_TAG" BY_VERSION \
		scripts/exec-subject-mvn.bash "deploy"
