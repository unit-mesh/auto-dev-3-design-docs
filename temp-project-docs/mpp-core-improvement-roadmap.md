# MPP-Core 改进路线图

## 概览

基于对 Codex、Gemini CLI、Kode 三个生产级 Coding Agent 的深度分析，为 mpp-core 制定的完整改进路线图。

---

## 架构演进对比

### 当前架构 (v0.1)

```mermaid
graph TB
    subgraph "现有组件"
        UI[UI Layer] --> LLM[KoogLLMService]
        LLM --> COMPILER[DevInsCompiler]
        LLM --> HISTORY[ChatHistoryManager]
        MODEL[ModelRegistry] -.-> LLM
    end
    
    style UI fill:#90EE90
    style LLM fill:#90EE90
    style COMPILER fill:#90EE90
    style HISTORY fill:#90EE90
    style MODEL fill:#90EE90
```

### 目标架构 (v1.0)

```mermaid
graph TB
    subgraph "UI Layer"
        CLI[CLI]
        WEB[Web UI]
        IDE[IDE Plugin]
    end
    
    subgraph "Communication Layer"
        CHANNEL[AgentChannel<br/>异步通信]
        SUB[Submission Queue]
        EVT[Event Stream]
    end
    
    subgraph "Orchestration Layer"
        ORCH[AgentOrchestrator<br/>主控制器]
        SCHEDULER[ToolScheduler<br/>工具调度]
        POLICY[PolicyEngine<br/>权限控制]
    end
    
    subgraph "Execution Layer"
        PARALLEL[ParallelExecutor<br/>并发执行]
        REGISTRY[ToolRegistry<br/>工具注册]
        SUBAGENT[AgentExecutor<br/>子任务]
    end
    
    subgraph "Core Services"
        LLM[KoogLLMService]
        COMPILER[DevInsCompiler]
        HISTORY[ChatHistoryManager]
        LOOP[LoopDetection]
        COMPRESS[Compression]
    end
    
    CLI --> CHANNEL
    WEB --> CHANNEL
    IDE --> CHANNEL
    
    CHANNEL --> SUB
    CHANNEL --> EVT
    
    SUB --> ORCH
    ORCH --> SCHEDULER
    SCHEDULER --> POLICY
    
    POLICY --> PARALLEL
    PARALLEL --> REGISTRY
    SCHEDULER --> SUBAGENT
    
    ORCH --> LLM
    LLM --> COMPILER
    ORCH --> HISTORY
    HISTORY --> LOOP
    LOOP --> COMPRESS
    
    style CHANNEL fill:#FFE4B5
    style ORCH fill:#FFE4B5
    style SCHEDULER fill:#FFE4B5
    style POLICY fill:#FFE4B5
    style PARALLEL fill:#ADD8E6
    style SUBAGENT fill:#ADD8E6
    style LOOP fill:#DDA0DD
    style COMPRESS fill:#DDA0DD
```

---

## 核心改进点详解

### 1. 异步通信层 (Queue Pair Pattern)

**参考**: Codex Queue Pair + Kotlin Channels

```mermaid
sequenceDiagram
    participant UI
    participant Channel
    participant Orchestrator
    participant Tool
    
    UI->>Channel: submit(SendPrompt)
    Channel->>Orchestrator: receive submission
    Orchestrator->>Tool: execute read_file
    Tool-->>Orchestrator: file content
    Orchestrator->>Channel: emit(StreamUpdate)
    Channel-->>UI: receive event
    UI->>UI: render update
```

**关键特性**:
- 双向异步通信
- 背压控制
- 可取消任务
- 完全解耦 UI

---

### 2. 工具调度器 (State Machine)

**参考**: Gemini CLI CoreToolScheduler

```mermaid
stateDiagram-v2
    [*] --> Validating: 接收工具调用
    
    Validating --> Scheduled: 验证通过
    Validating --> Error: 验证失败
    
    Scheduled --> AwaitingApproval: 需要审批
    Scheduled --> Executing: 自动批准
    
    AwaitingApproval --> Executing: 用户批准
    AwaitingApproval --> Cancelled: 用户拒绝
    
    Executing --> Success: 执行成功
    Executing --> Error: 执行失败
    
    Success --> [*]
    Error --> [*]
    Cancelled --> [*]
```

**状态追踪**:
- 每个工具调用都有唯一 ID
- 完整的状态历史
- 可恢复和重试

---

### 3. 并发执行引擎

**参考**: Codex RwLock + Parallel Execution

```mermaid
flowchart LR
    subgraph "工具分类"
        CALLS[Tool Calls]
        READ[Read-Only Tools]
        WRITE[Write Tools]
    end
    
    subgraph "并发执行"
        PAR[Parallel<br/>5 read_file 同时执行]
        SEQ[Sequential<br/>write_file 串行执行]
    end
    
    subgraph "锁保护"
        RWLOCK[ReadWriteLock]
        STATE[(Shared State)]
    end
    
    CALLS --> READ
    CALLS --> WRITE
    
    READ --> PAR
    WRITE --> SEQ
    
    PAR -->|read lock| RWLOCK
    SEQ -->|write lock| RWLOCK
    RWLOCK --> STATE
```

**性能提升**:
- Read 操作: 5-10x 加速
- 无锁冲突
- 资源高效利用

---

### 4. 子任务机制 (Subagent)

**参考**: Gemini CLI AgentExecutor

```mermaid
flowchart TB
    subgraph "Main Agent"
        MAIN[主对话流程]
        DETECT[检测到需要子任务]
    end
    
    subgraph "Subagent Executor"
        CREATE[创建隔离环境]
        TOOLS[独立 ToolRegistry<br/>只读权限]
        LOOP[Agent Loop]
        COMPLETE[complete_task 工具]
    end
    
    subgraph "结果"
        RESULT[结构化输出]
        VALIDATE[Schema 验证]
    end
    
    MAIN --> DETECT
    DETECT -->|创建| CREATE
    CREATE --> TOOLS
    TOOLS --> LOOP
    LOOP --> COMPLETE
    COMPLETE --> RESULT
    RESULT --> VALIDATE
    VALIDATE -->|返回| MAIN
```

**典型场景**:
```kotlin
// 代码审查子 Agent
val reviewer = AgentDefinition(
    name = "code-reviewer",
    allowedTools = listOf("read_file", "grep"),  // 只读
    outputSchema = CodeReviewResult::class
)

val result = executor.run(reviewer, mapOf("file" to "Auth.kt"))
// 返回: CodeReviewResult(issues=..., score=...)
```

---

### 5. 智能历史管理

**参考**: Gemini CLI Loop Detection + Compression

```mermaid
flowchart TD
    subgraph "工具调用追踪"
        CALL[Tool Call]
        RECORD[记录到历史]
        CHECK[检测循环模式]
    end
    
    subgraph "循环检测"
        PATTERN[模式匹配]
        THRESHOLD[重复 >= 3 次?]
        BREAK[打破循环]
    end
    
    subgraph "历史压缩"
        SIZE[历史 > 50 轮?]
        COMPRESS[LLM 总结]
        KEEP[保留最新 10 轮]
    end
    
    CALL --> RECORD
    RECORD --> CHECK
    CHECK --> PATTERN
    PATTERN --> THRESHOLD
    THRESHOLD -->|是| BREAK
    
    RECORD --> SIZE
    SIZE -->|是| COMPRESS
    COMPRESS --> KEEP
```

**效果**:
- 避免死循环
- Token 成本降低 60-80%
- 保持对话连贯性

---

## 实施时间线

### Phase 0: 基础设施 (2 周)

```mermaid
gantt
    title Phase 0 - 基础设施
    dateFormat YYYY-MM-DD
    
    section 核心组件
    Tool 接口定义           :crit, t1, 2025-11-01, 2d
    ToolRegistry           :crit, t2, after t1, 2d
    AgentChannel 通信层    :crit, t3, after t2, 3d
    
    section 测试
    单元测试框架            :t4, after t1, 2d
    集成测试环境            :t5, after t4, 2d
```

**Deliverables**:
- ✅ `Tool` 接口
- ✅ `ToolRegistry` 注册表
- ✅ `AgentChannel` 通信层
- ✅ 基础测试框架

---

### Phase 1: 工具调度 (2 周)

```mermaid
gantt
    title Phase 1 - 工具调度
    dateFormat YYYY-MM-DD
    
    section 调度器
    ToolCallState 定义      :crit, s1, 2025-11-15, 2d
    ToolScheduler 实现      :crit, s2, after s1, 4d
    状态机测试              :s3, after s2, 2d
    
    section 权限控制
    PolicyEngine           :crit, p1, 2025-11-15, 3d
    PolicyRule 配置        :p2, after p1, 2d
    审批流程测试            :p3, after p2, 2d
```

**Deliverables**:
- ✅ `ToolScheduler` 状态机
- ✅ `PolicyEngine` 权限控制
- ✅ 审批缓存机制
- ✅ 完整状态追踪

---

### Phase 2: 性能优化 (2 周)

```mermaid
gantt
    title Phase 2 - 性能优化
    dateFormat YYYY-MM-DD
    
    section 并发执行
    ReadWriteLock 集成      :crit, c1, 2025-12-01, 2d
    工具分类逻辑            :c2, after c1, 2d
    ParallelExecutor       :crit, c3, after c2, 3d
    
    section 输出管理
    流式输出 Handler       :o1, 2025-12-01, 2d
    大输出截断              :o2, after o1, 2d
    自动文件保存            :o3, after o2, 1d
```

**Deliverables**:
- ⭐ 5-10x 并发读性能
- ⭐ 大输出自动管理
- ⭐ 实时流式更新
- ⭐ 可取消任务

---

### Phase 3: 高级功能 (3 周)

```mermaid
gantt
    title Phase 3 - 高级功能
    dateFormat YYYY-MM-DD
    
    section Subagent
    AgentDefinition        :crit, a1, 2025-12-15, 2d
    AgentExecutor          :crit, a2, after a1, 5d
    Schema 验证             :a3, after a2, 2d
    
    section MCP 集成
    MCP Client             :m1, 2025-12-15, 4d
    工具发现                :m2, after m1, 3d
    MCP 工具包装           :m3, after m2, 2d
```

**Deliverables**:
- 🔧 `AgentExecutor` 子任务
- 🔧 工具权限隔离
- 🔧 结构化输出验证
- 🔧 MCP 协议支持

---

### Phase 4: 智能优化 (2 周)

```mermaid
gantt
    title Phase 4 - 智能优化
    dateFormat YYYY-MM-DD
    
    section 循环检测
    LoopDetectionService   :l1, 2026-01-05, 3d
    模式识别算法            :l2, after l1, 2d
    
    section 历史压缩
    ChatCompressionService :c1, 2026-01-05, 4d
    LLM 总结集成           :c2, after c1, 2d
    
    section 持久化
    会话存储                :p1, after c2, 2d
    恢复机制                :p2, after p1, 2d
```

**Deliverables**:
- 💡 循环自动检测
- 💡 历史智能压缩
- 💡 会话持久化
- 💡 IDE 上下文同步

---

## 性能指标对比

### 当前性能 (Baseline)

| 指标 | 当前值 | 来源 |
|------|--------|------|
| Read 工具并发 | 串行 (1x) | 实测 |
| 工具调用延迟 | ~150ms | 估算 |
| 历史 token 控制 | 无限制 | - |
| 循环检测 | 无 | - |
| 权限检查 | 无 | - |

### 目标性能 (v1.0)

| 指标 | 目标值 | 对比基线 | 参考来源 |
|------|--------|----------|----------|
| Read 工具并发 | 并行 (5-10x) | **10x 提升** | Codex |
| 工具调用延迟 | <50ms | **3x 提升** | Gemini CLI |
| 历史 token 控制 | <8k tokens | **控制成本** | Gemini CLI |
| 循环检测 | <5 次重复 | **防死循环** | Gemini CLI |
| 权限检查开销 | <5ms/call | **安全保障** | Gemini CLI |

---

## 兼容性策略

### 保持向后兼容

```kotlin
// 旧 API (v0.1)
class KoogLLMService {
    fun streamPrompt(userPrompt: String): Flow<String>
}

// 新 API (v1.0)
class KoogLLMService {
    @Deprecated("Use submitPrompt instead", ReplaceWith("submitPrompt(userPrompt)"))
    fun streamPrompt(userPrompt: String): Flow<String>
    
    // 新方法
    suspend fun submitPrompt(userPrompt: String): String {
        channel.submit(AgentSubmission.SendPrompt(userPrompt))
        // ...
    }
}
```

### 渐进式迁移

1. **Phase 0-1**: 新旧 API 共存
2. **Phase 2**: 标记旧 API 为 `@Deprecated`
3. **Phase 3**: 文档更新和迁移指南
4. **Phase 4**: 移除旧 API (major version bump)

---

## 风险评估

### 高风险项

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|------|----------|
| KMP 兼容性问题 | 高 | 中 | 充分测试所有平台 |
| 性能回退 | 中 | 低 | 持续性能基准测试 |
| Breaking changes | 高 | 低 | 保持向后兼容 |

### 中风险项

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|------|----------|
| 并发 Bug | 中 | 中 | 充分的并发测试 |
| 状态机复杂度 | 中 | 中 | 清晰的文档和图示 |
| 测试覆盖不足 | 中 | 中 | 80%+ 代码覆盖率 |

---

## 成功标准

### 功能完整性

- [x] 异步通信层实现
- [ ] 工具调度器状态机
- [ ] 权限控制系统
- [ ] 并发执行引擎
- [ ] 子任务机制
- [ ] 循环检测
- [ ] 历史压缩

### 性能达标

- [ ] Read 工具 5x+ 并发提升
- [ ] 工具调用延迟 <50ms
- [ ] 历史 token <8k
- [ ] 循环检测准确率 >95%

### 质量保障

- [ ] 单元测试覆盖率 >80%
- [ ] 集成测试通过率 100%
- [ ] 所有平台 (JVM/JS/Wasm) 通过
- [ ] 性能基准测试通过

---

## 参考资源

### 核心文档

1. [Codex 架构分析](./codex-architecture-analysis.md) - Queue Pair + 并发执行
2. [Gemini CLI 架构分析](./gemini-cli-architecture.md) - 状态机 + Subagent
3. [Kode 架构分析](./kode-architecture-analysis.md) - 多模型协作
4. [架构对比分析](./coding-agents-architecture.md) - 综合对比

### 技术栈

- **Kotlin Multiplatform**: https://kotlinlang.org/docs/multiplatform.html
- **Kotlin Coroutines**: https://kotlinlang.org/docs/coroutines-overview.html
- **Kotlin Flow**: https://kotlinlang.org/docs/flow.html
- **MCP Protocol**: https://modelcontextprotocol.io/

---

**文档版本**: v1.0  
**创建日期**: 2025-10-31  
**作者**: AutoDev Team
