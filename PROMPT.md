# 项目 Prompt：个人成长管理 App「未来自我」

# Project Prompt: Personal Growth Management App "Future Self"

---

## 一、产品概述

## 1. Product Overview

请帮我开发一个跨平台移动 App（iOS + Android，使用 Flutter 或 React Native），核心定位是：**帮助用户通过"回顾过去的自己 + 规划未来的自己"，来管理当下的手机使用习惯**。

产品逻辑：用户在引导流程中定义"过去的我"（性格特征、坏习惯）和"未来的我"（想成为的人、想做的事），系统据此生成个性化自律契约，并实际干预手机使用——限制短视频、短剧、游戏等娱乐 App 的时长，在专注时段锁定干扰 App。用户不是被家长管控，而是**被"自己设定的目标"管控**——这是与常规屏幕时间工具的核心差异，所有拦截、提醒文案都要围绕这一点设计。

Please build me a cross-platform mobile app (iOS + Android, using Flutter or React Native). Its core positioning is: **helping users manage their current phone habits by "looking back at their past self + planning their future self"**.

Product logic: during onboarding the user defines their "Past Self" (personality traits, bad habits) and "Future Self" (who they want to become, what they want to do). From that the system generates a personalised discipline contract and actually intervenes in phone use — limiting time spent in entertainment apps like short video, short dramas and games, and locking distracting apps during focus periods. The user is not policed by a parent; they are **policed by goals they set themselves** — that is the core difference from ordinary screen-time tools, and every block screen and reminder should be designed around it.

---

## 二、核心功能模块

## 2. Core Feature Modules

### 1. 引导与画像模块（Onboarding）

### 1. Onboarding & Profiling Module (Onboarding)

- **"过去的我"问卷**（2-3 屏，每屏一个问题，可跳过）：
  - 性格标签多选：拖延、易分心、三分钟热度、晚睡强迫、报复性熬夜、社交依赖等（≥10 个标签供选，支持自定义）；
  - 想改掉的坏习惯：刷短视频、追短剧、熬夜打游戏、反复解锁手机等；
  - 自评：估计自己每天实际屏幕时间（用于后续真实数据对比，制造认知冲击）。
- **"未来的我"问卷**：想发展的方向（考证、健身、学英语、读书、副业等）、目标时间（3个月/半年/1年）、每天愿意投入的专注时长。
- 基于回答生成**个性化自律契约**（规则引擎 + 可选 LLM 润色文案），例如："一个总被短视频吸走注意力、想半年内通过英语六级的你，为自己设定：娱乐 App 每日 ≤ 60 分钟，每日专注学习 ≥ 45 分钟。"用户需点击"签署"确认。契约在 App 内随时可查，修改需二次确认 + 24 小时冷静期（防止深夜破戒时给自己放水）。

- **"Past Self" questionnaire** (2–3 screens, one question per screen, skippable):
  - Multi-select personality tags: procrastination, easily distracted, quick to lose interest, forced late nights, revenge bedtime scrolling, social dependency, etc. (≥10 tags to choose from, custom ones supported);
  - Bad habits to break: scrolling short videos, bingeing short dramas, gaming late at night, unlocking the phone over and over, etc.;
  - Self-rating: estimated actual daily screen time (used later against real data to create a cognitive shock).
- **"Future Self" questionnaire**: the direction to grow in (certification, fitness, learning English, reading, side project, etc.), the target horizon (3 months / 6 months / 1 year), and the daily focus time they are willing to invest.
- Generate a **personalised discipline contract** from the answers (rule engine plus optional LLM-polished copy), e.g.: "You, who keep losing attention to short video and want to pass CET-6 within six months, set for yourself: entertainment apps ≤ 60 minutes a day, focused study ≥ 45 minutes a day." The user must tap "sign" to confirm. The contract is viewable in-app at any time; editing requires a second confirmation plus a 24-hour cooling-off period (so you cannot go easy on yourself during a late-night lapse).

---

### 2. 手机使用控制模块（核心难点，需分层实现）

### 2. Phone Usage Control Module (the hard part; implement in tiers)

**优先级从高到低三层实现，逐层降级：**

**Implement in three tiers from highest priority to lowest, degrading tier by tier:**

- **第一层（系统级限制）**：
  - iOS：FamilyControls / ManagedSettings / DeviceActivity 框架。注意：需要向 Apple 申请 Family Controls entitlement（申请周期数周），文档中需说明流程及被拒的应对。
  - Android：UsageStatsManager 统计前台应用 + AccessibilityService 检测被限 App 切到前台时弹出全屏拦截页（说明各厂商 ROM 的电池优化白名单设置步骤）。
- **第二层（降级方案，entitlement 未批或系统限制不生效时）**：仅做使用统计 + 到时强提醒 + 全屏劝导页。
- **第三层（统计都拿不到时）**：App 内置专注计时，专注期间仅屏蔽 App 自身通知。

- **Tier 1 (system-level limits)**:
  - iOS: the FamilyControls / ManagedSettings / DeviceActivity frameworks. Note: you must apply to Apple for the Family Controls entitlement (takes weeks); the docs need to cover the process and what to do if it is rejected.
  - Android: UsageStatsManager counts foreground apps, plus an AccessibilityService that pops a full-screen block page when a limited app comes to the foreground (document the battery-optimisation whitelist steps for each vendor ROM).
- **Tier 2 (fallback, when the entitlement is denied or system limits do not take effect)**: usage statistics only, plus a hard reminder when the limit is hit and a full-screen persuasion page.
- **Tier 3 (when even statistics are unavailable)**: in-app focus timer; during focus only the app's own notifications are blocked.

**具体能力**：

**Concrete capabilities**:

- 娱乐 App 分组（用户自选分组：短视频/短剧/游戏/社交），每组设每日限额，含"今日剩余额度"实时展示（需常驻通知或桌面小组件）；
- 到达限额后屏蔽该组 App，屏蔽页展示：现在的时间、今天已刷的时长、你签的契约原文、以及一句基于"未来目标"生成的文案（如"英语六级还有 87 天"）；
- **专注模式**：25/45/90 分钟番茄钟或自定义时长，期间锁定 App 全部不可用；提前退出门槛可由用户自己在签约时选择严格程度（1 档仅确认弹窗 / 2 档输入一段自己写的话 / 3 档强制倒计时 60 秒后才能退出）；
- 每日/每周使用报告：分组实际时长 vs 限额对比 + 与用户自估值对比的趋势图。

- Entertainment app groups (user-chosen groups: short video / short drama / games / social), each with a daily limit and a live "remaining quota today" display (needs a persistent notification or a home-screen widget);
- Block that group's apps once the limit is reached. The block page shows: the current time, how long you have scrolled today, the verbatim text of the contract you signed, and one line generated from your "future goal" (e.g. "87 days until CET-6");
- **Focus mode**: a 25/45/90-minute pomodoro or a custom duration, during which the locked apps are all unavailable. The user chooses how strict the early-exit gate is at signing time (level 1: confirm dialog only / level 2: type a passage you wrote yourself / level 3: forced 60-second countdown before you can exit);
- Daily/weekly usage report: actual time per group vs. the limit, plus a trend chart against the user's own estimate.

**防绕过**（按可行程度实现，做不成的在文档说明）：

**Anti-bypass** (implement in order of feasibility; document whatever cannot be done):

- 卸载重装检测：本地记录首次安装时间；
- 修改系统时间检测：与网络时间比对；
- 屏蔽页禁止直接跳系统设置去解除限制（Android 端）。

- Uninstall/reinstall detection: record the first install time locally;
- System clock change detection: compare against network time;
- The block page must not allow jumping straight into system settings to lift the limit (Android).

---

### 3. 专注与任务模块

### 3. Focus & Tasks Module

- 专注计时器，专注期间屏蔽生效，锁屏后计时仍需可靠运行（前台 Service / 后台任务说明）；
- 目标拆解为每日任务清单（背50个单词、健身30分钟等），完成任务解锁"奖励时长"（额外娱乐额度）或积分；
- 专注结束简短打卡（1-2 项，别做成负担）。

- A focus timer with blocking in effect during focus; timing must still run reliably after the screen locks (foreground Service / background-task notes);
- Break the goal into a daily task list (memorize 50 words, work out 30 minutes, etc.); completing a task unlocks "reward time" (extra entertainment quota) or points;
- A short check-in when focus ends (1–2 items — do not make it a burden).

---

### 4. 激励与反馈模块

### 4. Motivation & Feedback Module

- 积分/等级 + "堕落值"双轨：满勤涨积分，超时刷娱乐涨堕落值，堕落值过高触发"未来的我"警告页（展示用户自己签的契约 + 未来目标倒计时）；
- "来自未来的信"：连续达标 7 天 / 30 天，或严重破戒时，展示基于用户画像生成的一封信（可接 Claude API，key 由用户配置，需做好离线 fallback 文案库）；
- 连续打卡日历、成就徽章。

- A dual track of points/levels plus a "decadence value": a full streak raises points, overtime entertainment raises decadence, and excessive decadence triggers a "Future Self" warning page (showing the contract the user signed plus the countdown to the future goal);
- "Letters from the future": after 7 / 30 consecutive qualifying days, or after a serious lapse, show a letter generated from the user profile (may use the Claude API with a user-configured key; a solid offline fallback copy library is required);
- A streak calendar and achievement badges.

---

### 5. 数据与设置

### 5. Data & Settings

- 本地优先（SQLite/Hive），数据导出（JSON/CSV）；
- 隐私要点（需在首次启动和设置页明示）：性格问卷、习惯数据、使用记录**全部仅存本地**，接 LLM 生成文案时仅上传画像摘要并明确告知用户；
- 设置页：修改限额（触发契约冷静期规则）、免打扰时段（如 23:00 后自动全屏蔽）、严格模式开关。

- Local first (SQLite/Hive), with data export (JSON/CSV);
- Privacy essentials (must be stated clearly at first launch and in settings): the personality questionnaire, habit data and usage records **all stay local only**; when using an LLM to generate copy, upload only a profile summary and tell the user explicitly;
- Settings page: edit limits (triggers the contract cooling-off rules), a do-not-disturb window (e.g. block everything after 23:00), and a strict-mode switch.

---

## 三、技术与架构要求

## 3. Technical & Architectural Requirements

- Flutter 或 React Native 二选一并说明理由；原生控制能力用 Platform Channel 桥接；
- 分层：UI / 业务逻辑 / 平台原生层 / 数据层；状态管理 Riverpod 或 Zustand；
- 平台能力封装为独立模块 `screen_time_control`，统一接口（`setAppLimits` / `enableFocusMode` / `disableFocusMode` / `getUsageReport` / `getRemainingQuota`），按平台各实现一份，接口需有"能力检测"方法（`isSystemLevelControlAvailable`）以便降级；
- 契约、限额、任务等核心数据需定义清晰的本地数据模型（先给出表结构/模型定义再写代码）；
- 第一阶段无后端、无账号，预留同步接口；LLM 文案接 Claude API（用户自配 key）。

- Pick one of Flutter or React Native and justify the choice; bridge native control capability over Platform Channels;
- Layering: UI / business logic / platform native layer / data layer; state management with Riverpod or Zustand;
- Wrap the platform capability in a standalone `screen_time_control` module with one unified interface (`setAppLimits` / `enableFocusMode` / `disableFocusMode` / `getUsageReport` / `getRemainingQuota`), one implementation per platform; the interface needs a "capability probe" method (`isSystemLevelControlAvailable`) so it can degrade;
- Define clear local data models for the core data (contract, limits, tasks) — give the table structures / model definitions before writing code;
- No backend and no accounts in phase one, but leave room for a sync interface; LLM copy uses the Claude API (user-supplied key).

---

## 四、开发里程碑（按此顺序分批交付，每批完成后暂停验证）

## 4. Development Milestones (deliver in batches in this order; pause and validate after each)

1. **M1 引导流程**：3 个问卷页 + 契约生成与签署页，纯本地跑通；（已完成）
2. **M2 专注模式**：计时器 + 锁定界面 + 提前退出挑战（先只做 App 内部效果，不接系统级控制）；（已完成）
3. **M3 使用控制**：Android 端统计与拦截 → iOS 端 Screen Time API（含 entitlement 说明与降级方案）；
4. **M4 任务与激励**：任务清单、积分、堕落值；
5. **M4.5 自律挑战金**：见第六章 PRD —— 第一版为全虚拟模式（本地记账 + 模拟支付流程），验证留存后再接真实支付与合规方案；
6. **M5 报告与成就**：周报图表、成就、设置页。

1. **M1 Onboarding flow**: 3 questionnaire pages plus contract generation and signing, running purely locally; (done)
2. **M2 Focus mode**: timer, lock screen and early-exit challenge (in-app effects only to start, no system-level control); (done)
3. **M3 Usage control**: Android statistics and blocking → iOS Screen Time API (including entitlement notes and fallback plan);
4. **M4 Tasks & motivation**: task list, points, decadence value;
5. **M4.5 Discipline stake**: see the PRD in chapter 6 — version one is fully virtual (local bookkeeping plus a simulated payment flow); wire up real payment and compliance only after retention is validated;
6. **M5 Reports & achievements**: weekly report charts, achievements, settings page.

---

## 五、交付要求

## 5. Delivery Requirements

1. 每个里程碑给出可运行代码（含 iOS/Android 目录）；
2. 主界面：今日专注进度、各分组剩余额度、任务清单；
3. 屏蔽页 / 拦截页 / "未来的信" 三类关键情绪化页面的完整 UI；
4. 周报统计页；
5. README：环境搭建、iOS entitlement 申请步骤、Android 各厂商（小米/华为/OV）后台保活与无障碍设置引导、已知限制清单（哪些控制在不越狱/不 root 的设备上做不到）；
6. **先输出整体架构图（文字版）、页面路由表、数据模型定义，经确认后再开始编码**；每个里程碑结束附自测清单。

1. Ship runnable code for each milestone (including the iOS/Android directories);
2. Main screen: today's focus progress, remaining quota per group, task list;
3. Full UI for the three key emotional screens: block page / interception page / "letter from the future";
4. A weekly report and statistics page;
5. README: environment setup, iOS entitlement application steps, background-keepalive and accessibility setup guides for each Android vendor (Xiaomi / Huawei / OPPO / vivo), and a known-limits list (which controls cannot be done on non-jailbroken / non-rooted devices);
6. **Output the overall architecture (text form), the route table and the data model definitions first, and only start coding after they are confirmed**; attach a self-test checklist at the end of each milestone.

---

## 六、PRD：「自律挑战金」机制（M4.5）

## 6. PRD: the "Discipline Stake" Mechanism (M4.5)

### 6.1 产品定位

### 6.1 Product Positioning

将"损失厌恶"从心理机制升级为真实承诺：用户投入小额金钱作为"挑战金"，通过完成自律目标赢回全额返还。设计基调是**游戏化激励而非惩罚**——用户快乐地"在赢"，而不是焦虑地"怕输"。

Upgrade "loss aversion" from a psychological mechanism into a real commitment: the user puts in a small amount of money as a "stake" and wins a full refund by completing their discipline goals. The design tone is **gamified motivation, not punishment** — the user is happily "winning", not anxiously "afraid of losing".

### 6.2 核心参数

### 6.2 Core Parameters

| 参数 | 设定 | 理由 |
|---|---|---|
| 周期与定价 | 30 天一期，起步价 ¥29.9 | 咖啡价决策无痛；单价过高会变成"惩罚"心智 |
| 达标天数 | **22/30 天**（73%），非 15/30 | 15/50% 过松易刷；73% 是"踮脚够得着"，留 8 天容错 |
| 达标判定 | 当日专注 ≥ 契约承诺分钟数（复用 M2 FocusSession 数据） | 无需新增统计口径 |
| 未达标返还 | **按比例返还**（如完成 18 天返还 60%） | 全扣太狠会导致一次失败即卸载；比例返保留"还差一点"的挽回心态 |
| 购买限制 | 30 天内仅可购 1 期，未达标者可手动开启下一期 | 防冲动复购 |
| 防作弊 | 达标日需全天无强退会话；M3 之后叠加系统级绕过检测 | 提前退出/改时间的日期不计达标 |

| Parameter | Setting | Rationale |
|---|---|---|
| Cycle & price | One 30-day round, starting at ¥29.9 | A coffee-priced decision is painless; too high a price turns it into a punishment mindset |
| Qualifying days | **22/30 days (73%)**, not 15/30 | 15/50% is too loose and easy to game; 73% is "reachable if you stretch", leaving 8 days of slack |
| Qualifying check | That day's focus ≥ the minutes promised in the contract (reuse M2 FocusSession data) | No new statistic needed |
| Refund when short | **Pro-rata refund** (e.g. 18 days completed returns 60%) | Forfeiting everything is brutal and one failure means uninstalling; pro-rata keeps the "just a bit more" recovery mindset |
| Purchase limit | Only 1 round per 30 days; those who did not qualify may manually open the next one | Prevents impulsive repurchase |
| Anti-cheat | A qualifying day must have no forced-exit sessions all day; layer system-level bypass detection on top after M3 | Days with an early exit or a clock change do not count |

### 6.3 防焦虑设计（关键）

### 6.3 Anti-anxiety Design (critical)

1. **文案基调**：挑战金叫"自律挑战金"，达标叫"赢回"，失败文案为调侃式（"守护了 ¥12 的自己"），绝不羞辱；
2. **每日进度可视化**："第 9 天 · 今日专注 40/45 分钟"——让用户每天处于"在赢"状态；
3. **免罚卡**：每期 2 张"休息日卡"，主动声明免计当日，化解完美主义焦虑；
4. **绝不自动续费**：第二期必须手动开启，是口碑生命线；
5. **达标全返仅可提现或续期**，不诱导转化为平台收入。

1. **Copy tone**: the stake is called a "discipline stake", qualifying is "winning it back", and failure copy is tongue-in-cheek ("you protected ¥12 of yourself") — never shaming;
2. **Daily progress made visible**: "Day 9 · 40/45 focus minutes today" — keeps the user in a "winning" state every day;
3. **Rest-day cards**: 2 "rest day cards" per round, proactively declared to exclude that day, defusing perfectionist anxiety;
4. **Never auto-renew**: the second round must be opened manually — this is the reputation lifeline;
5. **A full qualifying refund is withdrawable or renewable only** — do not funnel it into platform revenue.

### 6.4 风险与合规（真实支付前必须解决）

### 6.4 Risk & Compliance (must be resolved before real payments)

- **iOS 审核**：押金返现类属 App Store 3.2.2 灰区，文案与流程需谨慎（可能需 IAP + 变通返还路径）；
- **资金合规**：真实资金池有二清风险，国内建议"完成任务后广告/合作补贴返现"模式；
- **协议**：用户协议明确"挑战金"性质（自律承诺，非投资/赌注）。

- **iOS review**: deposit-and-refund sits in a grey area of App Store 3.2.2; copy and flow must be careful (you may need IAP plus a workable refund path);
- **Funds compliance**: a real funds pool carries second-hand clearing risk; in China, an "advertising / partner subsidy refund after completing tasks" model is recommended;
- **Agreement**: the user agreement must state clearly what the "stake" is (a discipline commitment, not an investment or a wager).

### 6.5 实施决策

### 6.5 Implementation Decision

第一版（M4.5）为**全虚拟模式**：本地记账 + 模拟支付流程，跑通玩法闭环并验证留存；真实支付与合规方案待数据验证后单独立项。

Version one (M4.5) is a **fully virtual model**: local bookkeeping plus a simulated payment flow, to run the full gameplay loop and validate retention. Real payments and the compliance plan become a separate project once the data validates it.

### 6.6 数据模型（新版补充）

### 6.6 Data Model (new addition)

```
ChallengeRound {
  id, startDate, endDate,        // 30 天周期 / 30-day cycle
  priceYuan: 29.9,
  targetDays: 22,                // 达标天数 / qualifying days
  achievedDays: int,             // 已达标天数（每日结算时累加） / qualifying days so far (accumulated at daily settlement)
  restCardsLeft: 2,              // 免罚卡剩余 / rest-day cards remaining
  status,                        // active / won / partialRefund / pending-settle
}

DailyCheck {
  date, roundId,
  focusMinutes,                  // 当日有效专注分钟 / effective focus minutes that day
  achieved: bool,                // focusMinutes >= 契约承诺 / focusMinutes >= the contract's promise
  usedRestCard: bool,
  counted: bool,                 // achieved || usedRestCard
  cheatFlag: bool,               // 当日存在强退/作弊会话 / a forced-exit or cheating session occurred that day
}
```
