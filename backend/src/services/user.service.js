const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();
const DEFAULT_PASSWORD = '123456';

exports.createUser = async ({ nome, email, vencimento }) => {
  const userExists = await prisma.usuario.findUnique({ where: { email } });
  if (userExists) {
    throw new Error('Email já cadastrado.');
  }

  const hashedPassword = await bcrypt.hash(DEFAULT_PASSWORD, 10);

  const usuario = await prisma.usuario.create({
    data: {
      nome,
      email,
      senha: hashedPassword,
      role: 'ALUNO',
      vencimento: vencimento || null,
    },
  });

  return usuario;
};

exports.atualizarUsuario = async (id, dados) => {
  return await prisma.usuario.update({
    where: { id },
    data: dados
  });
};

exports.listarAlunos = async () => {
  return await prisma.usuario.findMany({
    where: { role: 'ALUNO' },
    orderBy: { nome: 'asc' }
  });
};

exports.atualizarVencimento = async (id, vencimento) => {
  return await prisma.usuario.update({
    where: { id },
    data: { vencimento }
  });
};

exports.listarAlunosComVencimentoProximo = async () => {
  const hoje = new Date();
  hoje.setHours(0, 0, 0, 0); // <- força o início do dia
  const daqui3dias = new Date();
  daqui3dias.setDate(hoje.getDate() + 3);
  daqui3dias.setHours(23, 59, 59, 999); // <- força o fim do terceiro dia

  return await prisma.usuario.findMany({
    where: {
      role: 'ALUNO',
      vencimento: {
        gte: hoje,
        lte: daqui3dias
      }
    },
    orderBy: { vencimento: 'asc' }
  });
};

exports.excluirUsuario = async (id) => {
  await prisma.usuario.delete({
    where: { id },
  });
};
