const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const morgan = require('morgan');
require('dotenv').config();

const sequelize = require('./config/database');
const { connectRedis } = require('./config/redis');

// Load models
require('./models/User');
require('./models/MarketData');
require('./models/Alarm');
require('./models/Portfolio');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Socket.io connection
io.on('connection', (socket) => {
    console.log('A user connected:', socket.id);

    socket.on('subscribe_prices', (symbols) => {
        if (Array.isArray(symbols)) {
            symbols.forEach(symbol => {
                socket.join(`price_${symbol}`);
                console.log(`Socket ${socket.id} subscribed to ${symbol}`);
            });
        }
    });

    socket.on('disconnect', () => {
        console.log('User disconnected:', socket.id);
    });
});

// Globalize io for use in services
global.io = io;

// Basic route
app.get('/', (req, res) => {
    res.send('Finans Backend (Node.js) is running');
});

// Routes
const authRoutes = require('./routes/auth');
const marketRoutes = require('./routes/market');
app.use('/api/auth', authRoutes);
app.use('/api/market', marketRoutes);

// Sync database and start server
const startServer = async () => {
    try {
        await sequelize.authenticate();
        console.log('Database connected successfully.');

        // In dev, sync models
        if (process.env.NODE_ENV === 'development') {
            await sequelize.sync({ alter: true });
            console.log('Database synced.');

            // Seed initial data
            const seedMarketData = require('./utils/seeder');
            await seedMarketData();
        }

        await connectRedis();

        // Start background jobs
        const initCrons = require('./utils/cron');
        initCrons();

        const PORT = process.env.PORT || 5000;
        server.listen(PORT, () => {
            console.log(`Server running on port ${PORT}`);
        });
    } catch (error) {
        console.error('Unable to start the server:', error);
    }
};

startServer();
