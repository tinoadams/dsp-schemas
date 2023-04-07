.PHONY: help
help:
	@cat $(MAKEFILE_LIST) | grep -E "^[^[:space:]]*: *.*## *" | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

validate: ## Validate all subject schemas against the schema registry
	scripts/foreach-subject.bash ./subjects scripts/register-subject.bash "http://localhost:8081" "validate"

package-%: ## Build the java package for each subject
	scripts/foreach-subject.bash ./subjects scripts/build-package.bash "$*"

publish: ## Publish java packages and register schemas with the schema registry
	scripts/foreach-subject.bash ./subjects scripts/register-subject.bash "http://localhost:8081" "register"

changed-subjects: ## List all subjects that have changed between the given release tag and the previous version
	scripts/changed-subjects.bash ./subjects/ "$$RELEASE_TAG" BY_VERSION