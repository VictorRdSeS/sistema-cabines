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

exports.atualizarUsuario = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { nome, email, senha, role } = req.body;

    const dadosAtualizados = {};

    if (nome) dadosAtualizados.nome = nome;
    if (email) dadosAtualizados.email = email;
    if (role) dadosAtualizados.role = role;
    if (senha) {
      const bcrypt = require('bcrypt');
      dadosAtualizados.senha = await bcrypt.hash(senha, 10);
    }

    const usuario = await userService.atualizarUsuario(Number(id), dadosAtualizados);
    res.json(usuario);
  } catch (error) {
    next(error);
  }
};

exports.listarAlunos = async (req, res, next) => {
  try {
    const alunos = await userService.listarAlunos();
    res.json(alunos);
  } catch (error) {
    next(error);
  }
};

exports.atualizarVencimento = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { vencimento } = req.body;

    if (!vencimento) {
      return res.status(400).json({ error: 'Campo vencimento é obrigatório.' });
    }

    const aluno = await userService.atualizarVencimento(Number(id), new Date(vencimento));
    res.json(aluno);
  } catch (error) {
    next(error);
  }
};

exports.listarComVencimentoProximo = async (req, res, next) => {
  try {
    const alunos = await userService.listarAlunosComVencimentoProximo();
    res.json(alunos);
  } catch (error) {
    next(error);
  }
};
