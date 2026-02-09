# トラブルシューティング: レスポンスが返ってこない

## 現象

チャットで「こんにちは」等を送信すると、**「Thinking...」「Processing... (55s)」** のまま長時間応答が返らない。

## 調査結果（想定原因）

Claude Code UI（`@siteboon/claude-code-ui`）の GitHub で、同様の事象が複数報告されています。

| Issue | 内容 |
|-------|------|
| [#336](https://github.com/siteboon/claudecodeui/issues/336) | Processing が 1335 秒続く・初回クエリが返らない。Esc/Stop が効かない。**メンテナより「リファクタで修正中」との回答あり（PR #374）** |
| [#245](https://github.com/siteboon/claudecodeui/issues/245) | **フロントが送る WebSocket のメッセージタイプが誤り**で、サーバが `claude-command` を処理せず「Thinking...」のままになる |
| [#263](https://github.com/siteboon/claudecodeui/issues/263) | UI チャットは極端に遅いが、同一環境の Shell / Claude Code CLI は速い |

**想定される主因:**

1. **UI の既知バグ**  
   フロントのメッセージ形式や WebSocket 周りの不具合で、バックエンドがリクエストを正しく処理していない可能性。
2. **バージョン**  
   古いバージョンで上記バグを踏んでいる、または逆に最新で別の不具合の可能性。
3. **Docker 内からの Anthropic API**  
   コンテナのネットワーク・DNS・プロキシの影響で API が遅い／タイムアウトしている可能性（CLI の Issue #1089, #13657 等）。

## 推奨対処（順に試す）

### 1. Claude Code UI を 1.16.3 に固定して再ビルド

UI に「Bump to 1.16.3 Update available」と出ている場合は、そのバージョンに合わせてイメージを再ビルドしてください。

```bash
# イメージの再ビルド・再起動
docker compose -p claude-dev-1 build --no-cache ui && docker compose -p claude-dev-1 up -d ui
```

Dockerfile でバージョン固定する場合は、次のように変更します。

```dockerfile
# 例: 1.16.3 に固定
CMD ["npx", "@siteboon/claude-code-ui@1.16.3"]
```

### 2. コンテナログでエラー確認

UI コンテナのログに WebSocket や API のエラーが出ていないか確認します。

```bash
docker compose -p claude-dev-1 logs -f ui
```

- `[WARN] Unknown message type:` → フロントのメッセージ形式の問題（#245 系）
- `ECONNRESET` / `timeout` / `API` → ネットワークまたは Anthropic API 接続の問題

### 3. コンテナ内で Claude Code CLI を直接実行

同じ環境から Anthropic API が使えているか確認します。

```bash
docker compose -p claude-dev-1 exec ui bash
# コンテナ内
claude "こんにちは"
```

- ここで即応答が返る → API は通っているので、**UI 側の不具合の可能性が高い**（上記 1 やバージョン・リファクタ PR の取り込みを検討）。
- ここでも遅い／タイムアウト → **ネットワーク／API キー／プロキシ**を疑う。

### 4. 認証情報とネットワークの確認

- `~/.claude/.credentials.json` が正しくマウントされているか  
  - `docker compose exec ui cat /home/dev/.claude/.credentials.json` で中身の有無・形式を確認。
- コンテナから外部への疎通  
  - `docker compose exec ui curl -sI https://api.anthropic.com` で HTTP 応答やタイムアウトを確認。

### 5. 暫定運用: Shell タブで会話する

Issue #263 のように、**チャットではなく Shell タブで `claude "メッセージ"` を実行すると速い**という報告があります。  
レスポンスが返らない間は、Shell 経由で Claude Code を使う運用で回避できます。

### 6. 上流の修正を待つ

Issue #336 ではメンテナが「リファクタで修正中」と回答しており、[PR #374](https://github.com/siteboon/claudecodeui/pull/374) で対応予定です。  
定期的に `@siteboon/claude-code-ui` のリリースノートや issue を確認し、修正版が出たらバージョンを上げて再ビルドすることを推奨します。

## まとめ

- **「Processing のまま返ってこない」** は Claude Code UI の既知の不具合報告と一致しており、**UI 側のバグの可能性が高い**です。
- まず **UI を 1.16.3 に固定して再ビルド**し、**コンテナログ**と**コンテナ内での `claude` CLI** で原因を切り分けると効率的です。
- 必要に応じて **Shell タブで `claude` を実行**する運用で回避できます。
