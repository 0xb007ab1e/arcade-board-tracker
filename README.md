# Arcade Board Tracker

A comprehensive web application for tracking motherboard components for arcade gaming machines.

## Project Overview

Arcade Board Tracker is designed to help arcade machine collectors, repair technicians, and hobbyists manage their inventory of arcade boards, track individual components on these boards, and maintain repair history records.

## Features

- **User Authentication**: Secure login and registration system with role-based access control
- **Board Management**: Track arcade boards with detailed specifications and documentation
- **Component Tracking**: Monitor individual components on arcade boards, including specifications and status
- **Repair History**: Log repair activities, issues identified, and parts replaced
- **Search and Filtering**: Easily find boards and components with advanced search capabilities
- **Documentation Storage**: Upload and manage schematics, datasheets, and images
- **Reporting**: Generate inventory and repair reports

## Technology Stack

- **Backend**: Node.js, Express.js, MongoDB with Mongoose
- **Frontend**: React.js, Redux, Material-UI
- **Authentication**: JWT-based authentication
- **File Storage**: Local file system with Multer

## CI/CD Pipeline

This project includes a CI/CD pipeline that automatically deploys each branch to your preferred cloud provider. The pipeline supports:

- Vercel (default)
- Render
- Railway
- Heroku
- Netlify

For each branch, a unique preview environment is created, allowing you to validate changes before merging to the main branch. See [CI/CD Setup Guide](docs/CI_CD_SETUP.md) for detailed instructions on configuring the pipeline.

## Getting Started

### Prerequisites

- Node.js (v14 or higher)
- MongoDB (v4 or higher)
- npm or yarn

### Installation

1. Clone the repository
   ```
   git clone https://github.com/yourusername/arcade-board-tracker.git
   cd arcade-board-tracker
   ```

2. Install dependencies
   ```
   npm install
   ```

3. Set up environment variables
   ```
   cp .env.example .env
   ```
   Edit the `.env` file with your configuration

4. Start the development server
   ```
   npm run dev
   ```

## Project Structure

```
arcade-board-tracker/
├── client/                       # Frontend React application
├── server/                       # Backend Node.js/Express application
│   ├── config/                   # Configuration files
│   ├── controllers/              # Route controllers
│   ├── middleware/               # Express middleware
│   ├── models/                   # Mongoose models
│   ├── routes/                   # API routes
│   ├── uploads/                  # File storage directory
│   └── index.js                  # Server entry point
├── docs/                         # Documentation
└── tests/                        # Test files
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- All contributors and maintainers
- The arcade gaming community for inspiration
- Testing team for deployment verification
