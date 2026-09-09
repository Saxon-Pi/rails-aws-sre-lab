<!-- omit in toc -->
# Rails AWS SRE Lab

Ruby on Rails アプリケーションを AWS 上で構築・運用しながら、  
**AWS × Rails × Terraform** を用いた SRE の実践スキルを学ぶためのオリジナルハンズオン

---

<!-- omit in toc -->
## 目次

- [目的](#目的)
- [アーキテクチャ](#アーキテクチャ)
- [技術スタック](#技術スタック)
- [ロードマップ](#ロードマップ)
- [最終ゴール](#最終ゴール)
- [Documents](#documents)

---

## 目的

本プロジェクトでは、Ruby on Rails の基礎から AWS 上での運用までを実際に構築しながら学習する

特に、単にアプリケーションをデプロイするだけではなく、SRE の立場で以下を実践することを目的とする

- Ruby / Ruby on Rails の基礎理解
- Rails アプリケーションの開発
- Docker によるコンテナ化
- ECS Fargate へのデプロイ
- Terraform による AWS インフラの IaC 化
- 既存 AWS リソースの棚卸し・Terraform 管理化
- Terraform Remote State を利用した複数人での IaC 運用
- CI/CD によるアプリケーション・インフラのデプロイ自動化
- インフラ構成・設定のレビュー
- CloudWatch を利用した監視・可観測性の整備
- Slack を利用した障害通知
- ECS Fargate の Right Sizing / Auto Scaling
- AWS コストの可視化・最適化
- 障害発生時のトラブルシューティング
- インフラ改善サイクルの実践
- AI ツールを利用した既存 AWS 環境の IaC 化検証

---

## アーキテクチャ

最終的に以下のような構成を目指す

```text
      Internet
          │
          ▼
         ALB
          │
          ▼
     ECS Fargate
  ┌─────────────────┐
  │ Ruby on Rails   │
  │ Puma / Thruster │
  └────────┬────────┘
           │
           ▼
      Amazon RDS
      PostgreSQL
```
```text
ALB / ECS / RDS
      │
      │ Metrics / Logs
      ▼
Amazon CloudWatch
├── Dashboard
├── Logs
└── Alarm
      │
      ▼
Amazon SNS
      │
      ▼
Amazon Q Developer
in chat applications
      │
      ▼
Slack
```

AWS インフラは Terraform で管理する

最終的にはアプリケーションとインフラで CI/CD Pipeline を分離し、  
Terraform State は Remote Backend で管理する

---

## 技術スタック

### アプリケーション

- Ruby
- Ruby on Rails
- PostgreSQL
- Puma
- Thruster

### インフラ

- AWS
  - VPC
  - ALB
  - ECS Fargate
  - ECR
  - RDS
  - CloudWatch
  - SNS
  - Secrets Manager
  - IAM
  - Amazon Q Developer in chat applications
- Docker
- Terraform

### CI/CD / Operations

- GitHub
- GitHub Actions
- Slack
- Kiro

---

# ロードマップ

## Phase 1: Ruby / Rails 基礎

Ruby と Ruby on Rails の基本構造を理解する

主な学習対象：

- Ruby 基本文法
- MVC
- Routing
- Controller
- Model
- View
- Active Record
- Migration
- Rails Console
- Gem / Bundler

---

## Phase 2: Rails アプリケーション

簡単な CRUD アプリケーションを作成する

```text
Create
Read
Update
Delete
```

Rails → Active Record → PostgreSQL というデータアクセスの流れを理解する

---

## Phase 3: Docker / AWS

Rails アプリケーションをコンテナ化し、AWS 上で動作させる

```text
Rails
  ↓
Docker
  ↓
ECR
  ↓
ECS Fargate
  ↓
ALB
  ↓
RDS PostgreSQL
```

以下について理解する

- Docker Image / Container
- ECR Image Tag
- ECS Cluster / Service / Task Definition / Task
- Fargate
- ALB / Target Group
- Security Group
- Private Subnet
- VPC Endpoint
- Secrets Manager
- Rails → RDS 接続

---

## Phase 4: Terraform

Terraform の基本操作を学び、AWS インフラを IaC で管理する

主な操作：

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform destroy
terraform import
```

以下についても検証する

- Terraform State
- Variable / Output
- Resource Dependency
- Existing Resource Import
- Drift Detection
- Brownfield 環境の Terraform 管理化

既存 AWS リソースを Terraform 管理へ取り込み、

```text
terraform plan

No changes. Your infrastructure matches the configuration.
```

となる状態を目指す

---

## Phase 5: Monitoring / Observability

CloudWatch を利用して ALB / ECS / RDS の状態を可視化する

### Dashboard

主な監視対象：

```text
ALB
├── RequestCount
├── TargetResponseTime
├── HTTPCode_ELB_5XX_Count
└── Target Health

ECS
├── CPUUtilization
└── MemoryUtilization

RDS
├── CPUUtilization
├── DatabaseConnections
├── FreeableMemory
└── FreeStorageSpace
```

### Alarm

以下の異常を CloudWatch Alarm で検知する

- ECS CPU High
- ALB 5XX
- Target 5XX
- Target Health

通知経路：

```text
CloudWatch Alarm
      ↓
Amazon SNS
      ↓
Amazon Q Developer
in chat applications
      ↓
Slack
```

負荷試験・Task 停止・Rails HTTP 500 などを実際に発生させ、  
Alarm → Slack まで E2E で動作確認する

---

## Phase 6: Right Sizing / Auto Scaling

CloudWatch Metrics と負荷試験結果を利用して、  
ECS Fargate の CPU / Memory 設定を評価する

```text
Load Test
   ↓
CloudWatch Metrics
   ↓
CPU / Memory / ResponseTime
   ↓
Right Sizing
```

`hey` を利用して負荷を段階的に増加させ、  
1 Task あたりの性能特性を確認する

さらに ECS Service Auto Scaling を構築する

```text
Traffic ↑
   ↓
CPU Utilization ↑
   ↓
ECS Service Auto Scaling
   ↓
Task 1 → 2 → 3
   ↓
ALB Load Balancing
```

以下を検証する

- Target Tracking Scaling
- Scale Out
- Scale In
- Minimum / Maximum Task Count
- CPU Target Value
- Cooldown
- Auto Scaling 前後の性能比較
- 水平スケーリング / 垂直スケーリングの判断
- RDS Connection への影響

---

## Phase 7: インフラ構成レビュー / コスト最適化

構築した AWS 環境を SRE の立場からレビューする

確認例：

- このリソースは何のために存在するか
- 不要なリソースは存在しないか
- CPU / Memory は適切か
- Single Point of Failure はないか
- Security Group は適切か
- ログは取得されているか
- ログ保持期間は適切か
- Alarm は設定されているか
- Backup / Restore は考慮されているか
- AWS リソースと Terraform の状態は一致しているか
- 過剰なコストが発生していないか
- NAT Gateway / VPC Endpoint の選択は適切か

改善は以下のサイクルで実施する

```text
Metrics
   ↓
Analysis
   ↓
Hypothesis
   ↓
Terraform Change
   ↓
terraform plan
   ↓
terraform apply
   ↓
Metrics
```

---

## Phase 8: Security / Availability

本番運用を想定してセキュリティと可用性を確認する

検証候補：

- Route 53
- ACM
- ALB HTTPS Listener
- HTTP → HTTPS Redirect
- Security Group 最小権限
- IAM Role / Policy 最小権限
- Secrets Manager
- RDS Backup / Restore
- RDS Multi-AZ
- ECS Task の複数 AZ 配置
- Single Point of Failure の確認

必要に応じて WAF についても検討する

---

## Phase 9: Incident Simulation

意図的に障害を発生させ、  
SRE としてトラブルシューティングする

例：

- Rails HTTP 500
- ECS Task 異常終了
- ALB Health Check Failure
- RDS 接続エラー
- Security Group 設定ミス
- CPU / Memory 高負荷
- DB Connection Pool 枯渇
- Migration Failure

障害について、

```text
Detect
 ↓
Investigate
 ↓
Identify
 ↓
Recover
 ↓
Prevent
```

まで実践する

障害発生時に、

```text
Slack Alert
   ↓
CloudWatch Dashboard
   ↓
CloudWatch Logs
   ↓
AWS Resource
   ↓
Root Cause
```

と調査できる状態を目指す

---

## Phase 10: Terraform Remote State / Team Operation

複数人で Terraform を管理することを想定し、  
Local State から Remote State へ移行する

検証内容：

- S3 Remote Backend
- State の環境分離
- State Lock
- State の暗号化
- Terraform State に含まれる機密情報の確認
- dev / stg / prd の環境分離
- tfvars の管理方法
- Secrets と非 Secret パラメータの分離

```text
Developer A ─┐
             │
Developer B ─┼── Terraform ── S3 Remote State
             │
CI/CD ───────┘
```

---

## Phase 11: CI/CD

アプリケーションとインフラで CI/CD Pipeline を分離する

### Application Pipeline

```text
Rails Change
    ↓
Test
    ↓
Docker Build
    ↓
Git SHA Tag
    ↓
ECR Push
    ↓
Task Definition Revision
    ↓
ECS Deploy
```

### Infrastructure Pipeline

```text
Terraform Change
      ↓
terraform fmt
terraform validate
terraform plan
      ↓
Pull Request Review
      ↓
Merge / Approval
      ↓
terraform apply
      ↓
AWS
```

GitHub Actions から AWS への認証には、  
可能な限り Access Key を保存せず OIDC + IAM Role を利用する

---

## Phase 12: Brownfield IaC / Kiro

既存 AWS 環境がコンソール中心で構築されている状況を想定し、  
既存環境から Terraform を作成する方法を検証する

```text
Existing AWS Environment
          ↓
         Kiro
          ↓
Terraform Draft
          ↓
Human Review
          ↓
Missing Resources / Dependencies
          ↓
Terraform Completion
          ↓
terraform import / plan
```

特に以下を確認する

- VPC / ALB / ECS / RDS などの抽出
- IAM Role / Policy の抽出
- AWS が自動生成したリソースの扱い
- Resource Dependency
- Environment 固有値
- Secret の扱い
- Terraform 生成漏れ
- `terraform plan` との差分

最終的に、

**手動で構築した Terraform と Kiro が既存 AWS 環境から生成した Terraform を比較する**

また、

```text
Production
   ↓
Existing Resources → Terraform 化
   ↓
Parameterize
   ↓
Staging
```

という Brownfield → IaC → 別環境構築の流れを検証する

---

# 最終ゴール

本プロジェクトの最終ゴールは、単に Rails や Terraform の使い方を学ぶことではなく、  
**Rails アプリケーションが稼働する AWS インフラを SRE の立場から理解し、評価・改善・運用できる状態になること**を目指す

さらに、

```text
Build
 ↓
Observe
 ↓
Detect
 ↓
Investigate
 ↓
Improve
 ↓
Automate
```

という SRE の改善サイクルを一通り経験する

最終的に、ハンズオンで得た知識を整理して、  
**「SRE としての AWS インフラチェック観点リスト」** を作成する

チェック観点には以下を含める予定

- Architecture
- Availability
- Reliability
- Monitoring / Observability
- Performance
- Security
- Cost
- Backup / Disaster Recovery
- IaC / Change Management
- Deployment / CI/CD
- Terraform State Management
- Application / Infrastructure Dependency
- Incident Response

このチェックリストを、新しい AWS 環境を確認するときの実践的なレビュー基準として利用できる状態を目指す

---

## Documents

- [01. Ruby on Rails 基礎](docs/01_rails_basics.md)
- [02. Rails AWS 基本構成](docs/02_rails_aws_architecture.md)
- [03. ECS / Rails Observability](docs/03_observability.md)

---
