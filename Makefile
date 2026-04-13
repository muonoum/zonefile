.PHONY: build
build:
	queso build

.PHONY: commit
commit: commit_message ?= $(shell git diff --name-only --cached | rev | cut -d/ -f 1,2 | rev | xargs)
commit:
	test -n "$(commit_message)"
	git commit -m "$(commit_message)"

.PHONY: push
push: commit
	git push
