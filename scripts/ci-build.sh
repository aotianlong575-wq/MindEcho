#!/bin/bash
# MindEcho CI Build Script
# 在本地 macOS 或 GitHub Actions 上运行

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   MindEcho CI Build${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查 Swift 版本
echo -e "\n${YELLOW}[1/4] Checking Swift version...${NC}"
swift --version

# 解析依赖
echo -e "\n${YELLOW}[2/4] Resolving dependencies...${NC}"
swift package resolve

# 编译
echo -e "\n${YELLOW}[3/4] Building MindEcho...${NC}"
if swift build --configuration debug 2>&1; then
    echo -e "${GREEN}✓ Build succeeded${NC}"
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi

# 测试
echo -e "\n${YELLOW}[4/4] Running tests...${NC}"
if swift test --configuration debug 2>&1; then
    echo -e "${GREEN}✓ All tests passed${NC}"
else
    echo -e "${RED}✗ Tests failed${NC}"
    exit 1
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}   CI Build Complete ✓${NC}"
echo -e "${GREEN}========================================${NC}"
