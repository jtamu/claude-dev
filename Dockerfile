FROM node:20-bookworm

RUN apt update && apt install -y vim curl

# Docker Compose Plugin (公式リポジトリ経由)
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y docker-ce-cli docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# 非rootユーザー作成とワークスペース（UID/GID 1001: ベースイメージの1000と衝突回避）
# .claude を事前作成して dev 所有にしないと、credentials.json マウント時に
# 親ディレクトリが root で作られ project-config.json の書き込みで EACCES になる
RUN groupadd --gid 1001 dev \
    && useradd --uid 1001 --gid 1001 --create-home --shell /bin/bash dev \
    && mkdir -p /home/dev/workspace /home/dev/.claude \
    && chown -R dev:dev /home/dev
WORKDIR /home/dev/workspace
USER dev

# プロジェクト固有の言語ランタイム（例: Python, Go など）
# RUN apt-get install -y python3 python3-pip ...

# エントリポイントスクリプト（後述）
#COPY entrypoint.sh /entrypoint.sh
#CMD ["/entrypoint.sh"]

# Claude Code WebUI

EXPOSE 3001

# レスポンスが返らない不具合の緩和のためバージョン固定（issue #336, #245 等）
ENTRYPOINT ["npx", "@siteboon/claude-code-ui@1.16.3"]
