const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();
const DEFAULT_PASSWORD = '123456';

exports.createUser = async ({ nome, email }) => {
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
      role: 'ALUNO'
    },
  });

  return usuario;
};
