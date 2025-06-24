/**
 * File upload middleware
 */
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { AppError } = require('./error');
const config = require('../config/config');

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, '../uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Configure storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // Create specific subdirectories based on upload type
    let uploadPath = uploadsDir;
    
    if (file.fieldname === 'boardImages') {
      uploadPath = path.join(uploadsDir, 'boards/images');
    } else if (file.fieldname === 'boardDocuments') {
      uploadPath = path.join(uploadsDir, 'boards/documents');
    } else if (file.fieldname === 'componentImages') {
      uploadPath = path.join(uploadsDir, 'components/images');
    } else if (file.fieldname === 'repairImages') {
      uploadPath = path.join(uploadsDir, 'repairs/images');
    }
    
    // Ensure directory exists
    if (!fs.existsSync(uploadPath)) {
      fs.mkdirSync(uploadPath, { recursive: true });
    }
    
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    // Create unique filename using original name, field, timestamp, and random string
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, `${file.fieldname}-${uniqueSuffix}${ext}`);
  },
});

// File filter function
const fileFilter = (req, file, cb) => {
  // Check file type based on field
  if (
    file.fieldname === 'boardImages' || 
    file.fieldname === 'componentImages' || 
    file.fieldname === 'repairImages'
  ) {
    // Allow only image files
    if (!config.upload.allowedImageTypes.includes(file.mimetype)) {
      return cb(
        new AppError(
          `Invalid file type. Please upload only ${config.upload.allowedImageTypes.join(', ')}`,
          400
        ),
        false
      );
    }
  } else if (file.fieldname === 'boardDocuments') {
    // Allow only document files
    if (!config.upload.allowedDocTypes.includes(file.mimetype)) {
      return cb(
        new AppError(
          `Invalid file type. Please upload only ${config.upload.allowedDocTypes.join(', ')}`,
          400
        ),
        false
      );
    }
  }
  
  // Accept file
  cb(null, true);
};

// Configure multer
const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: config.upload.maxFileSize, // From config
  },
});

// Create upload middleware functions
const uploadBoardImages = upload.array('boardImages', 5); // Max 5 images
const uploadBoardDocuments = upload.array('boardDocuments', 5); // Max 5 documents
const uploadComponentImages = upload.array('componentImages', 3); // Max 3 images
const uploadRepairImages = upload.array('repairImages', 5); // Max 5 images

// Error handling wrapper for multer errors
const handleUpload = (uploadMiddleware) => {
  return (req, res, next) => {
    uploadMiddleware(req, res, (err) => {
      if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
          return next(new AppError(`File too large. Maximum size is ${config.upload.maxFileSize / 1000000}MB`, 400));
        }
        return next(new AppError(`Upload error: ${err.message}`, 400));
      } else if (err) {
        return next(err);
      }
      next();
    });
  };
};

module.exports = {
  uploadBoardImages: handleUpload(uploadBoardImages),
  uploadBoardDocuments: handleUpload(uploadBoardDocuments),
  uploadComponentImages: handleUpload(uploadComponentImages),
  uploadRepairImages: handleUpload(uploadRepairImages),
};
