import express from 'express'
import cors from 'cors'
import dotenv from 'dotenv'
import mongoose from 'mongoose'
import admin from 'firebase-admin'
import serviceAccount from './serviceAccountKey.json' assert { type: 'json' }

dotenv.config()
const app = express()

// middleware
app.use(express.json())
app.use(
   cors({
      // change localhost later to match frontend if needed
      origin: 'http://localhost:3000',
      credentials: true,
   }),
)

// firebase admin init
admin.initializeApp({
   credential: admin.credential.cert(serviceAccount),
})

// using mongodb
mongoose
   .connect(process.env.MONGO_URI)
   .then(() => console.log('MongoDB connected'))
   .catch((err) => console.error('MongoDB connection error:', err))

// first get request
app.get('/', (req, res) => res.send('Hello World'))

const PORT = process.env.PORT || 5000
app.listen(PORT, () => console.log(`Server running on port ${PORT}`))
