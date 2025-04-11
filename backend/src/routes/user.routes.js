const express = require('express');
const router = express.Router();
const userController = require('../controllers/user.controller');
const auth = require('../middlewares/auth.middleware');
const permitirRoles = require('../middlewares/role.middleware');

// Criar usuário (somente recepcionista ou admin)
router.post('/', auth, permitirRoles('ADMIN', 'RECEPCIONISTA'), userController.createUser);

// Atualizar usuário (somente admin)
router.patch('/:id', auth, permitirRoles('ADMIN'), userController.atualizarUsuario);

//Listar Alunos
router.get('/alunos', auth, permitirRoles('ADMIN', 'RECEPCIONISTA'), userController.listarAlunos);

//Listar Alunos com Vencimento Proximo
router.get('/alunos/vencimentos-proximos', auth, permitirRoles('ADMIN', 'RECEPCIONISTA'), userController.listarComVencimentoProximo);

//Atualizar Vencimento
router.patch('/:id/vencimento', auth, permitirRoles('ADMIN', 'RECEPCIONISTA'), userController.atualizarVencimento);


router.get('/protegido', auth, (req, res) => {
    res.json({ message: `Rota protegida acessada por: ${req.usuario.nome}` });
});

module.exports = router;
