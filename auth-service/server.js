const express = require('express');
const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

const app = express();
app.use(express.json());

const serviceAccount = require('./firebase-service-account.json');

initializeApp({
  credential: cert(serviceAccount),
  projectId: 'studyflow-cd599',
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.post('/verify', async (req, res) => {
  const authorization = req.headers.authorization || '';
  const match = authorization.match(/^Bearer\s+(.+)$/i);

  if (!match) {
    return res.status(401).json({
      authenticated: false,
      error: 'Missing bearer token',
    });
  }

  try {
    const decoded = await getAuth().verifyIdToken(match[1]);

    return res.json({
      authenticated: true,
      uid: decoded.uid,
      email: decoded.email || null,
    });
  } catch (error) {
    console.error('Token verification failed:', error.code || 'unknown');

    return res.status(401).json({
      authenticated: false,
      error: 'Invalid or expired token',
    });
  }
});

app.listen(3000, '0.0.0.0', () => {
  console.log('StudyFlow auth service listening on port 3000');
});
