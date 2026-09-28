# syntax=docker/dockerfile:1.7

FROM denoland/deno:2.5.2

WORKDIR /app

USER root
RUN mkdir -p /data/levels && chown -R deno:deno /data

COPY --chown=deno:deno deno.json deno.lock main.ts ./
COPY --chown=deno:deno modules ./modules
COPY --chown=deno:deno public ./public

USER deno

RUN deno cache --lock=deno.lock main.ts \
	&& deno eval \
		'import { Database } from "@db/sqlite"; const db = new Database("/tmp/sqlite-prewarm.db"); db.close(); await Deno.remove("/tmp/sqlite-prewarm.db");'

ENV PORT=3000 \
	DB_PATH=/data/database.db \
	DATA_FOLDER_PATH=/data/levels \
	CREATE_DATA_FOLDER=true \
	USE_PUBLIC_FOLDER=true \
	PUBLIC_FOLDER_PATH=/app/public \
	USE_TEST_UI=true \
	USE_ADMIN_UI=false \
	USE_GITHUB_AUTH=false \
	USE_TURNSTILE=false \
	USE_OPENAI_MODERATION=false \
	USE_REPORTING=false \
	USE_UPLOAD_LOGGING=false \
	DISCORD_PROVIDER_ENABLED=false \
	BLUESKY_PROVIDER_ENABLED=false \
	USE_POSTHOG_ANALYTICS=false \
	GAME_URL=http://localhost:8080 \
	BACKEND_URL=http://localhost:3000 \
	ALLOWED_ORIGINS=http://localhost:8080,http://127.0.0.1:8080

EXPOSE 3000
VOLUME ["/data"]

HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=3 \
	CMD ["deno", "eval", "--allow-net=127.0.0.1:3000", "const r = await fetch('http://127.0.0.1:3000/api/health'); if (!r.ok) Deno.exit(1);"]

CMD ["deno", "run", "-P", "main.ts"]
