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

## レスポンスが返ってこない場合

チャットで「Thinking...」「Processing...」のまま応答が返らない場合は [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) を参照してください。
