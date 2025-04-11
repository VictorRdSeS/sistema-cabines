const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.criarCabine = async ({ nome }) => {
    return await prisma.cabine.create({
        data: { nome }
    });
};

exports.listarCabines = async () => {
    return await prisma.cabine.findMany();
};

exports.atualizarStatus = async (id, status) => {
    return await prisma.cabine.update({
        where: { id },
        data: { status }
    });
};
