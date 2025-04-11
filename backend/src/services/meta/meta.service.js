const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.criarMeta = async ({ titulo, data, alunoId }) => {
    return await prisma.meta.create({
        data: {
            titulo,
            data,
            alunoId
        }
    });
};

exports.listarMetasDoAluno = async (alunoId) => {
    return await prisma.meta.findMany({
        where: { alunoId },
        orderBy: { data: 'asc' }
    });
};

exports.marcarComoConcluida = async (id) => {
    return await prisma.meta.update({
        where: { id },
        data: { concluida: true }
    });
};
