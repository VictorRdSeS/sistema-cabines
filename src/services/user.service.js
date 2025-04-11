const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();
const DEFAULT_PASSWORD = '123456';

exports.createUser = async ({ nome, email }) => {
    // Verifica se o usuário já existe
    const userExists = await prisma.usuario.findUnique({ where: { email } });
    if (userExists) {
        throw new Error('Email já cadastrado.');
    }

    // Criptografa a senha padrão
    const hashedPassword = await bcrypt.hash(DEFAULT_PASSWORD, 10);

    // Cria o usuário com role ALUNO
    const usuario = await prisma.usuario.create({
        data: {
            nome,
            email,
            senha: hashedPassword,
            role: 'ALUNO'  // Garante que o usuário seja um aluno
        },
    });
    return usuario;
};
