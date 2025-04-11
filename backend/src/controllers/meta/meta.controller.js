const metaService = require('../../services/meta/meta.service');

exports.criar = async (req, res, next) => {
    try {
        const { titulo, data } = req.body;
        const alunoId = req.usuario.id;

        const novaMeta = await metaService.criarMeta({ titulo, data: new Date(data), alunoId });
        res.status(201).json(novaMeta);
    } catch (error) {
        next(error);
    }
};

exports.listarMinhasMetas = async (req, res, next) => {
    try {
        const alunoId = req.usuario.id;
        const metas = await metaService.listarMetasDoAluno(alunoId);
        res.json(metas);
    } catch (error) {
        next(error);
    }
};

exports.marcarConcluida = async (req, res, next) => {
    try {
        const { id } = req.params;
        const meta = await metaService.marcarComoConcluida(Number(id));
        res.json(meta);
    } catch (error) {
        next(error);
    }
};
