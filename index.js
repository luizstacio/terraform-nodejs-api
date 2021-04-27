const http = require('http');
const { Client } = require('pg')

const {
    DATABASE_PASSWORD,
    DATABASE_URL,
    DATABASE_USERNAME,
    DATABASE_NAME
} = process.env;
const [host, port_db] = String(DATABASE_URL).split(':');

const port = process.env.PORT || 3000;
const server = http.createServer({}, async (req, res) => {
    try {
        const client = new Client({
            host,
            port: port_db,
            user: DATABASE_USERNAME,
            password: DATABASE_PASSWORD,
            database: DATABASE_NAME
        });
        await client.connect()
        const resdb = await client.query('SELECT $1::text as message', ['From db!'])
        await client.end();
        res.write(JSON.stringify({
            message: 'Hello world 2',
            database: resdb.rows[0].message,
            configs: process.env
        }));
        res.addTrailers({ 'Content-Type': 'application/json' });
        res.end();
    } catch (e) {
        res.write(JSON.stringify(e));
        res.end();
    }

});
server.listen(port, () => {
    console.log('Server listening at port', port);
});