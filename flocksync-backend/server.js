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
const PORT = process.env.PORT || 5050
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
      // console.log('Detected MIME type:', file.mimetype)
      const allowedTypes = [
         'image/jpeg',
         'image/png',
         'application/pdf',
         'image/heic',
         'image/webp',
      ]
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
   try {
      console.log(`[MAP SERVICE] Searching for: "${query}" (limit: ${limit})`)
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

      console.log(`[MAP SERVICE] Got ${response.data?.length || 0} results`)

      if (!Array.isArray(response.data)) {
         throw new Error('Unexpected map service response format')
      }

      return response.data.map(parseAddressResult).filter(Boolean)
   } catch (error) {
      console.error('[MAP SERVICE] Error details:', {
         message: error.message,
         code: error.code,
         status: error.response?.status,
         statusText: error.response?.statusText,
         url: error.config?.url,
      })
      throw error
   }
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
// put in .env from the supabase
// SUPABASE_URL=https://<the-long-string-of-letters-in-the-url>.supabase.co
// go to settings -> api keys
// SUPABASE_ANON_KEY=<publishable-key>
// SUPABASE_SERVICE_ROLE_KEY=<secret-key>
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
      console.error('[AUTOCOMPLETE ENDPOINT] Error:', error.message)

      if (error.response?.status === 429) {
         return sendError(
            res,
            429,
            'Map service rate limited. Please try again in a moment.',
         )
      }

      if (error.code === 'ECONNREFUSED' || error.code === 'ENOTFOUND') {
         return sendError(res, 503, 'Map service is currently unavailable.')
      }

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
      console.error('[VERIFY ENDPOINT] Error:', error.message)

      if (error.response?.status === 429) {
         return sendError(
            res,
            429,
            'Map service rate limited. Please try again in a moment.',
         )
      }

      if (error.code === 'ECONNREFUSED' || error.code === 'ENOTFOUND') {
         return sendError(res, 503, 'Map service is currently unavailable.')
      }

      return sendError(
         res,
         502,
         'Unable to verify the building address right now.',
      )
   }
})

//--------------------------- profile picture route
// for all profile picture uploads
// dont need get request since this is stored publically, just call photo_url on the front
app.post(
   '/api/user/update-profile-picture',
   upload.single('image'),
   async (req, res) => {
      const { userId } = req.body
      const file = req.file

      if (!userId || !file) {
         return res.status(400).json({ error: 'Missing userId or image file.' })
      }

      try {
         const userDoc = await db.collection('users').doc(userId).get()
         if (!userDoc.exists) {
            return res.status(404).json({ error: 'User not found.' })
         }

         const processedBuffer = await sharp(file.buffer)
            .resize(400, 400, { fit: 'cover' })
            .jpeg({ quality: 85 })
            .toBuffer()

         const fileName = `${userId}/profile_${Date.now()}.jpg`

         const { data, error: uploadError } = await supabase.storage
            .from('profile-pictures')
            .upload(fileName, processedBuffer, {
               contentType: 'image/jpeg',
               upsert: true,
            })

         if (uploadError) throw uploadError

         const { data: publicUrlData } = supabase.storage
            .from('profile-pictures')
            .getPublicUrl(fileName)

         const publicImageLink = publicUrlData.publicUrl

         await db.collection('users').doc(userId).set(
            {
               photo_url: publicImageLink,
            },
            { merge: true },
         )

         return res.json({
            success: true,
            photoUrl: publicImageLink,
            message: 'Profile picture updated successfully!',
         })
      } catch (error) {
         console.error('Profile upload error:', error.message)
         return res.status(500).json({ error: error.message })
      }
   },
)
//----------------------------------verification documents(not resident verification)
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
            .upload(fileName, fileBuffer, {
               contentType: contentType,
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
                  owner_verification: {
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

// used for us to check grab the photo from supabase to manually check
// should use admin role, but using manager role for now for easier testing (dont want to create a new user and manually set role to admin)
app.get('/api/manager/view-document/:userId', async (req, res) => {
   // get the path from firestore that was storing during verification upload
   const userDoc = await db.collection('users').doc(req.params.userId).get()
   const path = userDoc.data()?.owner_verification?.storage_path

   if (!path) return res.status(404).send('No document found')

   //generate a fresh 15 minute link, supabase security things
   const { data } = await supabase.storage
      .from('verification-documents')
      .createSignedUrl(path, 900)
   res.json({ url: data.signedUrl })
})

// more admin stuff temp using manager
app.patch('/api/manager/verify-user', async (req, res) => {
   // decision should be 'approved' or 'rejected'
   const { userId, decision, adminNotes } = req.body

   try {
      const status = decision === 'approved' ? 'verified' : 'rejected'

      await db
         .collection('users')
         .doc(userId)
         .update({
            'owner_verification.status': status,
            'owner_verification.reviewed_at':
               admin.firestore.FieldValue.serverTimestamp(),
            'owner_verification.admin_notes': adminNotes || '',
         })

      res.json({ success: true, message: `User status updated to ${status}` })
   } catch (error) {
      res.status(500).json({ error: error.message })
   }
})

//create a default field for user if they select manager -> building owner to add a verification status
// again change manager to admin later
app.get('/api/manager/pending-verifications', async (req, res) => {
   try {
      const snapshot = await db
         .collection('users')
         .where('owner_verification.status', '==', 'pending')
         .orderBy('owner_verification.submitted_at', 'asc')
         .get()

      const pending = snapshot.docs.map((doc) => ({
         id: doc.id,
         ...doc.data().verification,
         displayName: doc.data().displayName,
      }))

      res.json(pending)
   } catch (error) {
      res.status(500).json({ error: error.message })
   }
})

//deletion path for testing
// just using manual delete in supabase console right now
// app.delete('/api/user/delete-verification', async (req, res) => {
//    const { userId, storagePath } = req.body

//    if (!userId || !storagePath) {
//       return res.status(400).json({ error: 'Missing userId or storagePath' })
//    }

//    try {
//       const { data, error: storageError } = await supabase.storage
//          .from('verification-documents')
//          .remove([storagePath])

//       if (storageError) throw storageError

//       await db.collection('users').doc(userId).update({
//          verification: admin.firestore.FieldValue.delete(),
//       })

//       res.json({
//          success: true,
//          message: 'Test image and metadata deleted successfully',
//       })
//    } catch (error) {
//       console.error('Delete error:', error.message)
//       res.status(500).json({ error: error.message })
//    }
// })

app.listen(PORT, () => console.log(`Server running on port ${PORT}`))
