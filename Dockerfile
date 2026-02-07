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

WORKDIR /workspace

# Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# プロジェクト固有の言語ランタイム（例: Python, Go など）
# RUN apt-get install -y python3 python3-pip ...

# エントリポイントスクリプト（後述）
#COPY entrypoint.sh /entrypoint.sh
#CMD ["/entrypoint.sh"]

# Claude Code WebUI

EXPOSE 3001

CMD ["npx", "@siteboon/claude-code-ui"]
