/*
Terraform を動かすために S3 Backend が必要になるため、
Backend用 Bucket はあらかじめ AWS CLI で作成する

・バケット作成

aws s3api create-bucket \
  --bucket rails-aws-sre-lab-terraform-state \
  --region ap-northeast-1 \
  --create-bucket-configuration LocationConstraint=ap-northeast-1

・Versioning を有効

aws s3api put-bucket-versioning \
  --bucket rails-aws-sre-lab-terraform-state \
  --versioning-configuration Status=Enabled

・Public Access Block を有効

aws s3api put-public-access-block \
  --bucket rails-aws-sre-lab-terraform-state \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

バケット作成後に以下を実行する

terraform init -migrate-state
*/

terraform {
  backend "s3" {
    bucket       = "rails-aws-sre-lab-terraform-state"
    key          = "terraform.tfstate"
    region       = "ap-northeast-1"
    use_lockfile = true

    encrypt = true
  }
}
