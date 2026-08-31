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
- インフラ構成・設定のレビュー
- CloudWatch を利用した監視・可観測性の整備
- AWS コストの可視化・最適化
- 障害発生時のトラブルシューティング
- インフラ改善サイクルの実践

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
│      Puma       │
└─────────────────┘
   │          │
   │          └── CloudWatch
   ▼
Amazon RDS
PostgreSQL
```

AWS インフラは Terraform で管理する

---

## 技術スタック

### アプリケーション

- Ruby
- Ruby on Rails
- PostgreSQL
- Puma

### インフラ

- AWS
  - VPC
  - ALB
  - ECS Fargate
  - ECR
  - RDS
  - CloudWatch
  - Secrets Manager
  - IAM
- Docker
- Terraform

---

## ロードマップ

### Phase 1: Ruby / Rails 基礎

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

### Phase 2: Rails アプリケーション

簡単な CRUD アプリケーションを作成する

```text
Create
Read
Update
Delete
```

Rails → Active Record → PostgreSQL というデータアクセスの流れを理解する

### Phase 3: Docker / AWS

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
```

### Phase 4: Terraform

Terraform の基本操作を学び、AWS インフラを IaC で管理する

主な操作：

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform destroy
```

以下についても検証する

- Terraform State
- Remote Backend
- Module
- Variable / Output
- Resource dependency
- Existing Resource Import
- Drift Detection

### Phase 5: インフラ構成レビュー

構築した AWS 環境を、SRE の立場からレビューする

例：

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

### Phase 6: コスト最適化

CloudWatch Metrics や AWS の料金情報を確認しながら、インフラを改善する

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

### Phase 7: インシデントシミュレーション

意図的に障害を発生させ、SRE としてトラブルシューティングする

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

---

## 最終ゴール

本プロジェクトの最終ゴールは、単に Rails や Terraform の使い方を学ぶことではなく、  
**Rails アプリケーションが稼働する AWS インフラを SRE の立場から理解し、評価・改善・運用できる状態になること** を目指す

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
- Deployment
- Application / Infrastructure Dependency
- Incident Response

このチェックリストを、新しい AWS 環境を確認するときの実践的なレビュー基準として利用できる状態を目指す

---

## Documents

- [01. Ruby on Rails 基礎](docs/01_rails_basics.md)
- [02. Rails AWS 基本構成](docs/02_rails_aws_architecture.md)

---
