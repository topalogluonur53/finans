import { Sequelize } from 'sequelize';
import path from 'path';
import 'dotenv/config';

const sequelize = new Sequelize({
    dialect: 'sqlite',
    storage: path.join(process.cwd(), 'database.sqlite'),
    logging: false
});

export default sequelize;
