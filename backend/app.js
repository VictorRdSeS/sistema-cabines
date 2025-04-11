const express = require('express');
const app = express();

const cors = require('cors');
app.use(cors());

app.use(express.json());

const userRoutes = require('./src/routes/user.routes');
app.use('/usuarios', userRoutes);

const authRoutes = require('./src/routes/auth.routes');
app.use('/auth', authRoutes);

const cabineRoutes = require('./src/routes/cabine/cabine.routes');
app.use('/cabines', cabineRoutes);

const metaRoutes = require('./src/routes/meta/meta.routes');
app.use('/metas', metaRoutes);

const dashboardRoutes = require('./src/routes/dashboard/dashboard.routes');
app.use('/dashboard', dashboardRoutes);


app.get('/', (req, res) => {
  res.send('API está no ar!');
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Erro interno do servidor' });
});

module.exports = app;
