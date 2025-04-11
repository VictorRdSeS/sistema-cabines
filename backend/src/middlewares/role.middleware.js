/**
 * Middleware para permitir apenas usuários com determinados papéis (roles).
 * 
 * Uso:
 * router.post('/rota', auth, permitirRoles('ADMIN', 'RECEPCIONISTA'), controller)
 */
module.exports = function permitirRoles(...rolesPermitidos) {
    return (req, res, next) => {
        const roleUsuario = req.usuario?.role;

        if (!roleUsuario) {
            return res.status(401).json({ error: 'Usuário não autenticado.' });
        }

        if (!rolesPermitidos.includes(roleUsuario)) {
            return res.status(403).json({ error: 'Acesso negado. Permissão insuficiente.' });
        }

        next();
    };
};
