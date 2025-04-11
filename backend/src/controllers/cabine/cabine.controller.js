const cabineService = require('../../services/cabine/cabine.service');

exports.criar = async (req, res, next) => {
    try {
        const { nome } = req.body;
        const cabine = await cabineService.criarCabine({ nome });
        res.status(201).json(cabine);
    } catch (error) {
        next(error);
    }
};

exports.listar = async (req, res, next) => {
    try {
        const cabines = await cabineService.listarCabines();
        res.json(cabines);
    } catch (error) {
        next(error);
    }
};

exports.atualizarStatus = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        const cabineAtualizada = await cabineService.atualizarStatus(Number(id), status);
        res.json(cabineAtualizada);
    } catch (error) {
        next(error);
    }
};
