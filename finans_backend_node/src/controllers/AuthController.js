const User = require('../models/User');
const jwt = require('jsonwebtoken');
require('dotenv').config();

class AuthController {
    async register(req, res) {
        try {
            const { username, email, password } = req.body;

            const existingUser = await User.findOne({ where: { email } });
            if (existingUser) {
                return res.status(400).json({ error: 'Bu e-posta adresi zaten kullanımda.' });
            }

            const user = await User.create({ username, email, password });

            const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET, { expiresIn: '1d' });

            res.status(201).json({ user: { id: user.id, username: user.username, email: user.email }, token });
        } catch (error) {
            res.status(500).json({ error: error.message });
        }
    }

    async login(req, res) {
        try {
            const { email, password } = req.body;

            const user = await User.findOne({ where: { email } });
            if (!user) {
                return res.status(400).json({ error: 'Kullanıcı bulunamadı.' });
            }

            const isMatch = await user.comparePassword(password);
            if (!isMatch) {
                return res.status(400).json({ error: 'Hatalı şifre.' });
            }

            const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET, { expiresIn: '1d' });

            res.json({ user: { id: user.id, username: user.username, email: user.email }, token });
        } catch (error) {
            res.status(500).json({ error: error.message });
        }
    }

    async me(req, res) {
        try {
            const user = await User.findByPk(req.user.id, { attributes: { exclude: ['password'] } });
            res.json(user);
        } catch (error) {
            res.status(500).json({ error: error.message });
        }
    }
}

module.exports = new AuthController();
