const userService = require('../services/user.service');

exports.createUser = async (req, res, next) => {
  try {
    const { nome, email, vencimento } = req.body;

    if (!nome || !email || !vencimento) {
      return res.status(400).json({ error: 'Nome, email e vencimento são obrigatórios.' });
    }

    const novoUsuario = await userService.createUser({
      nome,
      email,
      vencimento: vencimento ? new Date(vencimento) : null,
    });

    res.status(201).json({ message: 'Usuário criado com sucesso', usuario: novoUsuario });
  } catch (error) {
    res.status(400).json({ error: error.message || 'Erro ao criar usuário.' });
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

exports.deletarUsuario = async (req, res, next) => {
  try {
    const { id } = req.params;
    await userService.excluirUsuario(Number(id));
    res.status(200).json({ message: 'Usuário excluído com sucesso' });
  } catch (error) {
    next(error);
  }
};
