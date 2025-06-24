# Cloud Storage for File Uploads

When deploying to services like Vercel, Render, or Heroku, local file storage isn't viable because:
1. The filesystem is often ephemeral
2. Scaling becomes challenging
3. Files are lost during redeployments

Here's how to use AWS S3 for file storage instead:

## AWS S3 Integration

### 1. Install Required Packages

```bash
npm install aws-sdk multer-s3
```

### 2. Update Upload Middleware

Replace the local storage implementation with S3:

```javascript
const multer = require('multer');
const multerS3 = require('multer-s3');
const aws = require('aws-sdk');
const path = require('path');
const { AppError } = require('./error');
const config = require('../config/config');

// Configure AWS
aws.config.update({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION
});

const s3 = new aws.S3();

// Configure storage
const storage = multerS3({
  s3: s3,
  bucket: process.env.AWS_S3_BUCKET_NAME,
  acl: 'public-read',
  key: function (req, file, cb) {
    let uploadPath = '';
    
    if (file.fieldname === 'boardImages') {
      uploadPath = 'boards/images/';
    } else if (file.fieldname === 'boardDocuments') {
      uploadPath = 'boards/documents/';
    } else if (file.fieldname === 'componentImages') {
      uploadPath = 'components/images/';
    } else if (file.fieldname === 'repairImages') {
      uploadPath = 'repairs/images/';
    }
    
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    const filename = `${file.fieldname}-${uniqueSuffix}${ext}`;
    
    cb(null, uploadPath + filename);
  }
});

// File filter function remains the same...

// Configure multer
const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: config.upload.maxFileSize
  }
});

// Other code remains the same...
```

### 3. Update Environment Variables

Add these environment variables to your deployment platform:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `AWS_S3_BUCKET_NAME`

### 4. Update Response Data

Update your controllers to use the S3 URLs:

```javascript
// Before (with local storage)
res.status(201).json({
  status: 'success',
  data: {
    board: {
      // ...board data
      images: req.files.map(file => `/uploads/${file.filename}`)
    }
  }
});

// After (with S3)
res.status(201).json({
  status: 'success',
  data: {
    board: {
      // ...board data
      images: req.files.map(file => file.location) // S3 URL
    }
  }
});
```

## Other Cloud Storage Options

### Google Cloud Storage

Similar to S3, using the `@google-cloud/storage` package and `multer-google-storage`.

### Azure Blob Storage

Use the `azure-storage` package with a custom multer storage engine.

### Cloudinary

Excellent for image storage and manipulation:

```bash
npm install cloudinary multer-storage-cloudinary
```

## Important Security Considerations

1. Set proper CORS configuration on your bucket
2. Consider using signed URLs for sensitive documents
3. Implement file type validation both on frontend and backend
4. Set appropriate bucket permissions
5. Consider encrypting sensitive files
