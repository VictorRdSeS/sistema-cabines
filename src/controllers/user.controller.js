const userService = require('../services/user.service');

exports.createUser = async (req, res, next) => {
  try {
    const { nome, email } = req.body;
    if (!nome || !email) {
      return res.status(400).json({ error: 'Nome e email são obrigatórios.' });
    }

    const novoUsuario = await userService.createUser({ nome, email });
    res.status(201).json({ message: 'Usuário criado com sucesso', usuario: novoUsuario });
  } catch (error) {
    next(error);
  }
};
