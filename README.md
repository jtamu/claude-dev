# claude-dev
Claude CodeベースのAI開発者

## 使い方

### 起動

```bash
./start_dev.sh [起動数]
```

- 引数に起動するインスタンス数を指定します（デフォルト: `1`）
- 指定した数だけ `claude-dev-1`, `claude-dev-2`, ... と連番でcomposeプロジェクトが起動します

例:

```bash
# 1つだけ起動
./start_dev.sh

# 3つ起動（claude-dev-1, claude-dev-2, claude-dev-3）
./start_dev.sh 3
```

### Claude Code の初回セットアップ（認証情報）

認証情報は `claude-home` ボリュームに永続化されます。**初回のみ**、次のいずれかでボリュームに認証情報を入れます。

- **既にホストに `~/.claude/.credentials.json` がある場合**（1 回だけコピー）:
  ```bash
  docker compose -p claude-dev-1 run --rm ui sh -c 'mkdir -p /home/dev/.claude && cat > /home/dev/.claude/.credentials.json' < ~/.claude/.credentials.json
  ```
- その後、通常どおり `./start_dev.sh` で起動すれば Claude が利用できます。2 回目以降は再設定不要です。

## Codex を使う場合（サブスクリプション）

設定画面の「Agents」で Codex を有効にするには、ChatGPT アカウント（Plus/Pro/Team 等）で一度ログインしてください。

1. コンテナを起動した状態で、**初回のみ**次のコマンドを実行する:
   ```bash
   docker compose -p claude-dev-1 run --rm -it ui codex login --device-auth
   ```
2. 表示された URL をブラウザで開き、コードを入力して ChatGPT でサインインする。
3. ログインが完了したら、WebUI の設定 → Agents で Codex が「接続済み」になっていることを確認する。

認証情報は `codex-home` ボリュームに保存されるため、2 回目以降は再ログイン不要です。すでにホストで `codex login` 済みの場合は、`docker-compose.yml` の `codex-home:/home/dev/.codex` を `~/.codex:/home/dev/.codex` に差し替えると、ホストの認証をそのまま使えます。

## レスポンスが返ってこない場合

チャットで「Thinking...」「Processing...」のまま応答が返らない場合は [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) を参照してください。
