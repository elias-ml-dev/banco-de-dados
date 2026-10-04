-- 1- Criando banco de dados
CREATE DATABASE loja_trigger;
USE loja_trigger;

CREATE TABLE produtos(
	id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    preco DECIMAL(10,2) NOT NULL,
    estoque INT NOT NULL
);

CREATE TABLE vendas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    produto_id INT NOT NULL,
    quantidade INT NOT NULL,
    valor_total DECIMAL(10 , 2 ),
    data_venda DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE auditoria (
    id INT AUTO_INCREMENT PRIMARY KEY,
    mensagem VARCHAR(255),
    data_registro DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE produtos_excluidos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    produto_id INT,
    nome VARCHAR(100),
    preco DECIMAL(10,2),
    estoque INT,
    data_exclusao DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2- Registrs iniciais

INSERT INTO produtos (nome, preco, estoque)
VALUES
('Mouse', 80.00, 20),
('Teclado', 150.00, 15),
('Monitor', 900.00, 10),
('Notebook', 3500.00, 5),
('Headset', 200.00, 8);

SELECT * FROM produtos;

-- 1. Nome em letra maiúscula

DELIMITER $$

CREATE TRIGGER trg_nome_maiusculo
BEFORE INSERT ON produtos
FOR EACH ROW
BEGIN
    SET NEW.nome = UPPER(NEW.nome);
END $$

DELIMITER ;

-- Teste
INSERT INTO produtos (nome, preco, estoque)
VALUES ('webcam', 250.00, 10);

SELECT * FROM produtos;

-- 2. Não permitir preço Negativo.

DELIMITER $$

CREATE TRIGGER trg_validar_preco
BEFORE INSERT ON produtos
FOR EACH ROW
BEGIN
    IF NEW.preco < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'O preço não pode ser negativo';
    END IF;
END $$

DELIMITER ;

-- TESTE

INSERT INTO produtos (nome, preco, estoque)
VALUES ('Cabo USB', -20.00, 10);

-- 3. Não permitir estoque negativo.

DELIMITER $$

CREATE TRIGGER trg_validar_estoque
BEFORE INSERT ON produtos
FOR EACH ROW
BEGIN
    IF NEW.estoque < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'O estoque não pode ser negativo';
    END IF;
END $$

DELIMITER ;

INSERT INTO produtos (nome, preco, estoque)
VALUES ('Caixa de Som', 300.00, -5);


-- 4. Registrar Alteração de Preço:

DELIMITER $$

CREATE TRIGGER trg_alteracao_preco
AFTER UPDATE ON produtos
FOR EACH ROW
BEGIN
    IF NOT (OLD.preco <=> NEW.preco) THEN
        INSERT INTO auditoria (mensagem)
        VALUES (CONCAT('Produto: ', NEW.nome, ' | Preço antigo: ', OLD.preco, ' | Preço novo: ', NEW.preco));
    END IF;
END $$

DELIMITER ;

-- TESTE:
UPDATE produtos
SET preco = 100
WHERE id = 1;

SELECT * FROM auditoria;

-- 5 Impedir alteração para preço negativo:
DELIMITER $$

CREATE TRIGGER trg_validar_novo_preco
BEFORE UPDATE ON produtos
FOR EACH ROW
BEGIN
    IF NEW.preco < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'O preço não pode ser negativo';
    END IF;
END $$

DELIMITER ;

-- Teste
UPDATE produtos
SET preco = -500
WHERE id = 3;

-- 6. guardar produtos excluídos

DELIMITER $$

CREATE TRIGGER trg_produto_excluido
AFTER DELETE ON produtos
FOR EACH ROW
BEGIN
    INSERT INTO produtos_excluidos (produto_id, nome, preco, estoque)
    VALUES (OLD.id, OLD.nome, OLD.preco, OLD.estoque);
END $$

DELIMITER ;

-- TESTES:
INSERT INTO produtos (nome, preco, estoque)
VALUES ('Produto Teste', 10.00, 1);

SELECT * FROM produtos;
DELETE FROM produtos WHERE id = 7;

SELECT * FROM produtos_excluidos;

-- 7. Coonsultar TRIGGER
SHOW TRIGGERS;

-- 8. apagar Trigger

DROP TRIGGER trg_produto_excluido;