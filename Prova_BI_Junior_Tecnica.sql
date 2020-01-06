/* 
1 - Execute em um banco de dados MySQL os scripts:
a) prova_bi_create.sql
b) prova_bi_insert.sql
*/
USE prova_bi;
/* 
2 - Crie as seguintes consultas em SQL que retorne (uma para cada questão):
a) Nome do Cliente, Sexo, Total de Pedidos ordenado pelo cliente que teve maior numero de pedido
*/

SELECT clientes.nome, 
       clientes.sexo, 
       Count(pedidos.codigo_pedidos) AS `Total de Pedidos` 
FROM   clientes 
       JOIN pedidos 
         ON clientes.codigo_cliente = pedidos.codigo_cliente 
GROUP  BY clientes.nome 
ORDER  BY Count(pedidos.codigo_pedidos) DESC; 

/* 
b) Região, Total Vendido na Região, Média de Vendas na Região, Maior Vendas da Região, Menor Vendas da Região
*/

SELECT 
       regioes.nome_regiao,
       SUM(produtos.preco * item_pedidos.quantidade) AS `Total Vendido`,
       SUM(produtos.preco * item_pedidos.quantidade)/COUNT(produtos.preco) AS 'Media Vendas',
       MAX(produtos.preco * item_pedidos.quantidade) AS 'Maior Venda',
       MIN(produtos.preco * item_pedidos.quantidade) AS 'Menor Venda'
FROM   pedidos 
       JOIN item_pedidos 
         ON pedidos.codigo_pedidos = item_pedidos.codigo_pedidos 
       JOIN produtos 
         ON item_pedidos.codigo_produto = produtos.codigo_produto 
	   JOIN vendedores
		 ON pedidos.codigo_vendedor = vendedores.codigo_vendedor
	   JOIN regioes
	     ON vendedores.codigo_regiao = regioes.codigo_regiao
GROUP  BY nome_regiao
ORDER  BY nome_regiao;

/* 
c) Vendedor, Ano-Mes, Total de Pedidos, Valor Total Vendido, Produto mais vendido no mês, Comissão
*/

SELECT 
       vendedores.nome_vendedor,
       date_format(pedidos.data_pedido,'%Y-%m') as `ano_mes`,
       COUNT(item_pedidos.codigo_pedidos) `Total de pedidos`,
       SUM(produtos.preco * item_pedidos.quantidade) AS `Total Vendido`,
       SUM(produtos.preco * item_pedidos.quantidade * vendedores.percentual_comissao / 100) AS 'Comissao'
FROM   pedidos 
       JOIN item_pedidos 
         ON pedidos.codigo_pedidos = item_pedidos.codigo_pedidos 
       JOIN produtos 
         ON item_pedidos.codigo_produto = produtos.codigo_produto 
	   JOIN vendedores
		 ON pedidos.codigo_vendedor = vendedores.codigo_vendedor
	   JOIN regioes
	     ON vendedores.codigo_regiao = regioes.codigo_regiao
GROUP BY  pedidos.data_pedido, vendedores.nome_vendedor
ORDER  BY pedidos.data_pedido;

/* 
d) Vendedor, Ano-Mes com mais vendas, Ano-Mes com menos vendas, Ano-Mes com maior comissão, Ano-Mes com menor comissão
*/
WITH mais_vendas AS 
( 
                SELECT 			vendedores.nome_vendedor, 
                                Date_format(pedidos.data_pedido, '%Y-%m') AS `ano_mes`, 
                                SUM(produtos.preco * item_pedidos.quantidade) AS `maior_vendido`,
                                rank() over ( partition BY vendedores.nome_vendedor ORDER BY sum(produtos.preco * item_pedidos.quantidade) DESC ) my_rank
                FROM            vendedores 
                JOIN            pedidos 
                ON              vendedores.codigo_vendedor = pedidos.codigo_vendedor 
                JOIN            item_pedidos 
                ON              pedidos.codigo_pedidos = item_pedidos.codigo_pedidos 
                JOIN            produtos 
                ON              item_pedidos.codigo_produto = produtos.codigo_produto 
                GROUP BY        vendedores.nome_vendedor, 
                                date_format(pedidos.data_pedido, '%Y-%m')),  
	menos_vendas AS 
( 
                SELECT 			vendedores.nome_vendedor, 
                                Date_format(pedidos.data_pedido, '%Y-%m') AS `ano_mes`, 
                                SUM(produtos.preco * item_pedidos.quantidade) AS `menor_vendido`,
                                rank() over ( partition BY vendedores.nome_vendedor ORDER BY sum(produtos.preco * item_pedidos.quantidade)) my_rank
                FROM            vendedores 
                JOIN            pedidos 
                ON              vendedores.codigo_vendedor = pedidos.codigo_vendedor 
                JOIN            item_pedidos 
                ON              pedidos.codigo_pedidos = item_pedidos.codigo_pedidos 
                JOIN            produtos 
                ON              item_pedidos.codigo_produto = produtos.codigo_produto 
                GROUP BY        vendedores.nome_vendedor, 
                                date_format(pedidos.data_pedido, '%Y-%m'))
SELECT mais_vendas.nome_vendedor, 
       mais_vendas.ano_mes AS `Mais vendas`,
       mais_vendas.ano_mes AS `Maior Comissão`,
       menos_vendas.ano_mes AS `Menos vendas`,
       menos_vendas.ano_mes AS `Menor comissão`
FROM   mais_vendas 
JOIN   menos_vendas
ON     mais_vendas.nome_vendedor = menos_vendas.nome_vendedor
WHERE  mais_vendas.my_rank =1 AND menos_vendas.my_rank =1;
/* 
e) Codigo Pedido, Codigo Produto, Fornecedor, Nome do Produto, Quantidade, Linha Produto, Vendedor, Região do Cliente, Data do Pedido
*/

SELECT pedidos.codigo_pedidos, 
       item_pedidos.codigo_produto, 
       fornecedores.nome_fornecedor,
       produtos.descricao AS `nome_produto`,
       item_pedidos.quantidade, 
       linha_produto.descricao_linha AS `linha_produto`,
       vendedores.nome_vendedor,
       regioes.nome_regiao AS `regiao_cliente`,
       pedidos.data_pedido 
FROM   pedidos 
       JOIN item_pedidos
         ON pedidos.codigo_pedidos = item_pedidos.codigo_pedidos 
	   JOIN produtos
         ON item_pedidos.codigo_produto = produtos.codigo_produto
	   JOIN fornecedores
         ON produtos.codigo_fornecedores = fornecedores.codigo_fornecedores
	   JOIN linha_produto
         ON produtos.linha_produto = linha_produto.linha_produto
	   JOIN vendedores
         ON pedidos.codigo_vendedor = vendedores.codigo_vendedor
	   JOIN clientes
         ON pedidos.codigo_cliente = clientes.codigo_cliente
	   JOIN regioes
         ON clientes.codigo_regiao = regioes.codigo_regiao
ORDER  BY (pedidos.codigo_pedidos); 

/* 
3 - Crie uma tabela chamada pedido_produto com os seguintes critérios (envie o código de criação da tabela e o código que insere os dados nela):

a) A chave primária da tabela tem que ser as colunas codigo_pedidos e codigo_produtos

b) A tabela tenha as informações da tabela pedidos, produtos, fornecedores e clientes

c) A tabela tenha um indice para codigo_cliente

d) A tabela tenha um indice para codigo_fornecedores
*/

CREATE TABLE IF NOT EXISTS pedido_produto AS
    SELECT
         pedidos.codigo_pedidos, 
         produtos.codigo_produto,
         SUM(item_pedidos.quantidade) AS `quantidade_produto`,
         clientes.codigo_cliente,
         clientes.codigo_regiao,
         fornecedores.codigo_fornecedores,
         pedidos.codigo_vendedor, 
         pedidos.data_pedido, 
         pedidos.data_entrega,
         produtos.linha_produto,
         produtos.descricao AS `nome_produto`,
         produtos.preco AS `preco_produto`,
		 produtos.quantidade_estoque AS `estoque_produto`,
         fornecedores.nome_fornecedor,
         fornecedores.endereco AS `endereco_fornecedor`,
         fornecedores.cidade AS `cidade_fornecedor`,
         fornecedores.estado AS `estado_fornecedor`,
         fornecedores.cep AS `cep_fornecedor`,
         fornecedores.telefone AS `telefone_fornecedor`,
         fornecedores.fax AS `fax_fornecedor`,
         clientes.nome AS `nome_cliente`,
         clientes.sobrenome AS `sobrenome_cliente`,
         clientes.endereco AS `endereco_cliente`,
         clientes.estado AS `estado_cliente`,
         clientes.cidade AS `cidade_cliente`,
         clientes.cep AS `cep_cliente`,
         clientes.telefone AS `telefone_cliente`,
         clientes.sexo AS `sexo_cliente`,
         clientes.estado_civil AS `estadocivil_cliente`
    FROM pedidos
        JOIN item_pedidos 
           ON pedidos.codigo_pedidos = item_pedidos.codigo_pedidos
        JOIN clientes 
           ON pedidos.codigo_cliente = clientes.codigo_cliente 
        JOIN produtos
           ON item_pedidos.codigo_produto = produtos.codigo_produto 
        JOIN fornecedores 
           ON produtos.codigo_fornecedores = fornecedores.codigo_fornecedores
    GROUP BY codigo_pedidos, codigo_produto       
    ORDER BY codigo_pedidos;

ALTER TABLE pedido_produto 
  ADD PRIMARY KEY (codigo_pedidos, codigo_produto), 
  ADD FOREIGN KEY (codigo_cliente) REFERENCES prova_bi.clientes (codigo_cliente),
  ADD FOREIGN KEY (codigo_fornecedores) REFERENCES prova_bi.fornecedores (codigo_fornecedores);
  
/* 
4 - O que é uma tabela fato?

R: Fato é tudo que é mensurável, seja através de contagem, soma, cálculo de média e etc.
Dimensão é a forma pela qual desejamos girar e dividir as informações para assim obtermos multiplas
formas de visualizar as informações. Uma tabela fato é a entidade que interliga através de chaves
estrangeiras as várias tabelas de dimensões associadas.
*/

/* 
5 - O que é um cubo?

R: Um cubo é uma estrutura de dados agrega e desagrega os fatos em uma ou mais dimensões, é uma ferramenta
de análise muito poderosa se utilizada de forma correta.
*/

/* 
6 - Quais colunas você recomendaria para criar um cubo com as informações do schema prova_bi ?

R: As colunas que fazem relações das tabelas de dimensão com a tabela fato (pedidos): codigo_pedidos, codigo_produto,
data_pedido, data_entrega, codigo_cliente, codigo_regiao, codigo_vendedor, codigo_fornecedores, linha_produto. 
*/