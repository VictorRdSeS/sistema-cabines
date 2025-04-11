const express = require('express');
const app = express();
const userRoutes = require('./src/routes/user.routes');
const authRoutes = require('./src/routes/auth.routes');

app.use(express.json());
app.use('/usuarios', userRoutes);
app.use('/auth', authRoutes);

app.get('/', (req, res) => {
  res.send('API está no ar!');
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Erro interno do servidor' });
});

module.exports = app;
