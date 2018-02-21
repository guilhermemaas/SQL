-- Lista a data e hora das entregas do período selecionado.
DECLARE @DataIni DATETIME
DECLARE @DataFim DATETIME

SET @DataIni = '2016-12-05 00:00:00'
SET @DataFim = '2016-12-06 23:59:59'

SELECT U.CdunidadeNegocio AS Empresa, R.CdRotaNegocio Rota, NF2.CdNotaFiscalNegocio NotaFiscal, C.CdClienteNegocio AS CodigoCliente, 
	   C.NmCliente AS NomeCliente, CONVERT(Varchar(10), E.DtEntrega,103) AS DataRota, 
	   format(E.DtRealizada,'dd/mm/yyyy hh:mm', 'pt-br') AS DataHoraEntrega,
	   E.DtRealizada AS DataHoraEntrega,
	   E.IdEntregaRealizada AS ENTREGA_REALIZADA 
	   FROM TB_ENTREGA E
INNER JOIN TB_UNIDADE_NEGOCIO U
      ON U.CdunidadeNegocio = E.CdUnidadeNegocio
INNER JOIN TB_CLIENTE C
      ON C.CdCliente = E.Cdcliente
INNER JOIN TB_Rota R
      ON E.CdRota = R.CdRota
INNER JOIN (
      SELECT E.CdEntrega,NF.CdNotaFiscalNegocio
      FROM TB_ENTREGA E
            INNER JOIN (
                  SELECT P.CdPedido,P.CdEntrega,N.CdNotaFiscalNegocio
                        FROM TB_NOTA_FISCAL N
                              INNER JOIN TB_PEDIDO P
                                   ON P.CdPedido = N.CdPedido
            ) AS NF
                  ON E.CdEntrega = NF.CdEntrega
            WHERE E.DtRealizada >= @DataIni AND E.DtRealizada <= @DataFim
) AS NF2
      ON E.CdEntrega = NF2.CdEntrega
WHERE E.DtRealizada >= @DataIni and E.DtRealizada <= @DataFim AND
      E.IdEntregaRealizada = 1 AND R.CdRotaNegocio>0
ORDER BY U.CdUnidadeNegocio, E.DtRealizada, E.CdCliente