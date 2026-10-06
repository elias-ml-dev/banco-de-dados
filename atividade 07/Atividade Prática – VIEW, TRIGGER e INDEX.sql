CREATE DATABASE IF NOT EXISTS sakila;
USE sakila;


-- 1. VIEWS (4 VIEWs com pelo menos 2 tabelas cada)

-- VIEW 1: Filmes e seus Idiomas
CREATE OR REPLACE VIEW vw_filme_idioma AS
SELECT f.title, l.name AS idioma
FROM film f
JOIN language l ON f.language_id = l.language_id;

SELECT * FROM vw_filme_idioma LIMIT 5;


-- VIEW 2: Clientes e seus Endereços
CREATE OR REPLACE VIEW vw_cliente_endereco AS
SELECT c.first_name, c.last_name, a.address
FROM customer c
INNER JOIN address a ON c.address_id = a.address_id;

SELECT * FROM vw_cliente_endereco LIMIT 5;


-- VIEW 3: Atores e seus Filmes
CREATE OR REPLACE VIEW vw_ator_filme AS
SELECT a.first_name, a.last_name, f.title
FROM actor a
INNER JOIN film_actor fa ON a.actor_id = fa.actor_id
INNER JOIN film f ON fa.film_id = f.film_id;

SELECT * FROM vw_ator_filme LIMIT 5;


-- VIEW 4: Pagamentos por Cliente
CREATE OR REPLACE VIEW vw_pagamento_cliente AS
SELECT c.first_name, c.last_name, p.amount, p.payment_date
FROM customer c
INNER JOIN payment p ON c.customer_id = p.customer_id;

SELECT * FROM vw_pagamento_cliente LIMIT 5;



-- 2. INDEX (3 Índices com EXPLAIN antes e depois)


-- ÍNDICE 1: Data de Pagamento na tabela payment
EXPLAIN SELECT * FROM payment WHERE payment_date = '2005-05-25';
CREATE INDEX idx_payment_date ON payment(payment_date);
EXPLAIN SELECT * FROM payment WHERE payment_date = '2005-05-25';


-- ÍNDICE 2: Preço de Aluguel na tabela film
EXPLAIN SELECT * FROM film WHERE rental_rate = 2.99;
CREATE INDEX idx_rental_rate ON film(rental_rate);
EXPLAIN SELECT * FROM film WHERE rental_rate = 2.99;


-- ÍNDICE 3: Data de Devolução na tabela rental
EXPLAIN SELECT * FROM rental WHERE return_date IS NULL;
CREATE INDEX idx_return_date ON rental(return_date);
EXPLAIN SELECT * FROM rental WHERE return_date IS NULL;



-- 3. TRIGGERS (2 Triggers com Tabela de Auditoria)

-- Tabela de Auditoria
CREATE TABLE IF NOT EXISTS log_auditoria (
    id INT AUTO_INCREMENT PRIMARY KEY,
    mensagem VARCHAR(255),
    data_log DATETIME DEFAULT CURRENT_TIMESTAMP
);


-- TRIGGER 1: Registrar alteração de preço em filme (AFTER UPDATE)
DELIMITER //
CREATE TRIGGER trg_filme_update
AFTER UPDATE ON film
FOR EACH ROW
BEGIN
    IF OLD.rental_rate <> NEW.rental_rate THEN
        INSERT INTO log_auditoria (mensagem)
        VALUES (CONCAT('Filme ', NEW.title, ' alterou preco de ', OLD.rental_rate, ' para ', NEW.rental_rate));
    END IF;
END //
DELIMITER ;


-- TRIGGER 2: Registrar novo pagamento (AFTER INSERT)
DELIMITER //
CREATE TRIGGER trg_pagamento_insert
AFTER INSERT ON payment
FOR EACH ROW
BEGIN
    INSERT INTO log_auditoria (mensagem)
    VALUES (CONCAT('Novo pagamento ID ', NEW.payment_id, ' no valor de ', NEW.amount));
END //
DELIMITER ;



-- 4. TESTES DAS TRIGGERS

-- Teste Trigger 1 (Update)
UPDATE film SET rental_rate = 3.99 WHERE film_id = 1;

-- Teste Trigger 2 (Insert)
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
VALUES (1, 1, 1, 5.00, NOW());

-- Verificar os logs gerados pelas triggers
SELECT * FROM log_auditoria;