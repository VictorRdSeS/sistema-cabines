const express = require('express');
const router = express.Router();
const auth = require('../../middlewares/auth.middleware');
const permitirRoles = require('../../middlewares/role.middleware');
const dashboardController = require('../../controllers/dashboard/dashboard.controller');

router.get('/resumo', auth, permitirRoles('RECEPCIONISTA', 'ADMIN'), dashboardController.resumo);

module.exports = router;
