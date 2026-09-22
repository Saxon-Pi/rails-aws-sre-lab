<!-- omit in toc -->
# AWS DevOps Agent 全体像・主要コンポーネント整理

<!-- omit in toc -->
## 目次

- [1. AWS DevOps Agent とは](#1-aws-devops-agent-とは)
- [2. 全体アーキテクチャ](#2-全体アーキテクチャ)
- [3. Agent Space](#3-agent-space)
- [4. AWS Account Association](#4-aws-account-association)
- [5. Agent Space Role](#5-agent-space-role)
- [6. Investigation](#6-investigation)
- [7. Topology](#7-topology)
- [8. Operator App](#8-operator-app)
- [9. Operator App Role](#9-operator-app-role)
- [10. Investigation Guardrail](#10-investigation-guardrail)
- [11. Elevated Role](#11-elevated-role)
- [12. Directed Actions と人間による承認](#12-directed-actions-と人間による承認)
- [13. Guardrail の考え方](#13-guardrail-の考え方)
- [14. Skills](#14-skills)
- [15. Memory](#15-memory)
- [16. Custom Agent / Trigger](#16-custom-agent--trigger)
- [17. Third-party Integration](#17-third-party-integration)
- [18. 各コンポーネントの役割まとめ](#18-各コンポーネントの役割まとめ)
- [19. 今回のハンズオンで利用する範囲](#19-今回のハンズオンで利用する範囲)

---

## 1. AWS DevOps Agent とは

AWS DevOps Agent は、AWS 環境の運用・障害対応を支援する AI Agent

CloudWatch などの Observability 情報や AWS リソースの構成・関係性を参照しながら、  
障害発生時の Investigation（調査）や Root Cause Analysis（RCA）を行う

必要に応じて、  
人間の承認を伴う Directed Actions によって変更・復旧操作まで行わせることができる

大きく分けると、次の流れで動作する

```text
AWS環境
ECS / ALB / RDS / CloudWatch / etc..
        │
        │ Telemetry / Events / Resource 情報
        ▼
    DevOps Agent
        │
        ├─ Topology を使って関連リソースを把握
        ├─ Metrics / Logs / Events などを調査
        └─ Investigation / RCA
        │
        ▼
   Operator App
        │
        ▼
       人間

必要に応じて

       人間
        │
        │ 復旧操作を承認
        ▼
 Directed Actions
        │
        ▼
    AWSリソース変更
```

---

## 2. 全体アーキテクチャ

主要な登場人物を整理すると、以下のようになる

``` text
                         Agent Space
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
          ▼                   ▼                   ▼
 AWS Account Association  Operator App      外部サービス連携
          │                   │             New Relic等
          │                   ▼
          │             Operator App Role
          │
          ▼
   Agent Space Role
          │
          ▼
      AWS Account
          │
          ├─ ECS
          ├─ ALB
          ├─ RDS
          ├─ CloudWatch
          ├─ CloudTrail
          └─ etc.
          │
          ▼
       Topology
          │
          ▼
 Investigation / RCA

復旧操作を行う場合

 Investigation / RCA
          │
          ▼
      人間による承認
          │
          ▼
      Elevated Role
          │
          ▼
     Directed Actions
          │
          ▼
      AWSリソース変更
```

---

## 3. Agent Space

Agent Space は、DevOps Agent を利用するためのトップレベルの管理単位

「Agent が活動するワークスペース」のようなイメージで、  
AWS Account Association や Operator App などの設定をまとめる

``` text
Agent Space
   │
   ├─ AWS Account Association
   ├─ IAM Role
   ├─ Operator App
   ├─ Topology
   ├─ Investigation
   └─ 各種Integration
```

Agent Space 自体が「どの AWS リソースへアクセスできるか」を直接決めるわけではない

実際のアクセス可能範囲は IAM Role / Policy によって制御する

---

## 4. AWS Account Association

AWS Account Association は、

> この Agent Space が、どの AWS Account を調査対象として扱うか

を関連付ける仕組みである

``` text
Agent Space
     │
     │ AWS Account Association
     ▼
AWS Account
     │
     ├─ ECS
     ├─ ALB
     ├─ RDS
     └─ CloudWatch
```

ただし、

``` text
Account Association
=
AWS Account内の全リソースを自由に操作可能
```

という意味ではなく、  
Agent が実際に利用できる AWS API は IAM Role / Policy によって制限される

---

## 5. Agent Space Role

Agent Space Role は、  
DevOps Agent が AWS 環境を調査するために AssumeRole する IAM Role

イメージとしては以下となる

``` text
DevOps Agent
     │
     │ AssumeRole
     ▼
Agent Space Role
     │
     │ IAM Policy
     ▼
AWS Resources
```

AWS が用意する Investigation 用の Managed Policy を利用することで、  
CloudWatch、ECS、ELB などの情報を Agent が参照できるようになる

### AssumeRole と Policy の違い

``` text
AssumeRole
=
Agent が IAM Role を「借りる」

Policy
=
借りた Role で「何ができるか」
```

---

## 6. Investigation

Investigation は、DevOps Agent が障害や異常について調査する処理である

例えば ALB 5XX Alarm が発生した場合、

``` text
CloudWatch Alarm
「ALB 5XX 発生」
        │
        ▼
DevOps Agent
        │
        ├─ ALB を確認
        ├─ Target Group を確認
        ├─ ECS Service を確認
        ├─ ECS Task を確認
        ├─ Logs / Metrics を確認
        └─ Events / CloudTrail を確認
        │
        ▼
Root Cause Analysis
```

のように複数の情報を横断して原因を調査する

---

## 7. Topology

Topology とは、

> DevOps Agent が理解している「システムの地図」

のようなものである

単なる AWS リソース一覧ではなく、リソース同士の関係性を含み、  
例えば Rails + ECS 環境なら、概念的には以下のような構成になる

``` text
Internet
   │
   ▼
Route53
   │
   ▼
ALB
   │
   ▼
Target Group
   │
   ▼
ECS Service
   │
   ▼
ECS Task
   │
   ├────────► RDS
   │
   └────────► CloudWatch Logs
```

この Topology があることで、

``` text
ALBで障害
   │
   ▼
このALBのTargetは？
   │
   ▼
ECS Service
   │
   ▼
Taskの状態は？
```

というように、関連リソースを辿りながら調査できる

### Topology と Telemetry の違い

``` text
Topology
=
どこを調べるべきか判断するための「地図」

Metrics / Logs / Events / Traces
=
そこで何が起きたか確認するための「証拠」
```

### Topology と IAM の違い

``` text
Topology
=
Agentが理解しているシステムの地図

IAM
=
Agentが実際にアクセスしてよい範囲
```

「Topology にリソースが存在すること」と、  
「そのリソースに対する操作権限を持っていること」は別問題となる

---

## 8. Operator App

Operator App は、

> 人間が DevOps Agent とやり取りするための Web UI

である

``` text
AWS環境
   │
   ▼
DevOps Agent
   │
   ▼
Agent Space
   │
   ▼
Operator App
   │
   ▼
  人間
```

Operator App では、Investigation の確認、  
Agent との Chat、調査結果の確認などを行う

復旧操作を利用する場合には、人間と Agent のやり取りや承認にも関係する

---

## 9. Operator App Role

Agent が AWS 環境を調査するための Role と、  
人間が Operator App を操作するための Role は分離されている

``` text
Agent Space Role
     │
     ▼
DevOps Agent
     │
     └─ AWS環境を調査


Operator App Role
     │
     ▼
    人間
     │
     └─ DevOps Agent を操作
```

つまり、

``` text
Agent の AWSアクセス権限

と

人間の DevOps Agent 操作権限
```

を別々に管理できる

---

## 10. Investigation Guardrail

Agent Space Role に強い IAM 権限を与えたからといって、  
Agent がそのすべてを自由に利用できるわけではない

DevOps Agent 側にも Guardrail が存在し、  
Agent が利用可能な権限には追加の制約がかかる

概念的には、以下の関係となる

``` text
IAM Role で許可された権限
        ∩
DevOps Agent Guardrail
        │
        ▼
Agent が実際に利用可能な権限
```

そのため、

``` text
IAM RoleでAllowされている
=
Agentが必ず実行できる
```

わけではない

---

## 11. Elevated Role

通常の Investigation Role は調査・分析を目的とする

一方、障害復旧などで AWS リソースを変更する場合には、別途 Elevated Role を利用する

``` text
Investigation

Agent Space Role
      │
      ▼
調査・分析


Recovery / Change

Elevated Role
      │
      ▼
変更・復旧操作
```

調査権限と変更権限を分離することで、  
通常時から Agent に強い変更権限を持たせる必要がなくなる

---

## 12. Directed Actions と人間による承認

DevOps Agent に変更・復旧操作を行わせる場合、  
人間による承認を伴う Directed Actions を利用する

概念的な流れは以下となる

``` text
障害発生
   │
   ▼
Investigation
   │
   ▼
RCA
   │
   ▼
Agent が復旧操作を提案
   │
   ▼
人間が内容を確認
   │
   ▼
承認
   │
   ▼
Elevated Role
   │
   ▼
承認内容に限定された権限
   │
   ▼
Directed Action
   │
   ▼
AWSリソース変更
```

重要なのは、

> 人間が承認したことと、その操作を安全に実行してよいことは別

という考え方である

つまり IAM、承認、Session Policy、DevOps Agent 側の Guardrail など、  
複数の安全機構によって実行可能範囲は制限されることになる

---

## 13. Guardrail の考え方

復旧操作でも、

``` text
「人間が承認したから何でも実行可能」
```

とはならず、概念的には以下の関係となる

``` text
Elevated Role
      ∩
AgentがサポートしているAction
      ∩
人間が承認したAction / Resource
      ∩
DevOps Agent側のGuardrail
      │
      ▼
実際に実行可能な操作
```

つまり DevOps Agent は、

> 人間 + AI の組み合わせでも誤操作が発生する可能性がある

ことを前提に、多層防御で設計されている

---

## 14. Skills

Skills は、

> DevOps Agent に追加する運用ノウハウ・手順書

のようなものである

例えば、

``` text
ECS障害が発生した場合

1. ALB Target Healthを確認
2. ECS Service Eventを確認
3. Task State Changeを確認
4. CloudWatch Logsを確認
5. 直近Deployとの差分を確認
```

といった自社固有の運用ノウハウを Agent に持たせる用途で利用できる

概念的には、以下の情報を組み合わせて分析を行うことになる

``` text
AWS標準の知識
      +
Topology
      +
Telemetry
      +
自社Skill
      │
      ▼
自社環境に合わせたInvestigation / RCA
```

---

## 15. Memory

Memory は、Agent が環境について学習・保持する知識に関係する仕組み

Topology、コードや Pipeline の関係、運用上の知識など、  
Agent が環境を理解するための情報に利用される

Skills が「人間が明示的に与える運用知識」だとすると、  
Memory は「Agent が環境について保持する知識」というイメージとなる

---

## 16. Custom Agent / Trigger

より高度な利用では、用途を限定した Custom Agent を作ることもできる

例えば、

``` text
RDS専用Agent
ECS障害調査Agent
定期ヘルスチェックAgent
```

のように、利用する Tools / Skills / Memory を用途に合わせて構成できる

Trigger を利用すれば、Custom Agent をスケジュールなどの条件で起動することもできる

最初の DevOps Agent 検証では必須ではなく、標準 Agent の能力を確認した後に検討する

---

## 17. Third-party Integration

DevOps Agent は AWS 内の情報だけでなく、  
外部の Observability / Incident Management / Development Tool と組み合わせることもできる

例えば New Relic を利用している環境では、以下のような構成を検討できる

``` text
New Relic
Metrics / APM / Traces / Alerts
       │
       ▼
DevOps Agent
       │
       ├─ AWS Resource情報
       ├─ Topology
       ├─ CloudWatch
       └─ New Relic
       │
       ▼
Investigation / RCA
```

---

## 18. 各コンポーネントの役割まとめ


| コンポーネント | 役割 |
| --- | --- |
| Agent Space             | DevOps Agent の管理・実行単位 |
| AWS Account Association | Agent Space と調査対象 AWS Account の関連付け |
| Agent Space Role        | Agent が AWS 環境を調査するための IAM Role |
| Investigation           | 障害・異常について Agent が行う調査 |
| Topology                | AWS リソースと関係性を表す「システムの地図」 |
| Operator App            | 人間が Agent とやり取りする Web UI |
| Operator App Role       | 人間が Operator App / Agent を操作するための権限 |
| Guardrail               | Agent が利用可能な操作範囲に追加の安全制約を設ける仕組み |
| Elevated Role           | 変更・復旧操作で利用する追加権限 |
| Directed Actions        | 人間の承認を伴って Agent が変更・復旧を行う仕組み |
| Skills                  | Agent に追加する独自の運用ノウハウ・手順 |
| Memory                  | Agent が環境について保持する知識 |
| Custom Agent            | 特定用途向けに構成した Agent |
| Trigger                 | Custom Agent を条件・スケジュールなどで起動する仕組み |
| Third-party Integration | New Relic など外部サービスとの連携 |

## 19. 今回のハンズオンで利用する範囲

最初からすべての機能を利用するのではなく、  
まず標準 DevOps Agent の Investigation / RCA 能力を確認する

``` text
Agent Space
     │
     ▼
Agent Space Role
     │
     ▼
AWS Account Association
     │
     ▼
Operator App
     │
     ▼
Topology確認
     │
     ▼
障害発生
     │
     ▼
Investigation
     │
     ▼
RCA
     │
     ▼
手動RCAとの比較
```

まずは Investigation-only の構成で検証し、標準 Agent の能力と不足点を確認する

その後、必要に応じて、

``` text
Skills
Elevated Role / Directed Actions
New Relic Integration
Custom Agent
Trigger
```

などを追加していく

この順序にすることで、

> 標準の DevOps Agent だけでどこまで SRE / インフラ運用を任せられるのか

を評価することを目的としている

---
