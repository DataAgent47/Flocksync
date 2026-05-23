# Flocksync Backend 

This guide explains how to set up the Flocksync backend for development.

### 1. Clone the repo

```bash
git clone https://github.com/DataAgent47/Flocksync.git Flocksync
cd Flocksync/flocksync-backend
npm install
```
### 2. Supabase Setup

Supabase is needed to store images and files for the app.

Create an `.env` file with the following contents (get these values from your Supabase project Settings → API):

```
SUPABASE_URL=https://<the-long-string-of-letters-in-the-url>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
SUPABASE_SERVICE_ROLE_KEY=<service-key>
```

### 3. Firebase Setup

1. Go to the [Firebase Console](https://console.firebase.google.com/) and open your project.
2. Click the **gear icon** in the top-left corner and select **Project Settings**.
3. Navigate to the **Service Accounts** tab.
4. Click **Generate New Private Key**.
5. Download the JSON file.
6. **Rename** the file to `serviceAccountKey.json`.
7. Place the file in your backend project folder (e.g., `flocksync-backend/`).

> [!NOTE]
> You can embed the `serviceAccountKey.json` as an environment variable (which might make deploying easier):
>
> ```bash
> echo "FIREBASE_SERVICE_ACCOUNT_JSON=$(jq -c . serviceAccountKey.json)" >> .env
> ```

### 4. Running the server

```bash
npm run dev
```

### 5. Verify

- Test API: `curl http://localhost:5050/`

## Optional env variables

- `PORT=5050`
- `FRONTEND_ORIGIN=http://localhost:3000,http://123.123.123.123:1234`
- `MAP_USER_AGENT=Flocksync/1.0 (contact: help@hos.sh)`


For local development, the backend also allows `localhost` and `127.0.0.1` on any port, as Flutter randomizes its port.
