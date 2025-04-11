const express = require('express');
const app = express();
const userRoutes = require('./src/routes/user.routes');

app.get('/', (req, res) => {
    res.send('API está no ar!');
});

app.use(express.json());
app.use('/usuarios', userRoutes);

app.use((err, req, res, next) => {
    console.error(err);
    res.status(500).json({ error: 'Erro interno do servidor' });
});

module.exports = app;
