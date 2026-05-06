import express from 'express'
import cors from 'cors'
import dotenv from 'dotenv'
// import mongoose from 'mongoose'
import admin from 'firebase-admin'
import serviceAccount from './serviceAccountKey.json' with { type: 'json' }
import axios from 'axios'
import { createClient } from '@supabase/supabase-js'
import multer from 'multer'
import sharp from 'sharp'

// TODO: add differentiation between account types, residents, management, application administrator

// OpenStreetMap Nominatim API configuration
const MAP_BASE_URL = 'https://nominatim.openstreetmap.org'
const DEFAULT_MAP_RESULT_LIMIT = 5
const MAX_MAP_RESULT_LIMIT = 10
const MAP_REQUEST_TIMEOUT_MS = 10000

// Init
dotenv.config()
const app = express()
const PORT = process.env.PORT || 3001
const allowedOrigins = (process.env.FRONTEND_ORIGIN || 'http://localhost:3000')
   .split(',')
   .map((origin) => origin.trim())
   .filter(Boolean)

const isLocalDevOrigin = (origin) => {
   try {
      const url = new URL(origin)

      return (
         (url.protocol === 'http:' || url.protocol === 'https:') &&
         (url.hostname === 'localhost' || url.hostname === '127.0.0.1')
      )
   } catch {
      return false
   }
}

const isAllowedOrigin = (origin) => {
   return !origin || allowedOrigins.includes(origin) || isLocalDevOrigin(origin)
}

const sendError = (res, statusCode, error) => {
   return res.status(statusCode).json({ error })
}

// middleware
app.use(express.json())
app.use(
   cors({
      origin: (origin, callback) => {
         if (isAllowedOrigin(origin)) {
            return callback(null, true)
         }

         return callback(new Error('Not allowed by CORS'))
      },
      credentials: true,
   }),
)
// multer for verification documents
// define constraints
// max 10mb
// only allow jpeg png and pdf
const upload = multer({
   storage: multer.memoryStorage(),
   limits: { fileSize: 10 * 1024 * 1024 },
   fileFilter: (req, file, cb) => {
      const allowedTypes = ['image/jpeg', 'image/png', 'application/pdf']
      if (allowedTypes.includes(file.mimetype)) {
         cb(null, true)
      } else {
         cb(
            new Error(
               'Invalid file type. Only JPEG, PNG, and PDF are allowed.',
            ),
         )
      }
   },
})

// Helper functions for map API
const mapHeaders = {
   Accept: 'application/json',
   'User-Agent':
      process.env.MAP_USER_AGENT || 'Flocksync/1.0 (contact: help@hos.sh)',
}
const parseAddressResult = (result) => {
   const displayName = result?.display_name?.trim()
   const latitude = Number.parseFloat(result?.lat)
   const longitude = Number.parseFloat(result?.lon)
   const address = result?.address || {}

   const addressLine = [address.house_number, address.road]
      .filter(Boolean)
      .join(' ')
      .trim()
   const city =
      address.neighbourhood ||
      address.suburb ||
      address.city_district ||
      address.city ||
      address.town ||
      address.village ||
      address.hamlet ||
      address.municipality ||
      ''
   const region = address.state || address.region || address.county || ''
   const postalCode = address.postcode || ''
   const countryCode = (address.country_code || '').toUpperCase()

   if (!displayName || Number.isNaN(latitude) || Number.isNaN(longitude)) {
      return null
   }

   return {
      displayName,
      latitude,
      longitude,
      addressLine,
      city,
      region,
      postalCode,
      countryCode,
   }
}
const searchAddresses = async ({ query, limit = DEFAULT_MAP_RESULT_LIMIT }) => {
   const response = await axios.get(`${MAP_BASE_URL}/search`, {
      params: {
         q: query,
         format: 'jsonv2',
         addressdetails: 1,
         limit,
      },
      headers: mapHeaders,
      timeout: MAP_REQUEST_TIMEOUT_MS,
   })

   if (!Array.isArray(response.data)) {
      throw new Error('Unexpected map service response')
   }

   return response.data.map(parseAddressResult).filter(Boolean)
}
const clampMapResultLimit = (limit) => {
   return Math.min(Math.max(limit, 1), MAX_MAP_RESULT_LIMIT)
}

// ---firebase
admin.initializeApp({
   credential: admin.credential.cert(serviceAccount),
})
const db = admin.firestore()

//--------------------SUPABASE
const supabase = createClient(
   process.env.SUPABASE_URL,
   process.env.SUPABASE_SERVICE_ROLE_KEY,
)

//retired
// using mongodb
// mongoose
//    .connect(process.env.MONGO_URI)
//    .then(() => console.log('MongoDB connected'))
//    .catch((err) => console.error('MongoDB connection error:', err))

/*
   API Endpoints
*/

// first get request
app.get('/', (req, res) => res.send('Hello World'))

// Address autocomplete
app.get('/api/maps/autocomplete', async (req, res) => {
   const query = req.query.q?.trim()
   const limit =
      Number.parseInt(req.query.limit, 10) || DEFAULT_MAP_RESULT_LIMIT

   if (!query || query.length < 3) {
      return sendError(
         res,
         400,
         'Address query must be at least 3 characters long.',
      )
   }

   try {
      const suggestions = await searchAddresses({
         query,
         limit: clampMapResultLimit(limit),
      })

      return res.json({ suggestions })
   } catch (error) {
      console.error('Address autocomplete failed:', error.message)
      return sendError(
         res,
         502,
         'Unable to fetch address suggestions right now.',
      )
   }
})

// Address verification and geocoding
app.get('/api/maps/verify', async (req, res) => {
   const address = req.query.address?.trim()

   if (!address) {
      return sendError(res, 400, 'Building address is required.')
   }

   try {
      const matches = await searchAddresses({ query: address, limit: 1 })
      const bestMatch = matches[0]

      if (!bestMatch) {
         return sendError(
            res,
            404,
            'We could not verify that address. Please choose a suggestion or refine it.',
         )
      }

      return res.json({
         verifiedAddress: {
            formattedAddress: bestMatch.displayName,
            latitude: bestMatch.latitude,
            longitude: bestMatch.longitude,
            addressLine: bestMatch.addressLine,
            city: bestMatch.city,
            region: bestMatch.region,
            postalCode: bestMatch.postalCode,
            countryCode: bestMatch.countryCode,
         },
      })
   } catch (error) {
      console.error('Address verification failed:', error.message)
      return sendError(
         res,
         502,
         'Unable to verify the building address right now.',
      )
   }
})

// verification docs using supabase cloud storage 0.5gb limit
app.post(
   '/api/user/upload-verification',
   upload.single('document'),
   async (req, res) => {
      try {
         const { userId } = req.body
         const file = req.file

         if (!userId || !file) {
            return res
               .status(400)
               .json({ error: 'User ID and document file are required.' })
         }

         const userDoc = await db.collection('users').doc(userId).get()

         // user exists check
         if (!userDoc.exists) {
            return res.status(404).json({ error: 'User not found.' })
         }

         // checks for role, only manager(change if role names change)
         const userData = userDoc.data()
         if (userData.role !== 'manager') {
            return res.status(403).json({
               error: 'Access denied. Only building managers can upload verification documents.',
            })
         }
         // variables for sharp
         let fileBuffer = file.buffer
         let fileExtension = file.originalname.split('.').pop()
         let contentType = file.mimetype

         // sharp image processing
         if (file.mimetype.startsWith('image/')) {
            fileBuffer = await sharp(file.buffer)
               .resize(1200, 1200, { fit: 'inside', withoutEnlargement: true })
               .jpeg({ quality: 80 })
               .toBuffer()

            fileExtension = 'jpg'
            contentType = 'image/jpeg'
         }

         const fileName = `${userId}/${Date.now()}.${fileExtension}`

         const { data, error: uploadError } = await supabase.storage
            .from('verification-documents')
            .upload(fileName, file.buffer, {
               contentType: file.mimetype,
               upsert: true,
            })

         if (uploadError) throw uploadError

         // generate a signed url that lasts 1 hour since this bucket is private
         const { data: signedData, error: signedUrlError } =
            await supabase.storage
               .from('verification-documents')
               .createSignedUrl(fileName, 3600)

         if (signedUrlError) throw signedUrlError

         await db
            .collection('users')
            .doc(userId)
            .set(
               {
                  verification: {
                     storage_path: fileName,
                     status: 'pending',
                     submitted_at: admin.firestore.FieldValue.serverTimestamp(),
                  },
               },
               { merge: true },
            )

         // send temporary link to frontend
         res.json({
            success: true,
            previewUrl: signedData.signedUrl,
            message: 'Document uploaded successfully',
         })
      } catch (error) {
         console.error('Upload error:', error.message)
         res.status(500).json({ error: error.message })
      }
   },
)

app.listen(PORT, () => console.log(`Server running on port ${PORT}`))
