# MindEcho Makefile
# 在 macOS 上使用: make build / make test / make ci

.PHONY: build test clean lint ci open help

help: ## 显示帮助
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## 编译项目 (macOS Debug)
	swift build --configuration debug

release: ## 编译项目 (macOS Release)
	swift build --configuration release

test: ## 运行测试
	swift test --configuration debug

test-release: ## 运行测试 (Release)
	swift test --configuration release

lint: ## 代码检查
	swiftlint

clean: ## 清除构建缓存
	rm -rf .build/
	swift package reset

resolve: ## 解析依赖
	swift package resolve

ci: resolve lint build test ## CI 完整流程

open: ## 在 Xcode 中打开
	xed .

docs: ## 生成文档
	swift package generate-documentation \
		--target MindEchoCore \
		--output-path docs/api
