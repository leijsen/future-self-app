# 「未来自我」整体架构设计（待确认）

# Future Self — Architecture Design (pending confirmation)

---

## 0. 框架选型：Flutter

## 0. Framework Choice: Flutter

**理由**：

1. 本项目最重的部分是平台原生能力（iOS FamilyControls/DeviceActivity、Android AccessibilityService/UsageStatsManager），Flutter 的 Platform Channel + 原生模块组织方式与我们的 `screen_time_control` 模块划分天然匹配；
2. 状态管理 Riverpod 成熟稳定，符合 prompt 中的分层要求；
3. 本地存储生态（Hive/drift）完善，纯本地第一阶段无需任何原生构建设置；
4. 单一语言栈（Dart 强类型）适合本项目较多的数据模型与规则引擎逻辑。

**放弃 React Native 的原因**：Expo 体系对原生后台能力（前台 Service、无障碍服务）封装弱，自定义原生模块的调试链路更长。

**Rationale**:

1. The heaviest part of this project is platform-native capability (iOS FamilyControls/DeviceActivity, Android AccessibilityService/UsageStatsManager). Flutter's Platform Channel and native-module organization map naturally onto our `screen_time_control` module split;
2. Riverpod is mature and stable state management, matching the layering the prompt calls for;
3. The local-storage ecosystem (Hive/drift) is solid, and the purely-local first phase needs no native build setup at all;
4. A single language stack (strongly-typed Dart) suits this project's many data models and rule-engine logic.

**Why React Native was dropped**: the Expo system wraps native background capability (foreground Service, accessibility service) poorly, and the debugging path for custom native modules is longer.

---

## 1. 架构分层

## 1. Layering

```
┌─────────────────────────────────────────────┐
│  UI 层 (pages/ + widgets/)                   │  仅展示与交互，不含业务逻辑
│  UI layer (pages/ + widgets/)                │  presentation and interaction only, no business logic
├─────────────────────────────────────────────┤
│  状态/业务层 (providers/, Riverpod)           │  持有状态、调度用例
│  State/business layer (providers/, Riverpod) │  holds state, schedules use cases
├─────────────────────────────────────────────┤
│  领域层 (models/, contract_engine/)          │  纯 Dart：数据模型 + 契约规则引擎
│  Domain layer (models/, contract_engine/)    │  pure Dart: data models + contract rule engine
├─────────────────────────────────────────────┤
│  平台层 (platform/screen_time_control/)      │  统一接口 + 各平台实现
│  Platform layer (platform/screen_time_control/) │ unified interface + per-platform implementations
├─────────────────────────────────────────────┤
│  数据层 (repositories/, Hive/drift 本地存储) │
│  Data layer (repositories/, Hive/drift local storage) │
└─────────────────────────────────────────────┘
```

### platform 模块接口（Platform Channel 桥接）

### platform module interface (bridged over Platform Channel)

```dart
abstract class ScreenTimeControl {
  /// 能力检测：决定走第一层/第二层/第三层降级方案
  /// Capability probe: decides which tier (1/2/3) to fall back to
  ControlCapability getCapability(); // systemLevel | statisticsOnly | none

  Future<void> setAppLimits(List<AppGroupLimit> limits);
  Future<void> enableFocusMode(FocusConfig config);
  Future<void> disableFocusMode(String challengeToken);
  Future<UsageReport> getUsageReport(DateRange range);
  Future<Duration> getRemainingQuota(String groupId);
}
```

- iOS 实现：`FamilyControls` + `ManagedSettings` + `DeviceActivity`（需 entitlement，第一层）
- Android 实现：`UsageStatsManager` + `AccessibilityService` 拦截（第一层）
- 降级实现：仅统计 + 强提醒（第二层）；纯应用内计时（第三层）

- iOS implementation: `FamilyControls` + `ManagedSettings` + `DeviceActivity` (needs the entitlement; tier 1)
- Android implementation: `UsageStatsManager` + `AccessibilityService` interception (tier 1)
- Fallbacks: statistics plus a hard reminder (tier 2); purely in-app timing (tier 3)

---

## 2. 页面路由表（go_router）

## 2. Route table (go_router)

| 路由 | 页面 | 说明 |
|---|---|---|
| `/onboarding/past` | PastSelfPage | "过去的我"问卷（性格标签/坏习惯/自评） |
| `/onboarding/future` | FutureSelfPage | "未来的我"问卷（方向/目标时间/专注承诺） |
| `/onboarding/contract` | ContractSignPage | 契约预览与签署 |
| `/home` | HomePage | 今日专注进度、各分组剩余额度、任务清单 |
| `/focus` | FocusStartPage | 选择时长发起专注（25/45/90/自定义） |
| `/focus/active` | FocusActivePage | 专注进行中锁定页 |
| `/focus/exit-challenge` | ExitChallengePage | 提前退出挑战（1/2/3 档） |
| `/block` | BlockedPage | 限额拦截页（原生层唤起进入） |
| `/tasks` | TasksPage | 每日任务清单 |
| `/report` | ReportPage | 每日/每周使用报告与趋势图 |
| `/letters` | LettersPage | "来自未来的信"列表与详情 |
| `/settings` | SettingsPage | 限额修改（冷静期）、免打扰时段、严格模式 |

| Route | Page | Description |
|---|---|---|
| `/onboarding/past` | PastSelfPage | "Past Self" questionnaire (personality tags / bad habits / self-rating) |
| `/onboarding/future` | FutureSelfPage | "Future Self" questionnaire (direction / target date / focus commitment) |
| `/onboarding/contract` | ContractSignPage | Contract preview and signing |
| `/home` | HomePage | Today's focus progress, remaining quota per group, task list |
| `/focus` | FocusStartPage | Pick a duration and start focus (25/45/90/custom) |
| `/focus/active` | FocusActivePage | Lock screen shown during focus |
| `/focus/exit-challenge` | ExitChallengePage | Early-exit challenge (levels 1/2/3) |
| `/block` | BlockedPage | Quota block page (entered from the native layer) |
| `/tasks` | TasksPage | Daily task list |
| `/report` | ReportPage | Daily/weekly usage report and trend charts |
| `/letters` | LettersPage | "Letters from the future" list and detail |
| `/settings` | SettingsPage | Limit edits (cooling-off period), do-not-disturb window, strict mode |

---

## 3. 数据模型（Hive，第一阶段无后端）

## 3. Data models (Hive; no backend in phase one)

```dart
// 用户画像 —— "过去的我"
// User profile — "Past Self"
UserProfile {
  id, createdAt,
  List<String> personalityTags,   // 性格标签（拖延/易分心/三分钟热度…）
                                  // personality tags (procrastination / easily distracted / quick to lose interest…)
  List<String> badHabits,         // 坏习惯（刷短视频/熬夜打游戏…）
                                  // bad habits (scrolling short videos / gaming late at night…)
  int estimatedScreenMinutes,     // 自评每日屏幕时间
                                  // self-estimated daily screen time
}

// 目标 —— "未来的我"
// Goal — "Future Self"
FutureGoal {
  id, direction,                  // 发展方向（考证/健身/学英语…）
                                  // growth direction (certification / fitness / learning English…)
  DateTime targetDate,            // 目标达成时间（倒计时用）
                                  // target completion date (used for the countdown)
  int committedFocusMinutes,      // 承诺每日专注时长
                                  // committed daily focus time
}

// 自律契约
// Discipline contract
Contract {
  id, signedAt,
  UserProfile profile, FutureGoal goal,
  List<ContractRule> rules,        // 如 entertainmentDailyLimit=60min, focusDailyMin=45min
                                   // e.g. entertainmentDailyLimit=60min, focusDailyMin=45min
  int exitChallengeLevel,          // 退出挑战档位 1/2/3（签约时选定）
                                   // exit-challenge level 1/2/3 (chosen at signing)
  ContractStatus status,           // active / coolingDown(修改中) / superseded
                                   // active / coolingDown (being edited) / superseded
}

// 应用分组与限额
// App groups and limits
AppGroup {
  id, name, category,             // 短视频/短剧/游戏/社交/自定义
                                  // short video / short drama / games / social / custom
  int dailyLimitMinutes,
  bool systemManaged,              // 是否已托管给系统级 API
                                   // whether it has been handed to the system-level API
}

// 每日使用记录（按分组）
// Daily usage record (per group)
DailyUsageRecord {
  date, groupId, usedSeconds,
}

// 专注会话
// Focus session
FocusSession {
  id, startedAt, plannedMinutes,
  status,                         // completed / abandoned / inProgress
  exitChallengeAttempted,         // 是否尝试过提前退出
                                  // whether an early exit was attempted
}

// 每日任务
// Daily task
DailyTask {
  id, date, title, done, rewardMinutes, // 完成解锁奖励时长
                                        // completing it unlocks reward minutes
}

// 积分与堕落值流水
// Points and "decadence" ledger
PointsLedger {
  id, ts, delta, type,            // focusDone / taskDone / overtimeUsed / regression
}

// 来自未来的信
// Letters from the future
FutureLetter {
  id, ts, triggerEvent,           // streak7 / streak30 / relapse
  body,                           // LLM 生成或离线文案库
                                  // LLM-generated, or from the offline copy library
}
```

---

## 4. 关键机制

## 4. Key mechanisms

- **降级策略**：启动时调用 `getCapability()`，UI 根据能力级别显示"系统级限制 / 仅统计提醒 / 应用内专注"模式徽标；
- **契约冷静期**：`Contract` 修改 → 生成 pending 副本 + 24h 冷静期，到期自动生效，期间原契约继续执行；
- **防绕过**：本地记录 `firstInstallAt`（检测卸载重装），网络时间 vs 系统时间比对（检测改时间）；
- **专注计时可靠性**：Android 用前台 Service；iOS 用注释说明后台限制（短时段内通常可行）；
- **LLM 信件**：设置页配置 Claude API key（仅存本地），上传仅画像摘要；无 key / 网络失败时使用离线文案库 fallback；
- **隐私**：全部数据仅本地，首次启动与设置页有明显声明。

- **Degradation strategy**: call `getCapability()` at startup; the UI shows a mode badge of "system-level limits / statistics-only reminders / in-app focus" based on the capability tier;
- **Contract cooling-off period**: editing a `Contract` creates a pending copy plus a 24h cooling-off window; it takes effect automatically when the window expires, and the original contract stays in force meanwhile;
- **Anti-bypass**: record `firstInstallAt` locally (detects uninstall/reinstall), and compare network time against system time (detects clock changes);
- **Focus timing reliability**: a foreground Service on Android; on iOS, document the background limits (usually fine over short spans);
- **LLM letters**: the settings page stores a Claude API key (local only) and uploads only a profile summary; with no key or on network failure, fall back to the offline copy library;
- **Privacy**: everything stays local, with an explicit notice at first launch and in settings.

---

## 5. 各里程碑技术要点

## 5. Technical focus per milestone

| 里程碑 | 内容 | 原生依赖 |
|---|---|---|
| M1 引导流程 | 3 问卷页 + 契约签署 | 无 |
| M2 专注模式 | 计时器 + 锁定页 + 退出挑战 | 无（先纯应用内） |
| M3 使用控制 | Android 统计拦截 → iOS Screen Time | 重：两大平台原生模块 |
| M4 任务激励 | 任务/积分/堕落值 | 无 |
| M5 报告成就 | 周报/成就/设置 | widget/通知常驻 |

M1/M2/M4/M5 均可先在无原生依赖下交付与验证，M3 单独攻坚。

| Milestone | Contents | Native dependency |
|---|---|---|
| M1 Onboarding | 3 questionnaire pages + contract signing | none |
| M2 Focus mode | Timer + lock screen + exit challenge | none (in-app only to start) |
| M3 Usage control | Android stats & blocking → iOS Screen Time | heavy: native modules on both platforms |
| M4 Tasks & motivation | Tasks / points / decadence value | none |
| M5 Reports & achievements | Weekly report / achievements / settings | persistent widget / notification |

M1/M2/M4/M5 can all be delivered and validated without native dependencies first; M3 is a separate push.

---

## 6. 环境准备清单（本机现状）

## 6. Environment checklist (state of this machine)

- ✅ Homebrew、Xcode 命令行工具（macOS 26, Apple Silicon）
- ❌Flutter SDK —— 需安装（brew install --cask flutter，约 1GB）
- ❌CocoaPods —— M3 iOS 阶段需要（brew install cocoapods）
- Android 模拟器/设备 —— M3 Android 阶段需要

- ✅ Homebrew, Xcode command line tools (macOS 26, Apple Silicon)
- ❌ Flutter SDK — needs installing (`brew install --cask flutter`, ~1GB)
- ❌ CocoaPods — needed for the M3 iOS phase (`brew install cocoapods`)
- Android emulator/device — needed for the M3 Android phase
