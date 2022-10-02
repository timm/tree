MAKEFLAGS += --silent
SHELL=/bin/bash
R=$(shell git rev-parse --show-toplevel)

help: ## print help
	printf "\n#tree\nmake [OPTIONS]\n\nOPTIONS:\n"
	grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}\
	               {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

README.md: treelib.lua tree.lua ## update readme
	printf "\n# TREE\nTree learner via recursive random projections\n" > README.md
	lua $R/../readme.lua treelib.lua >> README.md

install: $R/../dotrc $R/../readme $R/../data

$R/../readme:; cd $R/..; git clone https://github.com/timm/readme
$R/../data  :; cd $R/..; git clone https://github.com/timm/data
$R/../dotrc :; cd $R/..; git clone https://github.com/timm/dotrc
	                       cd $R/../dotrc; make install

y?=saving
itso: ## commit to Git. To add a message, set `y=message`.
	git commit -am "$y"; git push; git status
