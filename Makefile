.PHONY: help
help:
	@cat $(MAKEFILE_LIST) | grep -E "^[^[:space:]]*: *.*## *" | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

validate: ## Validate all subject schemas against the schema registry
	./process-all-subjects.bash schema-registry/register-subject.bash "http://localhost:8081" "validate"

package-%: ## Build the java package for each subject
	./process-all-subjects.bash java/build-package.bash "$*"

register: ## Register all subject schemas with the schema registry
	./process-all-subjects.bash schema-registry/register-subject.bash "http://localhost:8081" "register"
