# Plan Parser 测试指南

## 重构概述

`ModificationPlanSection.kt` 已重构，将以下逻辑抽取到独立文件：

1. **PlanParser.kt** - Plan 格式的 Markdown 解析器
2. **PlanPriority.kt** - 优先级调整和判断逻辑

## 文件结构

```
mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/compose/agent/codereview/
├── ModificationPlanSection.kt  # UI 组件（Compose）
├── PlanParser.kt               # 解析器（纯函数，可测试）
└── PlanPriority.kt             # 优先级工具（纯函数，可测试）
```

## 测试文件

```
mpp-ui/src/commonTest/kotlin/cc/unitmesh/devins/ui/compose/agent/codereview/
├── PlanParserTest.kt           # PlanParser 测试
└── PlanPriorityTest.kt         # PlanPriority 测试
```

## 如何运行测试

```bash
# 运行所有测试
./gradlew :mpp-ui:test

# 运行特定测试类
./gradlew :mpp-ui:test --tests "PlanParserTest"
./gradlew :mpp-ui:test --tests "PlanPriorityTest"
```

## 测试覆盖

### PlanParser 测试
- ✅ 解析带代码块的 Plan 格式
- ✅ 解析不带代码块的 Plan 格式
- ✅ 解析步骤状态标记（TODO, COMPLETED, FAILED, IN_PROGRESS）
- ✅ 提取文件链接
- ✅ 处理空计划
- ✅ 处理默认优先级
- ✅ 处理多行步骤续行

### PlanPriority 测试
- ✅ 识别代码风格问题
- ✅ 将代码风格问题从 CRITICAL/HIGH 降级为 MEDIUM
- ✅ 不改变非代码风格问题的优先级
- ✅ 识别高优先级
- ✅ 处理大小写不敏感匹配
- ✅ 处理混合语言标题

## 测试示例

### PlanParser 测试示例

```kotlin
@Test
fun `should parse simple plan with code block`() {
    val planOutput = """
        ```plan
        1. Null Safety Issues - CRITICAL
            - [ ] Fix [UserService.kt](src/main/kotlin/UserService.kt) line 45
        ```
    """.trimIndent()
    
    val items = PlanParser.parse(planOutput)
    
    assertEquals(1, items.size)
    assertEquals("Null Safety Issues", items[0].title)
    assertEquals("CRITICAL", items[0].priority)
}
```

### PlanPriority 测试示例

```kotlin
@Test
fun `should downgrade code style issues from CRITICAL to MEDIUM`() {
    val adjusted = PlanPriority.adjustPriority("代码风格问题", "CRITICAL")
    assertEquals("MEDIUM", adjusted)
}
```

## 优势

1. **可测试性** - 纯函数逻辑，无需 Compose 环境即可测试
2. **可维护性** - 职责分离，代码更清晰
3. **可复用性** - PlanParser 和 PlanPriority 可在其他地方复用
4. **易于扩展** - 新增优先级规则或解析功能更容易

