-- CreateTable
CREATE TABLE `Meta` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `titulo` VARCHAR(191) NOT NULL,
    `concluida` BOOLEAN NOT NULL DEFAULT false,
    `data` DATETIME(3) NOT NULL,
    `alunoId` INTEGER NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `Meta` ADD CONSTRAINT `Meta_alunoId_fkey` FOREIGN KEY (`alunoId`) REFERENCES `Usuario`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
