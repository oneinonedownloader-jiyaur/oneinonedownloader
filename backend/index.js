require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const app = express();

// --- Middleware ---
app.use(cors()); // Enable CORS for all routes
app.use(helmet()); // Apply basic security headers
app.use(express.json()); // Parse JSON bodies

// --- Routes ---
app.get('/', (req, res) => {
  res.send('OmniDownloader Backend is running!');
});

// POST /analyze
// Receives a generic URL and returns available download formats.
app.post('/analyze', async (req, res) => {
  const { url } = req.body;

  if (!url) {
    return res.status(400).json({ error: 'URL is required' });
  }

  console.log(`Analyzing URL: ${url}`);

  // --- MOCK IMPLEMENTATION ---
  // For now, we return mock data to build the frontend.
  // We will replace this with a real web scraper later.
  try {
    // Simulate network delay
    await new Promise(resolve => setTimeout(resolve, 1500));

    const mockData = {
      title: 'A Cool Video Found on the Web',
      thumbnailUrl: 'https://via.placeholder.com/480x360.png?text=Video+Thumbnail',
      formats: [
        { id: '720p', quality: '720p', container: 'mp4', note: 'Video + Audio' },
        { id: '480p', quality: '480p', container: 'mp4', note: 'Video + Audio' },
      ],
      audioOnly: [
        { id: '128k', quality: '128kbps', container: 'mp3', note: 'Audio Only' }
      ]
    };

    res.json(mockData);

  } catch (error) {
    console.error('Error during analysis:', error);
    res.status(500).json({ error: 'Failed to analyze the provided URL.' });
  }
});

const admin = require('firebase-admin');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

// --- Firebase Initialization ---
try {
  const serviceAccount = require('./serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} catch (error) {
  console.error('Firebase Admin SDK initialization failed. Make sure serviceAccountKey.json is present in the backend directory.');
}
const db = admin.firestore();

// POST /download
app.post('/download', async (req, res) => {
  const { url, formatId, userId, title, thumbnailUrl } = req.body;
  if (!url || !formatId) {
    return res.status(400).json({ error: 'URL and formatId are required' });
  }

  const downloadId = crypto.randomBytes(16).toString('hex');
  const docRef = db.collection('downloads').doc(downloadId);

  console.log(`Initiating download for ${url}. ID: ${downloadId}`);

  await docRef.set({
    id: downloadId,
    userId,
    url,
    title: title || 'Untitled',
    thumbnailUrl: thumbnailUrl || '',
    formatId,
    status: 'downloading',
    progress: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // --- MOCK DOWNLOAD PROCESS ---
  let progress = 0;
  const interval = setInterval(async () => {
    progress += 20;
    if (progress >= 100) {
      clearInterval(interval);
      await docRef.update({ progress: 100, status: 'completed' });
      console.log(`Download ${downloadId} completed.`);
    } else {
      await docRef.update({ progress });
    }
  }, 1000);

  res.status(202).json({ downloadId });
});

// GET /download/status/:downloadId
app.get('/download/status/:downloadId', async (req, res) => {
  const { downloadId } = req.params;
  try {
    const doc = await db.collection('downloads').doc(downloadId).get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Download not found' });
    }
    res.json(doc.data());
  } catch (error) {
    res.status(500).json({ error: 'Failed to get download status' });
  }
});

// GET /history/:userId
app.get('/history/:userId', async (req, res) => {
  const { userId } = req.params;
  try {
    const snapshot = await db.collection('downloads').where('userId', '==', userId).orderBy('createdAt', 'desc').get();
    const history = snapshot.docs.map(doc => doc.data());
    res.json(history);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch download history' });
  }
});

// GET /download/stream/:downloadId
app.get('/download/stream/:downloadId', async (req, res) => {
  const { downloadId } = req.params;
  try {
    const doc = await db.collection('downloads').doc(downloadId).get();
    if (!doc.exists || doc.data().status !== 'completed') {
      return res.status(404).json({ error: 'File not ready or does not exist' });
    }

    const mockFilePath = path.join(__dirname, 'mock-download.tmp');
    fs.writeFileSync(mockFilePath, `This is a mock downloaded file for URL: ${doc.data().url}`);
    
    res.download(mockFilePath, 'video.mp4', (err) => {
      if (err) console.error('Error sending file:', err);
      fs.unlinkSync(mockFilePath);
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to stream file' });
  }
});

// --- Server ---
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
