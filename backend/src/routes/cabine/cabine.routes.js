const express = require('express');
const router = express.Router();
const cabineController = require('../../controllers/cabine/cabine.controller');
const auth = require('../../middlewares/auth.middleware');
const permitirRoles = require('../../middlewares/role.middleware');

router.post('/', auth, permitirRoles('ADMIN', 'RECEPCIONISTA'), cabineController.criar);
router.get('/', auth, cabineController.listar);
router.patch('/:id/status', auth, permitirRoles('ADMIN', 'RECEPCIONISTA'), cabineController.atualizarStatus);

module.exports = router;
