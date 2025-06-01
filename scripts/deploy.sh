cd server
docker build -t chat-server .
cd ..
docker compose --env-file ./volumes/private/production.env up -d