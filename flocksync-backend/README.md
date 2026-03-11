# Flocksync Backend — Developer First-Time Setup

This guide explains how to set up the Flocksync backend for development on a Mac.

---

## 1. MongoDB Setup

### Install MongoDB (Mac)

```bash
brew tap mongodb/brew
brew install mongodb-community
brew install mongosh
brew services start mongodb-community
```

### Clone the repo

`git clone https://github.com/DataAgent47/Flocksync.git`

`cd Group-2/flocksync-backend`

`npm install`

### Create local database

`mongosh`
`use <database-name>`

for docker and docker-compose:
`docker compose -f docker-mongo.yml config` 

in the .env for local development:
`MONGO_URI=mongodb://localhost:27017/flocksync`

### Firebase Setup

1. Go to the [Firebase Console](https://console.firebase.google.com/) and open your project.
2. Click the **gear icon** in the top-left corner and select **Project Settings**.
3. Navigate to the **Service Accounts** tab.
4. Click **Generate New Private Key**.
5. Download the JSON file.
6. **Rename** the file to `serviceAccountKey.json`.
7. Place the file in your backend project folder (e.g., `flocksync-backend/`).

### Running the server

```bash
docker compose -f docker-mongo.yml up -d
npm run dev
```



### 4. Verify

- Check container health:
	`docker ps --filter name=flocksync-mongodb`
- View Mongo logs:
	`docker logs flocksync-mongodb --tail 100`
- Test API:
	`curl http://localhost:5000/`

### 5. Stop / reset

- Stop container:
	`docker compose -f docker-compose.mongo.yml down`
- Stop and remove DB data volume:
	`docker compose -f docker-compose.mongo.yml down -v`
