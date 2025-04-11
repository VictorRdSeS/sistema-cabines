const express = require('express');
const router = express.Router();
const userController = require('../controllers/user.controller');
const auth = require('../middlewares/auth.middleware');
const permitirRoles = require('../middlewares/role.middleware');

// ✅ Rota protegida: apenas usuários com token válido podem acessar, com validação da regra dem quem tem permissão de Criar.
router.post('/', auth, permitirRoles('RECEPCIONISTA', 'ADMIN'), userController.createUser);

// 🔒 Exemplo de rota protegida para consulta (apenas como padrão)
router.get('/protegido', auth, (req, res) => {
    res.json({ message: `Rota protegida acessada com sucesso! Usuário logado: ID ${req.usuario.id}, Perfil: ${req.usuario.role}` });
});

module.exports = router;
