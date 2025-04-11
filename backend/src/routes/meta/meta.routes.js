const express = require('express');
const router = express.Router();
const metaController = require('../../controllers/meta/meta.controller');
const auth = require('../../middlewares/auth.middleware');

router.post('/', auth, metaController.criar);
router.get('/', auth, metaController.listarMinhasMetas);
router.patch('/:id/concluir', auth, metaController.marcarConcluida);

module.exports = router;
