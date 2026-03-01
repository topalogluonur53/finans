import { createClient } from 'redis';
import 'dotenv/config';

const mockClient = {
    get: async () => null,
    set: async () => null,
    isOpen: false,
    on: () => { }
};

export const redisContainer = {
    client: mockClient,
    isRedisEnabled: false
};

export const connectRedis = async () => {
    try {
        const client = createClient({
            url: process.env.REDIS_URL || 'redis://localhost:6379',
            socket: {
                reconnectStrategy: (retries) => {
                    if (retries > 0) return false;
                    return 500;
                }
            }
        });

        client.on('error', (err) => {
            if (redisContainer.isRedisEnabled) {
                console.log('Redis connection lost, switching to DB only.');
            }
            redisContainer.isRedisEnabled = false;
        });

        await client.connect();
        console.log('Connected to Redis');
        redisContainer.client = client;
        redisContainer.isRedisEnabled = true;
    } catch (error) {
        console.warn('Redis not found or connection failed. Running in DB-only mode.');
        redisContainer.isRedisEnabled = false;
        redisContainer.client = mockClient;
    }
};
