# Chat by Swipelab

A breath of fresh air in communications. 

# Features

- [x] Registration
- [x] Login
- [x] Push Notification (Firebase)
- [x] VoIP (WebRTC)
- [ ] E2E Encryption
- [x] Rooms
    - [x] Name
    - [ ] Members
    - [ ] Permissions
- [ ] Messages
    - [x] Text
    - [ ] Blob
    - [ ] Image
    - [ ] Video
    - [ ] Audio    
- [x] Profile
    - [x] Username
    - [ ] Avatar


# Build Server

```sh
cd server
docker build -t chat-server .
```

# Self Host

```sh
// after you build the server
docker compose --env-file ./volumes/private/production.env up -d
```


Sample `env` file `./volumes/private/production.env`
```env
POSTGRES_PASSWORD=postgres
POSTGRES_USER=postgres
POSTGRES_DB=chat_db
AUTH_KEY=super secret key! really really!
```