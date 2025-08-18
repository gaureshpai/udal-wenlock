const express = require('express');
const http = require('http');
const WebSocket = require('ws');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

app.get('/', (req, res) => {
    res.sendFile(__dirname + '/index.html');
});

app.get("/test", (req, res) => {
    let g = Date.now();
    res.json({ now: g })
})

wss.on('connection', (ws) => {
    console.log('Browser connected via WebSocket');

    setInterval(() => ws.send('Hello from WebSocket server!'), 5000);

    ws.on('message', (msg) => {
        console.log('Got from browser:', msg.toString());
        ws.send(`Server echo: ${msg}`);
    });
});

server.listen(3000, '0.0.0.0', () => {
    console.log('Server running at http://localhost:3000');
});
