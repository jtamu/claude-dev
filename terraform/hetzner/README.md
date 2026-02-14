# Claude Dev - Hetzner Cloud Deployment

Hetzner CloudにClaude Dev環境をデプロイします。低コストで高性能なヨーロッパ拠点のクラウドです。

## 料金

| サーバータイプ | スペック | 月額 |
|---------------|----------|------|
| cx11 | 1 vCPU, 2GB, 20GB | €3.29 (~¥530) |
| **cx22** | 2 vCPU, 4GB, 40GB | €4.35 (~¥700) |
| cx32 | 4 vCPU, 8GB, 80GB | €7.69 (~¥1,240) |
| cax11 (ARM) | 2 vCPU, 4GB, 40GB | €3.29 (~¥530) |
| cax21 (ARM) | 4 vCPU, 8GB, 80GB | €5.49 (~¥890) |

**推奨:** cx22（x86）または cax11（ARM）

## 前提条件

1. Hetzner Cloud アカウント
2. Terraform >= 1.0

## セットアップ

### 1. API Tokenの取得

1. [Hetzner Cloud Console](https://console.hetzner.cloud) にログイン
2. プロジェクトを選択（または新規作成）
3. **Security** > **API Tokens** > **Generate API Token**
4. Read & Write 権限でトークンを生成

### 2. SSH鍵の準備

```bash
# 既存の鍵を使用するか、新規作成
ssh-keygen -t rsa -b 4096 -f ~/.ssh/hetzner_claude_dev
```

### 3. 変数ファイルを作成

```bash
cd terraform/hetzner
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` を編集:

```hcl
hcloud_token = "your-api-token-here"
location     = "fsn1"  # Falkenstein (cheapest)

projects = ["my-project"]

server_type = "cx22"  # €4.35/month

ssh_public_key_path  = "~/.ssh/hetzner_claude_dev.pub"
ssh_private_key_path = "~/.ssh/hetzner_claude_dev"

git_repo_url = "https://github.com/your-org/claude-dev.git"
```

### 4. デプロイ

```bash
terraform init
terraform plan
terraform apply
```

## 出力

```
servers = {
  "my-project" = {
    server_id   = 12345678
    ipv4        = "xxx.xxx.xxx.xxx"
    server_type = "cx22"
    location    = "fsn1"
    webui_url   = "http://xxx.xxx.xxx.xxx:3001"
  }
}

ssh_commands = {
  "my-project" = "ssh -i ~/.ssh/hetzner_claude_dev root@xxx.xxx.xxx.xxx"
}

monthly_cost_estimate = {
  server_type   = "cx22"
  cost_per_unit = "€4.35"
  instances     = 1
  total         = "1 x cx22"
}
```

## ロケーション

| コード | 場所 | 備考 |
|--------|------|------|
| fsn1 | Falkenstein, Germany | 最安・デフォルト |
| nbg1 | Nuremberg, Germany | |
| hel1 | Helsinki, Finland | |
| ash | Ashburn, USA | アメリカ拠点 |

日本からのレイテンシはヨーロッパ拠点で約250-300ms程度ですが、AI開発作業では許容範囲です。

## ARM (cax) vs x86 (cx)

| 項目 | ARM (cax) | x86 (cx) |
|------|-----------|----------|
| 価格 | より安い | やや高い |
| 互換性 | イメージ依存 | 高い |
| 性能 | 同等〜優れる | 安定 |

ARMを使う場合は `server_type = "cax11"` に変更してください。

## トラブルシューティング

### SSHに接続できない

1. ファイアウォール設定を確認
2. `allowed_ssh_cidrs` に自分のIPが含まれているか確認:
   ```bash
   curl ifconfig.me
   ```

### WebUIにアクセスできない

1. `allowed_app_cidrs` を確認
2. サービス状態を確認:
   ```bash
   ssh root@<IP>
   systemctl status claude-dev
   docker ps
   tail -f /var/log/user-data.log
   ```

### サーバー作成に失敗する

Hetznerのリソース制限に達している可能性があります。サポートに連絡してリミット引き上げを依頼してください。

## クリーンアップ

```bash
terraform destroy
```

## 参考リンク

- [Hetzner Cloud](https://www.hetzner.com/cloud)
- [Hetzner Cloud Terraform Provider](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs)
- [Hetzner Cloud Pricing](https://www.hetzner.com/cloud#pricing)
