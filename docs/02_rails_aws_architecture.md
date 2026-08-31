<!-- omit in toc -->
# Rails AWS 基本構成

- [概要](#概要)
- [アーキテクチャ](#アーキテクチャ)
- [コンテナ構成](#コンテナ構成)
- [ECS](#ecs)
- [VPC Endpoint](#vpc-endpoint)
- [Secrets](#secrets)
- [データベース](#データベース)
- [ログ](#ログ)
- [Terraform](#terraform)
- [使用技術](#使用技術)

---

## 概要

Rails アプリケーションを Docker Image 化し、  
Amazon ECS / AWS Fargate 上で実行する

データベースには Amazon RDS for PostgreSQL を使用し、  
Application Load Balancer を経由して外部からアクセスする

---

## アーキテクチャ

```text
Internet
    |
    | HTTP :80
    v
Application Load Balancer
    |
    | HTTP :8080
    v
Target Group
    |
    v
ECS Service
    |
    v
Fargate Task
    |
    | Thruster :8080
    |     |
    |     v
    | Puma :3000
    |     |
    |     v
    | Rails
    |
    | PostgreSQL :5432
    v
Amazon RDS
```

---

## コンテナ構成

Rails アプリケーションは Docker Image としてビルドし、
Amazon ECR に保存する

ECS Task Definition から ECR Image を参照し、
AWS Fargate 上でコンテナを実行する

コンテナは非 root ユーザーで実行するため、
Thruster の HTTP ポートには 8080 を使用する

```text
ALB :80
  ↓
Fargate :8080
  ↓
Thruster :8080
  ↓
Puma :3000
  ↓
Rails
```

---

## ECS

ECS Service が Task Definition をもとに Fargate Task を起動し、  
指定した desired count を維持する

起動した Task の Private IP は Target Group に自動登録される

```text
ECS Service
  ↓
Task Definition
  ↓
Fargate Task
  ↓
Target Groupへ登録
```

---

### ネットワーク

ALB は Public Subnet、
ECS Task と RDS は Private Subnet に配置する

ECS Task には Public IP を付与しない

```
Internet
   ↓
Public Subnet
   └─ ALB
        ↓
Private Subnet
   ├─ ECS Task
   └─ RDS
```

Security Group は以下の通信のみ許可する

- Internet → ALB :80
- ALB → ECS :8080
- ECS → RDS :5432
- ECS → VPC Endpoint :443

---

## VPC Endpoint

ECS Task は NAT Gateway を使用せず、
VPC Endpoint 経由で AWS サービスへアクセスする

- Amazon ECR API
- Amazon ECR DKR
- Amazon S3
- CloudWatch Logs
- AWS Secrets Manager

---

## Secrets

RDS のパスワードと Rails Master Key は
AWS Secrets Manager で管理する

ECS Task Execution Role に
secretsmanager:GetSecretValue を許可し、  
Task 起動時に環境変数としてコンテナへ渡す

---

## データベース

Amazon RDS for PostgreSQL を Private Subnet に配置する

DB Subnet Group には複数 AZ の Private Subnet を登録するが、  
学習環境では multi_az = false として Single-AZ 構成とする

---

## ログ

Rails コンテナのログは awslogs Log Driver を使用して
CloudWatch Logs に送信する

また、ECS Cluster では Container Insights を有効化する

---

## Terraform

AWS インフラは Terraform で管理する

主な構成ファイル：

```text
terraform/
├── network.tf
├── security_group.tf
├── ecr.tf
├── ecs.tf
├── iam.tf
├── alb.tf
├── rds.tf
└── secrets.tf
```

## 使用技術

- Rails 8
- PostgreSQL
- Docker
- Amazon ECR
- Amazon ECS
- AWS Fargate
- Application Load Balancer
- Amazon RDS for PostgreSQL
- AWS Secrets Manager
- Amazon CloudWatch
- Terraform

---
