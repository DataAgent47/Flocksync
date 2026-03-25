# Flocksync Backend — Developer First-Time Setup

This guide explains how to set up the Flocksync backend for development on a Mac.

> [!NOTE]
> If you just want to complete onboarding (and use the maps api), just skip the MongoDB steps.

---

## MongoDB Setup

### 1. Install MongoDB (Mac)

```bash
brew tap mongodb/brew
brew install mongodb-community
brew install mongosh
brew services start mongodb-community
```

### 2. Clone the repo

`git clone https://github.com/DataAgent47/Flocksync.git`

`cd Group-2/flocksync-backend`

`npm install`

### 3. Create local database

`mongosh`
`use <database-name>`

for docker and docker-compose:
`docker compose -f docker-mongo.yml config` 

in the .env for local development:
`MONGO_URI=mongodb://localhost:27017/flocksync`

### 4. Firebase Setup

1. Go to the [Firebase Console](https://console.firebase.google.com/) and open your project.
2. Click the **gear icon** in the top-left corner and select **Project Settings**.
3. Navigate to the **Service Accounts** tab.
4. Click **Generate New Private Key**.
5. Download the JSON file.
6. **Rename** the file to `serviceAccountKey.json`.
7. Place the file in your backend project folder (e.g., `flocksync-backend/`).

### 5. Running the server

```bash
# Run MongoDB, docker command as example:
docker compose -f docker-mongo.yml up -d
# Run npm
npm run dev
```

### 6. Verify

- Check container health:
	`docker ps --filter name=flocksync-mongodb`
- View Mongo logs:
	`docker logs flocksync-mongodb --tail 100`
- Test API:
	`curl http://localhost:5000/`

### 7. Stop / reset

- Stop container:
	`docker compose -f docker-compose.mongo.yml down`
- Stop and remove DB data volume:
	`docker compose -f docker-compose.mongo.yml down -v`

## Optional env variables

- `PORT=5000` 
- `FRONTEND_ORIGIN=http://localhost:3000,http://123.123.123.123:1234`
- `MAP_USER_AGENT=Flocksync/1.0 (contact: help@hos.sh)`

For local development, the backend also allows `localhost` and `127.0.0.1` on any port, as Flutter randomizes its port. 