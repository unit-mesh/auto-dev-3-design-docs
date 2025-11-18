# 多端协同架构设计 (Multi-Client Collaboration)

## 📊 现状分析

### 已有能力

#### 1. **事件驱动架构** ✅
- **AgentEvent**: 完整的事件模型（IterationStart, LLMResponseChunk, ToolCall, ToolResult, Error, Complete）
- **ServerSideRenderer**: 基于 `Channel<AgentEvent>` 的事件发射器
- **SSE 流式传输**: 通过 Ktor SSE 实时推送事件到客户端
- **跨平台客户端**: RemoteAgentClient (Kotlin), ServerAgentClient (TypeScript)

#### 2. **数据持久化** ✅
- **SQLDelight**: 跨平台数据库支持（JVM/Android/iOS/JS/WASM）
- **ModelConfigRepository**: 已有配置管理实现
- **expect/actual 模式**: 平台特定实现

#### 3. **服务端架构** ✅
- **Ktor Server**: HTTP + SSE 端点
- **AgentService**: CodingAgent 执行服务
- **GitCloneService**: Git 仓库管理
- **ProjectService**: 项目列表管理

#### 4. **客户端架构** ✅
- **ViewModel 模式**: CodingAgentViewModel, RemoteCodingAgentViewModel
- **Compose UI**: 跨平台 UI 渲染
- **Terminal UI**: Node.js CLI (Ink/React)

---

## 🎯 多端协同需求

### 1️⃣ 会话管理（Session Management）

**目标**: 多个端可以连接到同一个 Agent 执行会话，查看实时进度。

**场景**:
```
场景 A: 在 Desktop 上启动任务，在 Android/iOS 查看进度
场景 B: 在 CLI 上启动任务，在 Web 上查看结果
场景 C: 断线重连后恢复会话状态
```

**核心功能**:
- ✅ 创建会话（Session）
- ✅ 加入会话（Join Session）
- ✅ 会话状态同步
- ✅ 会话历史查询
- ✅ 会话权限管理（Owner / Viewer）

### 2️⃣ 同步输出（Synchronized Output / Real-time Data Sync）

**目标**: 多个端同时订阅同一个 Agent 会话，实时接收相同的事件流。

**场景**:
```
Desktop 端启动任务 → Android 端实时查看 LLM 响应 → iOS 端查看 Tool 执行结果
```

**核心功能**:
- ✅ 事件广播（Event Broadcasting）
- ✅ 多订阅者支持（Multiple Subscribers）
- ✅ 事件持久化（Event Persistence）
- ✅ 历史事件回放（Event Replay）

### 3️⃣ 状态与操作一致性（State & Operation Consistency）

**目标**: 确保多端操作和状态一致，支持协作编辑和冲突解决。

**场景**:
```
Desktop 端编辑文件 → Android 端看到实时更新 → iOS 端获取最新文件状态
```

**核心功能**:
- ✅ 状态快照（State Snapshot）
- ✅ 操作队列（Operation Queue）
- ✅ 冲突检测与解决（Conflict Resolution）
- ✅ 最终一致性保证（Eventual Consistency）

---

## 🏗️ 技术架构设计

### 整体架构图

```
┌──────────────────────────────────────────────────────────────────────┐
│                         Client Tier (mpp-ui)                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │
│  │  Desktop    │  │  Android    │  │  iOS        │  │  Web/CLI    │ │
│  │  (Compose)  │  │  (Compose)  │  │  (SwiftUI)  │  │  (React)    │ │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘ │
│         │                │                │                │         │
│         └────────────────┴────────────────┴────────────────┘         │
│                              │ HTTP/SSE                               │
└──────────────────────────────┼────────────────────────────────────────┘
                               │
┌──────────────────────────────┼────────────────────────────────────────┐
│                              ▼                                        │
│                   mpp-server (Ktor Server)                            │
│  ┌────────────────────────────────────────────────────────────┐      │
│  │                  Session Manager                           │      │
│  │  - 管理活跃会话 (Active Sessions)                           │      │
│  │  - 多订阅者支持 (Multiple Subscribers per Session)         │      │
│  │  - 事件广播 (Event Broadcasting)                            │      │
│  └───────────┬────────────────────────────────────────────────┘      │
│              │                                                        │
│  ┌───────────┴────────────┬──────────────┬────────────────────┐     │
│  │                        │              │                    │     │
│  ▼                        ▼              ▼                    ▼     │
│ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐│
│ │ Session     │  │ Agent       │  │ Event       │  │ State        ││
│ │ Repository  │  │ Service     │  │ Store       │  │ Sync Service ││
│ │ (SQLDelight)│  │             │  │ (Memory +   │  │              ││
│ │             │  │             │  │  Persistent)│  │              ││
│ └─────────────┘  └─────────────┘  └─────────────┘  └──────────────┘│
└───────────────────────────────────────────────────────────────────────┘
```

---

## 📦 数据模型设计

### 1. Session（会话）

会话是多端协同的核心概念，每个 Agent 任务执行都对应一个 Session。

```kotlin
// mpp-core/src/commonMain/kotlin/cc/unitmesh/session/Session.kt

@Serializable
data class Session(
    val id: String,                      // UUID
    val projectId: String,               // 项目 ID
    val task: String,                    // 任务描述
    val status: SessionStatus,           // 会话状态
    val ownerId: String,                 // 会话所有者
    val createdAt: Long,                 // 创建时间
    val updatedAt: Long,                 // 更新时间
    val metadata: SessionMetadata? = null
)

@Serializable
enum class SessionStatus {
    PENDING,      // 等待执行
    RUNNING,      // 执行中
    PAUSED,       // 暂停
    COMPLETED,    // 完成
    FAILED,       // 失败
    CANCELLED     // 取消
}

@Serializable
data class SessionMetadata(
    val gitUrl: String? = null,
    val branch: String? = null,
    val maxIterations: Int = 100,
    val currentIteration: Int = 0,
    val llmConfig: String? = null        // JSON serialized LLMConfig
)

@Serializable
data class SessionParticipant(
    val sessionId: String,
    val userId: String,
    val role: ParticipantRole,
    val joinedAt: Long
)

@Serializable
enum class ParticipantRole {
    OWNER,     // 拥有者（可控制执行）
    VIEWER     // 观察者（只读）
}
```

### 2. SessionEvent（会话事件）

扩展现有的 `AgentEvent`，增加会话关联信息。

```kotlin
// mpp-core/src/commonMain/kotlin/cc/unitmesh/session/SessionEvent.kt

@Serializable
data class SessionEventEnvelope(
    val sessionId: String,               // 会话 ID
    val eventId: String,                 // 事件 ID (UUID)
    val timestamp: Long,                 // 时间戳
    val sequenceNumber: Long,            // 序列号（确保顺序）
    val event: AgentEvent                // 原有的 AgentEvent
)
```

### 3. SessionState（会话状态快照）

用于断线重连和状态同步。

```kotlin
// mpp-core/src/commonMain/kotlin/cc/unitmesh/session/SessionState.kt

@Serializable
data class SessionState(
    val sessionId: String,
    val status: SessionStatus,
    val currentIteration: Int,
    val maxIterations: Int,
    val events: List<SessionEventEnvelope>,  // 历史事件
    val steps: List<AgentStepInfo>,
    val edits: List<AgentEditInfo>,
    val lastEventSequence: Long              // 最后事件序列号
)
```

---

## 🗄️ 数据持久化

### SQLDelight Schema

在 `mpp-ui` 或 `mpp-server` 中添加新的 SQLDelight 表：

```sql
-- mpp-ui/src/commonMain/sqldelight/cc/unitmesh/devins/db/Session.sq

CREATE TABLE IF NOT EXISTS Session (
    id TEXT PRIMARY KEY NOT NULL,
    projectId TEXT NOT NULL,
    task TEXT NOT NULL,
    status TEXT NOT NULL,
    ownerId TEXT NOT NULL,
    createdAt INTEGER NOT NULL,
    updatedAt INTEGER NOT NULL,
    metadata TEXT
);

CREATE INDEX idx_session_owner ON Session(ownerId);
CREATE INDEX idx_session_project ON Session(projectId);
CREATE INDEX idx_session_status ON Session(status);

-- 查询所有会话
selectAll:
SELECT * FROM Session ORDER BY updatedAt DESC;

-- 查询指定项目的会话
selectByProject:
SELECT * FROM Session WHERE projectId = ? ORDER BY updatedAt DESC;

-- 查询指定所有者的会话
selectByOwner:
SELECT * FROM Session WHERE ownerId = ? ORDER BY updatedAt DESC;

-- 查询活跃会话（RUNNING 或 PAUSED）
selectActive:
SELECT * FROM Session WHERE status IN ('RUNNING', 'PAUSED') ORDER BY updatedAt DESC;

-- 根据 ID 查询
selectById:
SELECT * FROM Session WHERE id = ?;

-- 插入会话
insert:
INSERT INTO Session(id, projectId, task, status, ownerId, createdAt, updatedAt, metadata)
VALUES (?, ?, ?, ?, ?, ?, ?, ?);

-- 更新会话状态
updateStatus:
UPDATE Session SET status = ?, updatedAt = ? WHERE id = ?;

-- 更新会话元数据
updateMetadata:
UPDATE Session SET metadata = ?, updatedAt = ? WHERE id = ?;

-- 删除会话
delete:
DELETE FROM Session WHERE id = ?;

-- Session Event 表（用于事件持久化）
CREATE TABLE IF NOT EXISTS SessionEvent (
    id TEXT PRIMARY KEY NOT NULL,
    sessionId TEXT NOT NULL,
    eventId TEXT NOT NULL,
    timestamp INTEGER NOT NULL,
    sequenceNumber INTEGER NOT NULL,
    eventType TEXT NOT NULL,
    eventData TEXT NOT NULL,
    FOREIGN KEY (sessionId) REFERENCES Session(id) ON DELETE CASCADE
);

CREATE INDEX idx_session_event_session ON SessionEvent(sessionId);
CREATE INDEX idx_session_event_sequence ON SessionEvent(sessionId, sequenceNumber);

-- 查询会话的所有事件
selectEventsBySession:
SELECT * FROM SessionEvent WHERE sessionId = ? ORDER BY sequenceNumber ASC;

-- 查询会话的最新事件
selectLatestEventBySession:
SELECT * FROM SessionEvent WHERE sessionId = ? ORDER BY sequenceNumber DESC LIMIT 1;

-- 插入事件
insertEvent:
INSERT INTO SessionEvent(id, sessionId, eventId, timestamp, sequenceNumber, eventType, eventData)
VALUES (?, ?, ?, ?, ?, ?, ?);

-- Session Participant 表
CREATE TABLE IF NOT EXISTS SessionParticipant (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sessionId TEXT NOT NULL,
    userId TEXT NOT NULL,
    role TEXT NOT NULL,
    joinedAt INTEGER NOT NULL,
    FOREIGN KEY (sessionId) REFERENCES Session(id) ON DELETE CASCADE,
    UNIQUE(sessionId, userId)
);

CREATE INDEX idx_participant_session ON SessionParticipant(sessionId);

-- 查询会话参与者
selectParticipantsBySession:
SELECT * FROM SessionParticipant WHERE sessionId = ?;

-- 添加参与者
insertParticipant:
INSERT INTO SessionParticipant(sessionId, userId, role, joinedAt)
VALUES (?, ?, ?, ?);

-- 删除参与者
deleteParticipant:
DELETE FROM SessionParticipant WHERE sessionId = ? AND userId = ?;
```

### Repository 实现

```kotlin
// mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/db/SessionRepository.kt

expect class SessionRepository {
    fun getAllSessions(): List<Session>
    fun getSessionById(id: String): Session?
    fun getActiveSessionsByProject(projectId: String): List<Session>
    fun getSessionsByOwner(ownerId: String): List<Session>
    fun createSession(session: Session): String
    fun updateSessionStatus(id: String, status: SessionStatus)
    fun updateSessionMetadata(id: String, metadata: SessionMetadata)
    fun deleteSession(id: String)
    
    // Event 相关
    fun getSessionEvents(sessionId: String): List<SessionEventEnvelope>
    fun getLatestEvent(sessionId: String): SessionEventEnvelope?
    fun appendEvent(event: SessionEventEnvelope)
    
    // Participant 相关
    fun getParticipants(sessionId: String): List<SessionParticipant>
    fun addParticipant(participant: SessionParticipant)
    fun removeParticipant(sessionId: String, userId: String)
    
    companion object {
        fun getInstance(): SessionRepository
    }
}
```

---

## 🔧 服务端实现

### 1. SessionManager（会话管理器）

核心组件，管理所有活跃会话和订阅者。

```kotlin
// mpp-server/src/main/kotlin/cc/unitmesh/server/session/SessionManager.kt

class SessionManager(
    private val sessionRepository: SessionRepository
) {
    // 活跃会话：sessionId -> Session
    private val activeSessions = ConcurrentHashMap<String, Session>()
    
    // 会话订阅者：sessionId -> List<EventChannel>
    private val sessionSubscribers = ConcurrentHashMap<String, MutableList<Channel<SessionEventEnvelope>>>()
    
    // 事件序列号：sessionId -> AtomicLong
    private val eventSequences = ConcurrentHashMap<String, AtomicLong>()
    
    /**
     * 创建新会话
     */
    fun createSession(request: CreateSessionRequest): Session {
        val session = Session(
            id = UUID.randomUUID().toString(),
            projectId = request.projectId,
            task = request.task,
            status = SessionStatus.PENDING,
            ownerId = request.userId,
            createdAt = System.currentTimeMillis(),
            updatedAt = System.currentTimeMillis(),
            metadata = request.metadata
        )
        
        sessionRepository.createSession(session)
        activeSessions[session.id] = session
        eventSequences[session.id] = AtomicLong(0)
        
        return session
    }
    
    /**
     * 订阅会话（用于 SSE）
     */
    suspend fun subscribeToSession(sessionId: String, userId: String): Flow<SessionEventEnvelope> = flow {
        val session = getSession(sessionId) ?: throw SessionNotFoundException(sessionId)
        
        // 创建订阅通道
        val channel = Channel<SessionEventEnvelope>(Channel.BUFFERED)
        
        // 注册订阅者
        sessionSubscribers.computeIfAbsent(sessionId) { mutableListOf() }.add(channel)
        
        try {
            // 先发送历史事件（从数据库加载）
            val historicalEvents = sessionRepository.getSessionEvents(sessionId)
            historicalEvents.forEach { event ->
                emit(event)
            }
            
            // 然后监听实时事件
            for (event in channel) {
                emit(event)
            }
        } finally {
            // 取消订阅时移除通道
            sessionSubscribers[sessionId]?.remove(channel)
            channel.close()
        }
    }
    
    /**
     * 广播事件到所有订阅者
     */
    suspend fun broadcastEvent(sessionId: String, event: AgentEvent) {
        val sequence = eventSequences[sessionId]?.incrementAndGet() ?: return
        
        val envelope = SessionEventEnvelope(
            sessionId = sessionId,
            eventId = UUID.randomUUID().toString(),
            timestamp = System.currentTimeMillis(),
            sequenceNumber = sequence,
            event = event
        )
        
        // 持久化事件
        sessionRepository.appendEvent(envelope)
        
        // 广播到所有订阅者
        sessionSubscribers[sessionId]?.forEach { channel ->
            channel.trySend(envelope)
        }
        
        // 更新会话状态
        if (event is AgentEvent.Complete) {
            updateSessionStatus(sessionId, if (event.success) SessionStatus.COMPLETED else SessionStatus.FAILED)
        }
    }
    
    /**
     * 获取会话状态快照
     */
    fun getSessionState(sessionId: String): SessionState? {
        val session = getSession(sessionId) ?: return null
        val events = sessionRepository.getSessionEvents(sessionId)
        
        // 从事件中重建 steps 和 edits
        val steps = mutableListOf<AgentStepInfo>()
        val edits = mutableListOf<AgentEditInfo>()
        
        events.forEach { envelope ->
            when (val event = envelope.event) {
                is AgentEvent.Complete -> {
                    steps.addAll(event.steps)
                    edits.addAll(event.edits)
                }
                else -> {}
            }
        }
        
        return SessionState(
            sessionId = sessionId,
            status = session.status,
            currentIteration = session.metadata?.currentIteration ?: 0,
            maxIterations = session.metadata?.maxIterations ?: 100,
            events = events,
            steps = steps,
            edits = edits,
            lastEventSequence = eventSequences[sessionId]?.get() ?: 0
        )
    }
    
    /**
     * 更新会话状态
     */
    private fun updateSessionStatus(sessionId: String, status: SessionStatus) {
        sessionRepository.updateSessionStatus(sessionId, status)
        activeSessions[sessionId] = activeSessions[sessionId]?.copy(
            status = status,
            updatedAt = System.currentTimeMillis()
        ) ?: return
    }
    
    fun getSession(sessionId: String): Session? {
        return activeSessions[sessionId] ?: sessionRepository.getSessionById(sessionId)
    }
    
    fun getAllActiveSessions(): List<Session> {
        return activeSessions.values.toList()
    }
}

data class CreateSessionRequest(
    val projectId: String,
    val task: String,
    val userId: String,
    val metadata: SessionMetadata? = null
)

class SessionNotFoundException(sessionId: String) : 
    Exception("Session not found: $sessionId")
```

### 2. 集成到 AgentService

修改 `AgentService` 以支持会话管理：

```kotlin
// mpp-server/src/main/kotlin/cc/unitmesh/server/service/AgentService.kt (修改)

class AgentService(
    private val sessionManager: SessionManager,
    private val gitCloneService: GitCloneService
) {
    /**
     * 通过会话执行 Agent（新方法）
     */
    suspend fun executeAgentWithSession(
        sessionId: String,
        projectPath: String,
        request: AgentRequest
    ): Flow<SessionEventEnvelope> {
        // 创建 ServerSideRenderer 的包装器
        val renderer = SessionAwareRenderer(sessionId, sessionManager)
        
        val llmService = createLLMService(request.llmConfig)
        val agent = createCodingAgent(projectPath, llmService, renderer)
        
        // 更新会话状态为 RUNNING
        sessionManager.updateSessionStatus(sessionId, SessionStatus.RUNNING)
        
        // 在后台执行 Agent
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val task = AgentTask(
                    requirement = request.task,
                    projectPath = projectPath
                )
                agent.executeTask(task)
            } catch (e: Exception) {
                sessionManager.broadcastEvent(
                    sessionId,
                    AgentEvent.Error("Agent execution failed: ${e.message}")
                )
                sessionManager.updateSessionStatus(sessionId, SessionStatus.FAILED)
            }
        }
        
        // 返回会话事件流
        return sessionManager.subscribeToSession(sessionId, request.userId ?: "anonymous")
    }
    
    // 保留原有的 executeAgentStream 方法以兼容旧客户端
    suspend fun executeAgentStream(
        projectPath: String,
        request: AgentRequest
    ): Flow<AgentEvent> {
        // ... 原有实现 ...
    }
}

/**
 * 会话感知的 Renderer，将 AgentEvent 广播到 SessionManager
 */
class SessionAwareRenderer(
    private val sessionId: String,
    private val sessionManager: SessionManager
) : CodingAgentRenderer {
    
    override fun renderIterationHeader(current: Int, max: Int) {
        runBlocking {
            sessionManager.broadcastEvent(sessionId, AgentEvent.IterationStart(current, max))
        }
    }
    
    override fun renderLLMResponseChunk(chunk: String) {
        runBlocking {
            sessionManager.broadcastEvent(sessionId, AgentEvent.LLMResponseChunk(chunk))
        }
    }
    
    override fun renderToolCall(toolName: String, paramsStr: String) {
        runBlocking {
            sessionManager.broadcastEvent(sessionId, AgentEvent.ToolCall(toolName, paramsStr))
        }
    }
    
    override fun renderToolResult(
        toolName: String,
        success: Boolean,
        output: String?,
        fullOutput: String?,
        metadata: Map<String, String>
    ) {
        runBlocking {
            sessionManager.broadcastEvent(sessionId, AgentEvent.ToolResult(toolName, success, output))
        }
    }
    
    override fun renderError(message: String) {
        runBlocking {
            sessionManager.broadcastEvent(sessionId, AgentEvent.Error(message))
        }
    }
    
    override fun renderFinalResult(success: Boolean, message: String, iterations: Int) {
        // 将在 Complete 事件中处理
    }
    
    // ... 其他方法实现 ...
}
```

### 3. 新增 Session API 路由

```kotlin
// mpp-server/src/main/kotlin/cc/unitmesh/server/plugins/SessionRouting.kt (新文件)

fun Route.sessionRouting(sessionManager: SessionManager, agentService: AgentService) {
    route("/api/sessions") {
        
        // 创建会话
        post {
            val request = call.receive<CreateSessionRequest>()
            val session = sessionManager.createSession(request)
            call.respond(HttpStatusCode.Created, session)
        }
        
        // 获取所有会话
        get {
            val userId = call.request.queryParameters["userId"]
            val sessions = if (userId != null) {
                sessionManager.getSessionsByOwner(userId)
            } else {
                sessionManager.getAllActiveSessions()
            }
            call.respond(sessions)
        }
        
        // 获取指定会话
        get("/{sessionId}") {
            val sessionId = call.parameters["sessionId"] ?: return@get call.respond(
                HttpStatusCode.BadRequest,
                mapOf("error" to "Missing sessionId")
            )
            
            val session = sessionManager.getSession(sessionId)
            if (session != null) {
                call.respond(session)
            } else {
                call.respond(HttpStatusCode.NotFound, mapOf("error" to "Session not found"))
            }
        }
        
        // 获取会话状态快照
        get("/{sessionId}/state") {
            val sessionId = call.parameters["sessionId"] ?: return@get call.respond(
                HttpStatusCode.BadRequest,
                mapOf("error" to "Missing sessionId")
            )
            
            val state = sessionManager.getSessionState(sessionId)
            if (state != null) {
                call.respond(state)
            } else {
                call.respond(HttpStatusCode.NotFound, mapOf("error" to "Session not found"))
            }
        }
        
        // 订阅会话事件（SSE）
        get("/{sessionId}/stream") {
            val sessionId = call.parameters["sessionId"] ?: return@get call.respond(
                HttpStatusCode.BadRequest,
                mapOf("error" to "Missing sessionId")
            )
            
            val userId = call.request.queryParameters["userId"] ?: "anonymous"
            
            call.respondSse {
                try {
                    sessionManager.subscribeToSession(sessionId, userId).collect { envelope ->
                        val json = Json { encodeDefaults = true }
                        
                        send(
                            ServerSentEvent(
                                data = json.encodeToString(envelope),
                                event = "session_event",
                                id = envelope.eventId
                            )
                        )
                    }
                } catch (e: SessionNotFoundException) {
                    send(
                        ServerSentEvent(
                            data = """{"error": "Session not found"}""",
                            event = "error"
                        )
                    )
                }
            }
        }
        
        // 启动会话执行（结合 Agent）
        post("/{sessionId}/execute") {
            val sessionId = call.parameters["sessionId"] ?: return@post call.respond(
                HttpStatusCode.BadRequest,
                mapOf("error" to "Missing sessionId")
            )
            
            val request = call.receive<AgentRequest>()
            
            val session = sessionManager.getSession(sessionId) ?: return@post call.respond(
                HttpStatusCode.NotFound,
                mapOf("error" to "Session not found")
            )
            
            // 确定项目路径（支持 Git clone）
            val projectPath = if (request.gitUrl != null) {
                // Git clone 逻辑
                gitCloneService.cloneOrPullRepository(
                    gitUrl = request.gitUrl,
                    branch = request.branch,
                    username = request.username,
                    password = request.password,
                    projectId = session.projectId
                )
                // ... 返回项目路径
            } else {
                "/path/to/project/${session.projectId}"
            }
            
            // 启动 Agent 执行（异步）
            CoroutineScope(Dispatchers.IO).launch {
                agentService.executeAgentWithSession(sessionId, projectPath, request).collect()
            }
            
            call.respond(HttpStatusCode.Accepted, mapOf("message" to "Session execution started"))
        }
        
        // 删除会话
        delete("/{sessionId}") {
            val sessionId = call.parameters["sessionId"] ?: return@delete call.respond(
                HttpStatusCode.BadRequest,
                mapOf("error" to "Missing sessionId")
            )
            
            sessionManager.deleteSession(sessionId)
            call.respond(HttpStatusCode.NoContent)
        }
    }
}
```

---

## 💻 客户端实现

### 1. SessionClient（会话客户端）

在 `mpp-ui` 中实现会话管理客户端：

```kotlin
// mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/session/SessionClient.kt

class SessionClient(private val baseUrl: String) {
    private val httpClient = HttpClient()
    private val json = Json { ignoreUnknownKeys = true }
    
    /**
     * 创建会话
     */
    suspend fun createSession(request: CreateSessionRequest): Session {
        val response = httpClient.post("$baseUrl/api/sessions") {
            contentType(ContentType.Application.Json)
            setBody(json.encodeToString(request))
        }
        return response.body()
    }
    
    /**
     * 获取会话列表
     */
    suspend fun getSessions(userId: String? = null): List<Session> {
        val url = if (userId != null) {
            "$baseUrl/api/sessions?userId=$userId"
        } else {
            "$baseUrl/api/sessions"
        }
        val response = httpClient.get(url)
        return response.body()
    }
    
    /**
     * 获取会话详情
     */
    suspend fun getSession(sessionId: String): Session {
        val response = httpClient.get("$baseUrl/api/sessions/$sessionId")
        return response.body()
    }
    
    /**
     * 获取会话状态快照
     */
    suspend fun getSessionState(sessionId: String): SessionState {
        val response = httpClient.get("$baseUrl/api/sessions/$sessionId/state")
        return response.body()
    }
    
    /**
     * 订阅会话事件流（SSE）
     */
    fun subscribeToSession(sessionId: String, userId: String = "anonymous"): Flow<SessionEventEnvelope> = flow {
        // 使用 HttpClient 的 SSE 支持
        httpClient.prepareGet("$baseUrl/api/sessions/$sessionId/stream?userId=$userId").execute { response ->
            val channel = response.bodyAsChannel()
            
            var currentEvent = ""
            var currentData = ""
            
            while (!channel.isClosedForRead) {
                val line = channel.readUTF8Line() ?: break
                
                when {
                    line.startsWith("event:") -> {
                        currentEvent = line.substringAfter("event:").trim()
                    }
                    line.startsWith("data:") -> {
                        currentData = line.substringAfter("data:").trim()
                    }
                    line.isEmpty() && currentData.isNotEmpty() -> {
                        if (currentEvent == "session_event") {
                            val envelope = json.decodeFromString<SessionEventEnvelope>(currentData)
                            emit(envelope)
                        }
                        currentEvent = ""
                        currentData = ""
                    }
                }
            }
        }
    }
    
    /**
     * 启动会话执行
     */
    suspend fun executeSession(sessionId: String, request: AgentRequest) {
        httpClient.post("$baseUrl/api/sessions/$sessionId/execute") {
            contentType(ContentType.Application.Json)
            setBody(json.encodeToString(request))
        }
    }
    
    /**
     * 删除会话
     */
    suspend fun deleteSession(sessionId: String) {
        httpClient.delete("$baseUrl/api/sessions/$sessionId")
    }
}
```

### 2. SessionViewModel（会话视图模型）

```kotlin
// mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/session/SessionViewModel.kt

class SessionViewModel(
    private val sessionClient: SessionClient,
    private val userId: String
) {
    private val _sessions = MutableStateFlow<List<Session>>(emptyList())
    val sessions: StateFlow<List<Session>> = _sessions.asStateFlow()
    
    private val _currentSession = MutableStateFlow<Session?>(null)
    val currentSession: StateFlow<Session?> = _currentSession.asStateFlow()
    
    private val _sessionEvents = MutableStateFlow<List<SessionEventEnvelope>>(emptyList())
    val sessionEvents: StateFlow<List<SessionEventEnvelope>> = _sessionEvents.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private var subscriptionJob: Job? = null
    
    /**
     * 创建新会话
     */
    suspend fun createSession(projectId: String, task: String, metadata: SessionMetadata? = null): Session {
        _isLoading.value = true
        try {
            val request = CreateSessionRequest(
                projectId = projectId,
                task = task,
                userId = userId,
                metadata = metadata
            )
            val session = sessionClient.createSession(request)
            loadSessions()
            return session
        } finally {
            _isLoading.value = false
        }
    }
    
    /**
     * 加载会话列表
     */
    suspend fun loadSessions() {
        _isLoading.value = true
        try {
            val sessions = sessionClient.getSessions(userId)
            _sessions.value = sessions
        } finally {
            _isLoading.value = false
        }
    }
    
    /**
     * 加入会话（订阅事件）
     */
    suspend fun joinSession(sessionId: String) {
        _isLoading.value = true
        try {
            // 加载会话详情
            val session = sessionClient.getSession(sessionId)
            _currentSession.value = session
            
            // 加载历史状态
            val state = sessionClient.getSessionState(sessionId)
            _sessionEvents.value = state.events
            
            // 订阅实时事件
            subscriptionJob?.cancel()
            subscriptionJob = CoroutineScope(Dispatchers.Default).launch {
                sessionClient.subscribeToSession(sessionId, userId).collect { envelope ->
                    // 追加事件到列表
                    _sessionEvents.value = _sessionEvents.value + envelope
                    
                    // 更新会话状态
                    if (envelope.event is AgentEvent.Complete) {
                        _currentSession.value = _currentSession.value?.copy(
                            status = if ((envelope.event as AgentEvent.Complete).success) 
                                SessionStatus.COMPLETED 
                            else 
                                SessionStatus.FAILED
                        )
                    }
                }
            }
        } finally {
            _isLoading.value = false
        }
    }
    
    /**
     * 离开会话（取消订阅）
     */
    fun leaveSession() {
        subscriptionJob?.cancel()
        subscriptionJob = null
        _currentSession.value = null
        _sessionEvents.value = emptyList()
    }
    
    /**
     * 启动会话执行
     */
    suspend fun executeSession(sessionId: String, request: AgentRequest) {
        sessionClient.executeSession(sessionId, request)
    }
    
    /**
     * 删除会话
     */
    suspend fun deleteSession(sessionId: String) {
        sessionClient.deleteSession(sessionId)
        loadSessions()
    }
}
```

### 3. UI 组件示例（Compose）

```kotlin
// mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/session/SessionListScreen.kt

@Composable
fun SessionListScreen(viewModel: SessionViewModel) {
    val sessions by viewModel.sessions.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    
    LaunchedEffect(Unit) {
        viewModel.loadSessions()
    }
    
    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        Text("我的会话", style = MaterialTheme.typography.headlineMedium)
        
        Spacer(modifier = Modifier.height(16.dp))
        
        if (isLoading) {
            CircularProgressIndicator()
        } else {
            LazyColumn {
                items(sessions) { session ->
                    SessionCard(session) {
                        // 点击加入会话
                        viewModel.joinSession(session.id)
                    }
                }
            }
        }
    }
}

@Composable
fun SessionCard(session: Session, onClick: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp).clickable(onClick = onClick),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(session.task, style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.weight(1f))
                StatusBadge(session.status)
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text("Project: ${session.projectId}", style = MaterialTheme.typography.bodySmall)
            Text(
                "Created: ${formatTimestamp(session.createdAt)}",
                style = MaterialTheme.typography.bodySmall
            )
        }
    }
}

@Composable
fun StatusBadge(status: SessionStatus) {
    val color = when (status) {
        SessionStatus.RUNNING -> Color.Green
        SessionStatus.COMPLETED -> Color.Blue
        SessionStatus.FAILED -> Color.Red
        SessionStatus.CANCELLED -> Color.Gray
        else -> Color.Yellow
    }
    
    Surface(
        color = color,
        shape = RoundedCornerShape(4.dp)
    ) {
        Text(
            text = status.name,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            style = MaterialTheme.typography.labelSmall,
            color = Color.White
        )
    }
}

@Composable
fun SessionDetailScreen(viewModel: SessionViewModel) {
    val currentSession by viewModel.currentSession.collectAsState()
    val sessionEvents by viewModel.sessionEvents.collectAsState()
    
    Column(modifier = Modifier.fillMaxSize()) {
        // 顶部会话信息
        currentSession?.let { session ->
            SessionHeader(session)
        }
        
        Divider()
        
        // 事件时间线
        LazyColumn(modifier = Modifier.weight(1f)) {
            items(sessionEvents) { envelope ->
                EventTimelineItem(envelope)
            }
        }
    }
}

@Composable
fun EventTimelineItem(envelope: SessionEventEnvelope) {
    when (val event = envelope.event) {
        is AgentEvent.IterationStart -> {
            Text("🔄 Iteration ${event.current}/${event.max}")
        }
        is AgentEvent.LLMResponseChunk -> {
            Text("💬 ${event.chunk}")
        }
        is AgentEvent.ToolCall -> {
            Text("🔧 Tool: ${event.toolName}")
        }
        is AgentEvent.ToolResult -> {
            Text("✅ Result: ${event.output}")
        }
        is AgentEvent.Error -> {
            Text("❌ Error: ${event.message}", color = Color.Red)
        }
        is AgentEvent.Complete -> {
            Text("🎉 Completed: ${event.message}")
        }
        else -> {}
    }
}
```

---

## 🔄 状态同步与一致性

### 1. 断线重连

客户端断线后，可以通过以下方式恢复：

```kotlin
// mpp-ui/src/commonMain/kotlin/cc/unitmesh/devins/ui/session/SessionSyncManager.kt

class SessionSyncManager(
    private val sessionClient: SessionClient,
    private val viewModel: SessionViewModel
) {
    private var lastEventSequence: Long = 0
    
    /**
     * 断线重连逻辑
     */
    suspend fun reconnect(sessionId: String) {
        // 1. 获取服务器端的最新状态
        val serverState = sessionClient.getSessionState(sessionId)
        
        // 2. 检查是否有缺失的事件
        val missingEvents = serverState.events.filter { it.sequenceNumber > lastEventSequence }
        
        // 3. 应用缺失的事件
        missingEvents.forEach { envelope ->
            viewModel.applyEvent(envelope)
        }
        
        // 4. 更新序列号
        lastEventSequence = serverState.lastEventSequence
        
        // 5. 重新订阅
        viewModel.joinSession(sessionId)
    }
}
```

### 2. 冲突解决

对于多端同时操作的场景（未来扩展），可以使用：

- **Operation-based CRDT**: 操作日志 + 转换
- **Last-Write-Wins (LWW)**: 时间戳优先
- **Manual Merge**: 提示用户手动解决冲突

当前阶段，建议使用 **OWNER / VIEWER** 角色区分：
- **OWNER**: 可以发起操作（启动、暂停、取消）
- **VIEWER**: 只能观察，不能操作

---

## 📊 性能优化

### 1. 事件压缩

对于高频事件（如 LLMResponseChunk），可以在服务端进行批量发送：

```kotlin
class EventBatcher(private val batchSize: Int = 10, private val batchIntervalMs: Long = 100) {
    private val buffer = mutableListOf<AgentEvent.LLMResponseChunk>()
    
    suspend fun addChunk(chunk: AgentEvent.LLMResponseChunk): List<AgentEvent.LLMResponseChunk>? {
        buffer.add(chunk)
        
        if (buffer.size >= batchSize) {
            val batch = buffer.toList()
            buffer.clear()
            return batch
        }
        
        return null
    }
}
```

### 2. 事件分页

历史事件查询支持分页：

```kotlin
// API: GET /api/sessions/{sessionId}/events?offset=0&limit=50
fun getSessionEventsPaginated(
    sessionId: String,
    offset: Long = 0,
    limit: Int = 50
): List<SessionEventEnvelope>
```

### 3. 内存管理

服务端定期清理已完成会话的订阅者：

```kotlin
class SessionCleanupTask(private val sessionManager: SessionManager) {
    fun cleanup() {
        val completedSessions = sessionManager.getAllActiveSessions()
            .filter { it.status == SessionStatus.COMPLETED || it.status == SessionStatus.FAILED }
        
        completedSessions.forEach { session ->
            sessionManager.removeSubscribers(session.id)
        }
    }
}
```

---

## 🔐 安全性考虑

### 1. 认证与授权

建议在后续阶段实现：

```kotlin
// mpp-server: JWT 认证
fun Route.authenticate() {
    install(Authentication) {
        jwt("auth-jwt") {
            realm = "AutoDev"
            verifier(JwtVerifier.create())
            validate { credential ->
                // 验证 JWT
            }
        }
    }
}

// 权限检查
fun checkSessionAccess(userId: String, sessionId: String): Boolean {
    val session = sessionRepository.getSessionById(sessionId) ?: return false
    val participants = sessionRepository.getParticipants(sessionId)
    
    return participants.any { it.userId == userId }
}
```

### 2. Rate Limiting

防止滥用：

```kotlin
fun Route.rateLimiting() {
    install(RateLimiting) {
        limit = 100
        window = 1.minutes
    }
}
```

---

## 📈 实施计划

### Phase 1: 核心会话管理（2-3 天）

- ✅ 定义 Session 数据模型
- ✅ 实现 SessionRepository (SQLDelight)
- ✅ 实现 SessionManager
- ✅ 添加 Session API 路由

### Phase 2: 事件广播与订阅（2-3 天）

- ✅ 修改 AgentService 支持 SessionAwareRenderer
- ✅ 实现事件持久化
- ✅ 实现多订阅者广播机制
- ✅ 测试 SSE 流式传输

### Phase 3: 客户端集成（3-4 天）

- ✅ 实现 SessionClient (Kotlin)
- ✅ 实现 SessionViewModel
- ✅ 实现 SessionListScreen 和 SessionDetailScreen (Compose)
- ✅ 测试多端连接

### Phase 4: 状态同步与断线重连（2 天）

- ✅ 实现 SessionSyncManager
- ✅ 实现断线重连逻辑
- ✅ 测试状态一致性

### Phase 5: 性能优化与安全（1-2 天）

- ✅ 事件批量处理
- ✅ 内存管理
- ✅ 添加认证与授权（可选）

**总计：10-14 天**

---

## 🧪 测试策略

### 1. 单元测试

```kotlin
@Test
fun testSessionCreation() {
    val sessionManager = SessionManager(sessionRepository)
    val request = CreateSessionRequest(
        projectId = "test-project",
        task = "Test task",
        userId = "user-123"
    )
    
    val session = sessionManager.createSession(request)
    
    assertEquals("test-project", session.projectId)
    assertEquals(SessionStatus.PENDING, session.status)
}
```

### 2. 集成测试

```kotlin
@Test
fun testMultiClientSubscription() = runTest {
    val sessionManager = SessionManager(sessionRepository)
    val session = sessionManager.createSession(createTestRequest())
    
    // 模拟两个客户端订阅
    val client1Events = mutableListOf<SessionEventEnvelope>()
    val client2Events = mutableListOf<SessionEventEnvelope>()
    
    launch {
        sessionManager.subscribeToSession(session.id, "user-1").collect {
            client1Events.add(it)
        }
    }
    
    launch {
        sessionManager.subscribeToSession(session.id, "user-2").collect {
            client2Events.add(it)
        }
    }
    
    // 广播事件
    sessionManager.broadcastEvent(session.id, AgentEvent.IterationStart(1, 10))
    
    delay(100)
    
    // 验证两个客户端都收到事件
    assertEquals(1, client1Events.size)
    assertEquals(1, client2Events.size)
}
```

### 3. 端到端测试

使用 Ktor 的 `testApplication` 和 HTTP 客户端进行完整流程测试。

---

## 📚 总结

这个设计方案基于您现有的 KMP 架构，充分复用了：

✅ **事件驱动架构**：`AgentEvent` + SSE  
✅ **SQLDelight 持久化**：跨平台数据存储  
✅ **Ktor Server**：高性能 HTTP + SSE  
✅ **Compose Multiplatform**：统一 UI 渲染  
✅ **ViewModel 模式**：状态管理

通过引入 **Session** 概念，实现了：

🎯 **会话管理**：多端共享同一个 Agent 执行会话  
🎯 **同步输出**：实时事件广播到所有订阅者  
🎯 **状态一致性**：事件序列化 + 快照机制  
🎯 **断线重连**：历史事件回放 + 增量同步

这是一个**渐进式、可扩展**的设计，您可以根据实际需求分阶段实施。

---

## 🔗 下一步

1. **Review 这个设计文档**，确认是否符合您的需求
2. **开始 Phase 1**：实现核心 Session 管理
3. **逐步迭代**：每个 Phase 完成后测试验证
4. **持续优化**：根据实际使用反馈调整

有任何问题或需要调整的地方，请随时告诉我！🚀

