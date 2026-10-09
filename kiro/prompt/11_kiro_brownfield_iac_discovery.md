あなたは、既に稼働しているAWS環境を解析し、
Terraformによって別環境へ再構築する担当です。

## 検証の目的

既存のRails + AWS環境をAWS APIから解析し、
既存のTerraformコードを一切参照せずにTerraformを生成してください。

最終的には、生成したTerraformを使って
同一AWSアカウント・同一リージョン内の別環境を構築し、

https://kiro.saxon-aws-lab.click/tasks

へHTTPSでアクセスして、
既存環境と同じRails Task画面が正常表示され、
HTTP 200になることを目標とします。

単にTerraformコードを生成するだけではなく、

AWS実環境の解析
→ Resource / Dependency把握
→ Terraform生成
→ fmt / validate / plan
→ Error / Difference分析
→ Terraform修正
→ Human Review
→ Deploy
→ End-to-End Validation

までを対象とします。


## 重要な制約

以下は必ず守ってください。

1. 既存Terraformコードを参照しないでください。
   既存の rails-aws-sre-lab Repositoryや、
   人間が作成したTerraformコードを検索・参照・推測元として利用しないでください。

2. AWS実環境を唯一のInfrastructure Sourceとして解析してください。

3. 解析対象リージョンは ap-northeast-1 です。

4. 現在稼働中の既存AWS環境を変更・削除しないでください。

5. 現在付与されているAWS権限は調査用のRead-only権限です。
   作成・変更・削除操作を試行しないでください。

6. 新しく構築する環境は既存環境とは分離してください。
   - 別VPC
   - 別Subnet
   - 別Security Group
   - 別ECS / ALB / RDS等
   - 別Terraform State
   - Resource名は既存環境と衝突させない
   - 必要に応じて "kiro" を名前に含める

7. Applyは実行しないでください。
   Human Reviewと明示的な承認があるまで、
   terraform apply / destroy やAWSリソース変更操作は禁止します。

8. 意図しないdestroy / replaceがPlanに含まれる場合は、
   Applyを提案せず、原因を分析してください。

9. SecretやCredentialの値を取得・表示・Terraformへハードコードしないでください。


## 既存環境の解析

まず、Terraformの生成を開始する前に、
ap-northeast-1 の既存AWS環境を可能な限り調査してください。

Webアプリケーションの動作に関係する以下を中心に確認してください。

- VPC
- Public / Private Subnet
- Route Table
- Internet Gateway
- VPC Endpoint
- Security Group
- IAM Role / Policy
- ECR
- ECS Cluster
- ECS Task Definition
- ECS Service
- Application Load Balancer
- Target Group
- Listener
- RDS PostgreSQL
- DB Subnet Group
- Secrets Manager
- CloudWatch Logs
- Route 53
- ACM

これ以外にもアプリケーション動作に必要なResourceがあれば追加してください。


## 調査結果として最初に提示する内容

Terraform生成に進む前に、以下を整理してください。

### 1. Resource Inventory
検出した主要AWS Resourceの一覧。

Resourceごとに可能であれば以下を示してください。

- AWS Service
- Resource名
- Resource ID / ARN
- Region / AZ
- 主要Parameter
- 関連Resource

### 2. Resource Dependencies
Resource同士の依存関係を整理してください。

例:

Internet
→ Route 53
→ ALB
→ Target Group
→ ECS Service
→ ECS Task
→ RDS

のように、Application RequestがどのResourceを通るか説明してください。

### 3. Architecture
現在のAWS環境全体のArchitectureを文章またはASCII Diagramで説明してください。

### 4. IaC化対象
別環境で同じRails Applicationを動作させるために、
Terraform化が必要なResourceを整理してください。

各Resourceについて、

- 必須
- 条件付きで必要
- 再利用可能
- IaC化不要

のどれに該当するか説明してください。

### 5. 不明点・不足情報
AWS APIだけでは判断できない内容、
追加確認が必要な内容、
推測している内容を明示してください。

推測と確認済み情報を混同しないでください。


## Terraform生成方針

調査内容をHuman Reviewした後、
明示的に「Terraform生成へ進んでよい」と指示された場合のみ生成を開始してください。

Terraformは新しいRepository内に作成してください。

以下のようにResourceの責務ごとにファイルを分割してください。

versions.tf
providers.tf
variables.tf
outputs.tf
network.tf
security_group.tf
iam.tf
ecr.tf
ecs.tf
alb.tf
rds.tf
secrets.tf
route53.tf
acm.tf
monitoring.tf

必要に応じてファイルは追加・整理して構いません。


## Terraform設計方針

- Hard-codeすべきでない値はvariables.tfへ分離する
- 利用価値のある値はoutputs.tfへ定義する
- Resource間はID/ARNの直接ハードコードではなくTerraform Referenceを利用する
- Secret値をコードに含めない
- IAMはLeast Privilegeを意識する
- Security Groupは必要最小限の通信だけ許可する
- Existing EnvironmentのResource IDを新環境用Resourceとして直接利用しない
- Existing Terraform Stateを利用しない
- 新環境専用Stateを使用する
- Provider versionを明示する
- Terraformの可読性・保守性を考慮する


## Terraform生成後

生成後は以下を順番に実施してください。

terraform fmt
terraform validate
terraform plan

Errorが発生した場合は、
すぐに人間へ修正方法を尋ねるのではなく、
まず自身で以下を行ってください。

- Error内容の解析
- 原因候補の提示
- AWS実環境との比較
- Provider Schemaの確認
- Dependencyの確認
- IAM Permissionの確認
- Terraformコードの修正
- 再度 fmt / validate / plan

ただし、AWSリソースへの変更操作や
terraform apply はHuman Approvalなしでは実行しないでください。


## Plan Review

terraform plan後は以下をHuman Review用に整理してください。

- AddされるResource
- ChangeされるResource
- DestroyされるResource
- ReplaceされるResource
- IAM変更
- Security Group変更
- Network変更
- RDS変更
- Costに影響しそうなResource
- 既存環境との差
- 意図しない可能性がある変更
- Apply前に人間が確認すべきポイント


## Human Interventionの記録

検証中、人間から追加情報・修正・判断を受けた場合は、
その都度Human Interventionとして記録してください。

以下を残してください。

- 何が原因で介入が必要だったか
- Kiroだけでは何ができなかったか
- 人間が提供した情報
- 人間が直接修正したコードがあるか
- その介入後にKiroが何を実行したか


## 現時点での指示

まずはTerraformを生成しないでください。

最初の作業として、
ap-northeast-1 の既存AWS環境をRead-onlyで解析し、

1. Resource Inventory
2. Resource Dependencies
3. Architecture
4. IaC化対象
5. 不明点・不足情報

を整理して提示してください。

AWS Resourceへの作成・変更・削除操作は行わないでください。