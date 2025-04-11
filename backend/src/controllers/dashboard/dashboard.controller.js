const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.resumo = async (req, res, next) => {
    try {
        const hoje = new Date();
        hoje.setHours(0, 0, 0, 0);

        const daqui3dias = new Date();
        daqui3dias.setDate(hoje.getDate() + 3);
        daqui3dias.setHours(23, 59, 59, 999);

        const totalCabines = await prisma.cabine.count();
        const cabinesLivres = await prisma.cabine.count({ where: { status: 'LIVRE' } });
        const cabinesOcupadas = await prisma.cabine.count({ where: { status: 'OCUPADA' } });

        const totalAlunos = await prisma.usuario.count({ where: { role: 'ALUNO' } });

        const vencemHoje = await prisma.usuario.count({
            where: {
                role: 'ALUNO',
                vencimento: {
                    gte: hoje,
                    lte: new Date(hoje.getFullYear(), hoje.getMonth(), hoje.getDate(), 23, 59, 59, 999)
                }
            }
        });

        const vencemEm3Dias = await prisma.usuario.count({
            where: {
                role: 'ALUNO',
                vencimento: {
                    gt: hoje,
                    lte: daqui3dias
                }
            }
        });

        res.json({
            totalCabines,
            cabinesLivres,
            cabinesOcupadas,
            totalAlunos,
            vencemHoje,
            vencemEm3Dias
        });
    } catch (error) {
        next(error);
    }
};
