use DB_NAME

DECLARE @CodigoGrupo bigint
DECLARE @NomeGrupo varchar(200)

DECLARE @dataFim DATE
DECLARE @dataIni DATE
DECLARE @dataIniAderencia DATE
DECLARE @dataFimAderencia DATE
DECLARE @percentual FLOAT
DECLARE @total INT
DECLARE @iniciadas INT
DECLARE @finalizadas INT
DECLARE @naoIniciadas INT
DECLARE @aderenciaMes FLOAT
DECLARE @aderenciaDMenos1 FLOAT
DECLARE @aderenciaAno FLOAT
DECLARE @temRotaHoje INT
DECLARE @teveRotaOntem INT
DECLARE @diaSemana INT
DECLARE @QtEntrega INT
DECLARE @QtAderencia INT
DECLARE @QtEntregaMes INT
DECLARE @QtAderenciaMes INT
DECLARE @QtEntregaAno INT
DECLARE @QtAderenciaAno INT



CREATE TABLE #rotasNaoIniciadas
(
    CdUnidadeNegocio VARCHAR(7),
	NmUnidade VARCHAR(25),
    QtTotalRota INT,
    QtIniciadas INT,
    QtFinalizadas INT,
    QtNaoIniciadas INT,
    VlPercentual FLOAT,
    VlAderenciaMes FLOAT,
    VlAderenciaDMenos1 FLOAT,
    VlAderenciaAno FLOAT,
	QtEntrega INT,
	QtAderencia INT,
	QtEntregaMes INT,
	QtAderenciaMes INT,
	QtEntregaAno INT,
	QtAderenciaAno INT
)



CREATE TABLE #VeiculosRotasIniciadas
(
    CdPlacaVeiculo varchar(20) COLLATE Latin1_General_CI_AI,
	IdRastreado bit
)


insert into #VeiculosRotasIniciadas(CdPlacaVeiculo, IdRastreado)
select distinct v.CdPlacaVeiculo, v.IdRastreado
from TB_VEICULO v WITH (NOLOCK)
inner join TB_ROTA r WITH (NOLOCK)
on v.CdPlacaVeiculo = r.CdPlacaVeiculo
where r.DtRota >= CAST(GETDATE() - 30 AS DATE)
	AND r.DtPartidaRealizada IS NOT NULL
	AND v.IdRastreado = 1




SET @dataIni = DATEADD(DAY, - DATEPART(dd,GETDATE() -1), GETDATE())
SET @dataFim = CAST(GETDATE() AS DATE)


SET @dataFimAderencia =
					(
					CASE WHEN DATEPART(WEEKDAY, DATEADD(DAY, -1, @dataFim)) = 1
					THEN
						DATEADD(DAY, -2, @dataFim)
					ELSE
						DATEADD(DAY, -1, @dataFim)
					END
					)

DECLARE gruposUnidades CURSOR FOR

SELECT g.CdGrupoUnidadeNegocio, g.DsGrupoUnidadeNegocio
FROM TB_GRUPO_UNIDADE_NEGOCIO g
WHERE g.CdGrupoUnidadeNegocio <> 4 -- Exclui a GEO BRASIL

OPEN gruposUnidades;

FETCH NEXT FROM gruposUnidades INTO @CodigoGrupo, @NomeGrupo;

WHILE @@FETCH_STATUS = 0
BEGIN

	SET @dataIniAderencia = 
						(
							SELECT MIN(r.DtRota)
							FROM TB_ROTA r WITH (NOLOCK)
							INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO_UNIDADE gu WITH (NOLOCK)
							ON gu.CdUnidadeNegocio = r.CdUnidadeNegocio
							INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO g WITH (NOLOCK)
							ON g.CdGrupoUnidadeNegocio = gu.CdGrupoUnidadeNegocio
							WHERE gu.CdGrupoUnidadeNegocio = @CodigoGrupo
								AND r.IdExpurgada = 0
								AND r.DtPartidaRealizada IS NOT NULL
								AND r.CdTipoSegmento = 1
								and r.DtSaidaDeposito is not null
							HAVING COUNT(r.DtPartidaRealizada) > 2
						)
						
	SET @dataIniAderencia =
						(
							CASE WHEN DATEPART(YEAR, @dataIniAderencia) < DATEPART(YEAR, GETDATE())
							THEN
								DATEADD(DAYOFYEAR, - DATEPART(DAYOFYEAR, @dataIni) + 1, @dataIni)
							ELSE
								@dataIniAderencia
							END
						)
						
	SET @dataIniAderencia =
						(
							CASE WHEN @dataIniAderencia > @dataFimAderencia
							THEN
								@dataFimAderencia
							ELSE
								@dataIniAderencia
							END
						)
	
	SET @temRotaHoje =	(
							SELECT CAST(COUNT(r.CdRota) AS FLOAT)
							FROM TB_ROTA r WITH (NOLOCK)
							INNER JOIN #VeiculosRotasIniciadas v
							ON r.CdPlacaVeiculo = v.CdPlacaVeiculo
							INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO_UNIDADE gu WITH (NOLOCK)
							ON gu.CdUnidadeNegocio = r.CdUnidadeNegocio
							INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO g WITH (NOLOCK)
							ON g.CdGrupoUnidadeNegocio = gu.CdGrupoUnidadeNegocio
							WHERE gu.CdGrupoUnidadeNegocio = @CodigoGrupo
								AND r.CdTipoSegmento = 1
								AND r.IdExpurgada = 0
								AND r.DtRota = @dataFim
								AND v.IdRastreado = 1
						)
	SET @teveRotaOntem =
						(
							SELECT CAST(COUNT(R.CdRota) AS FLOAT)
							FROM TB_ROTA r WITH (NOLOCK)
							INNER JOIN #VeiculosRotasIniciadas v
							ON r.CdPlacaVeiculo = v.CdPlacaVeiculo
							INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO_UNIDADE gu WITH (NOLOCK)
							ON gu.CdUnidadeNegocio = r.CdUnidadeNegocio
							INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO g WITH (NOLOCK)
							ON g.CdGrupoUnidadeNegocio = gu.CdGrupoUnidadeNegocio
							WHERE gu.CdGrupoUnidadeNegocio = @CodigoGrupo
								AND r.CdTipoSegmento = 1
								AND r.IdExpurgada = 0
								AND r.DtRota = @dataFimAderencia
								AND v.IdRastreado = 1
						)
	SET @iniciadas =	(
							SELECT CAST(COUNT(R.Cdrota) AS FLOAT)
							FROM TB_ROTA r WITH (NOLOCK) 
							INNER JOIN #VeiculosRotasIniciadas v
							ON r.CdPlacaVeiculo = v.CdPlacaVeiculo
							INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO_UNIDADE gu WITH (NOLOCK)
							ON gu.CdUnidadeNegocio = r.CdUnidadeNegocio
							INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO g WITH (NOLOCK)
							ON g.CdGrupoUnidadeNegocio = gu.CdGrupoUnidadeNegocio
							WHERE gu.CdGrupoUnidadeNegocio = @CodigoGrupo
								AND r.CdTipoSegmento = 1
								AND r.IdTipoRota = 0
								AND (r.DtPartidaRealizada IS NOT NULL AND r.DtChegadaRealizada IS NULL)
								AND r.DtRota = @dataFim
								AND r.IdExpurgada = 0
								AND v.IdRastreado = 1
						)
	SET @finalizadas =	(
							SELECT CAST(COUNT(R.CdRota) AS FLOAT)
							FROM TB_ROTA r WITH (NOLOCK)
							INNER JOIN #VeiculosRotasIniciadas v
							ON r.CdPlacaVeiculo = v.CdPlacaVeiculo
							INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO_UNIDADE gu WITH (NOLOCK)
							ON gu.CdUnidadeNegocio = r.CdUnidadeNegocio
							INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO g WITH (NOLOCK)
							ON g.CdGrupoUnidadeNegocio = gu.CdGrupoUnidadeNegocio
							WHERE gu.CdGrupoUnidadeNegocio = @CodigoGrupo
								AND r.CdTipoSegmento = 1
								AND r.IdTipoRota = 0
								AND (r.DtChegadaRealizada IS NOT NULL AND r.DtPartidaRealizada IS NOT NULL)
								AND r.DtRota = @dataFim
								AND r.IdExpurgada = 0
								AND v.IdRastreado = 1
						)
	SET @naoIniciadas = (
							SELECT CAST(COUNT(R.CdRota) AS FLOAT)
							FROM TB_ROTA r WITH (NOLOCK)
							INNER JOIN #VeiculosRotasIniciadas v
							ON r.CdPlacaVeiculo = v.CdPlacaVeiculo
							INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO_UNIDADE gu WITH (NOLOCK)
							ON gu.CdUnidadeNegocio = r.CdUnidadeNegocio
							INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO g WITH (NOLOCK)
							ON g.CdGrupoUnidadeNegocio = gu.CdGrupoUnidadeNegocio
							WHERE gu.CdGrupoUnidadeNegocio = @CodigoGrupo
								AND r.CdTipoSegmento = 1
								AND r.IdTipoRota = 0
								AND r.DtPartidaRealizada IS NULL
								AND r.DtRota = @dataFim
								AND r.IdExpurgada = 0
								AND v.IdRastreado = 1
						)
	SET @total =		(
							SELECT CAST(COUNT(R.CdRota) AS FLOAT)
							FROM TB_ROTA r WITH (NOLOCK)
							INNER JOIN #VeiculosRotasIniciadas v
							ON r.CdPlacaVeiculo = v.CdPlacaVeiculo
							INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO_UNIDADE gu WITH (NOLOCK)
							ON gu.CdUnidadeNegocio = r.CdUnidadeNegocio
							INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO g WITH (NOLOCK)
							ON g.CdGrupoUnidadeNegocio = gu.CdGrupoUnidadeNegocio
							WHERE gu.CdGrupoUnidadeNegocio = @CodigoGrupo
								AND r.CdTipoSegmento = 1
								AND r.IdTipoRota = 0
								AND r.DtRota = @dataFim
								AND r.IdExpurgada = 0
								AND v.IdRastreado = 1
						)
	SET @percentual =	(
							SELECT
							CASE WHEN
							/* Verifica se o n�mero de rotas � maior que ZERO */
								(@temRotaHoje) > 0
							THEN
							/* Se for, conta a quantidade de rotas n�o iniciadas e multiplica por 100
							para dividir pela quantidade de rotas iniciadas e obter a porcentagem */
							(
								SELECT CAST(@naoIniciadas AS FLOAT)
							)/
							(
								SELECT CAST(@total AS FLOAT)
							)
							ELSE
								(SELECT 0)
							END
						)
	SET @aderenciaMes =	(
							SELECT
							CASE WHEN
							/* Verifica se o n�mero de rotas � maior que ZERO */
								@teveRotaOntem > 0 OR @temRotaHoje > 0
							THEN
							/* Obt�m ader�ncia da Unidade */
							(
								SELECT ISNULL(ROUND(SUM(CAST(e.IdPosicaoCorreta AS DECIMAL))/COUNT(e.CdEntrega),2),0)
								FROM TB_ROTA r WITH (NOLOCK)
								INNER JOIN TB_ENTREGA e WITH (NOLOCK)
								ON r.CdRota = e.CdRota
								INNER JOIN #VeiculosRotasIniciadas v
								ON r.CdPlacaVeiculo = v.CdPlacaVeiculo
								INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO_UNIDADE gu WITH (NOLOCK)
								ON gu.CdUnidadeNegocio = r.CdUnidadeNegocio
								INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO g WITH (NOLOCK)
								ON g.CdGrupoUnidadeNegocio = gu.CdGrupoUnidadeNegocio
								WHERE gu.CdGrupoUnidadeNegocio = @CodigoGrupo
									AND r.CdTipoSegmento = 1
									AND r.DtRota BETWEEN @dataIni AND @dataFimAderencia
									AND r.CdPlacaVeiculo NOT IN ('REC0001', 'REC0003')
									AND r.IdExpurgada = 0
									AND v.IdRastreado = 1
									and r.DtSaidaDeposito is not null
							)
							ELSE
								(SELECT 0)
							END
						)
	SET @aderenciaDMenos1 = (
								SELECT
								CASE WHEN
								/* Verifica se o n�mero de rotas � maior que ZERO */
									@teveRotaOntem > 0 OR @temRotaHoje > 0
								THEN
								/* Obt�m ader�ncia da Unidade no dia anterior */
								(
									SELECT ISNULL(ROUND(SUM(CAST(e.IdPosicaoCorreta AS DECIMAL))/COUNT(e.CdEntrega),2),0)
									FROM TB_ROTA r WITH (NOLOCK)
									INNER JOIN TB_ENTREGA e WITH (NOLOCK)
									ON R.CdRota = e.CdRota
									INNER JOIN #VeiculosRotasIniciadas v
									ON r.CdPlacaVeiculo = v.CdPlacaVeiculo
									INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO_UNIDADE gu WITH (NOLOCK)
									ON gu.CdUnidadeNegocio = r.CdUnidadeNegocio
									INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO g WITH (NOLOCK)
									ON g.CdGrupoUnidadeNegocio = gu.CdGrupoUnidadeNegocio
									WHERE gu.CdGrupoUnidadeNegocio = @CodigoGrupo
										AND r.CdTipoSegmento = 1
										AND r.DtRota = @dataFimAderencia
										AND r.CdPlacaVeiculo NOT IN ('REC0001', 'REC0003')
										AND r.IdExpurgada = 0
										AND v.IdRastreado = 1
										and r.DtEntradaDeposito is not null
										and r.DtSaidaDeposito is not null
								)
								ELSE
									(SELECT 0)
								END
						)
	SET @aderenciaAno = (
							SELECT
							CASE WHEN
							/* Verifica se o n�mero de rotas � maior que ZERO */
								@teveRotaOntem > 0 OR @temRotaHoje > 0
							THEN
							/* Obt�m ader�ncia da Unidade durante o ano */
							(
								SELECT ISNULL(ROUND(SUM(CAST(e.IdPosicaoCorreta AS DECIMAL))/COUNT(e.CdEntrega),2),0)
								FROM TB_ROTA r WITH (NOLOCK)
								INNER JOIN TB_ENTREGA e WITH (NOLOCK)
								ON r.CdRota = e.CdRota
								INNER JOIN #VeiculosRotasIniciadas v
								ON r.CdPlacaVeiculo = v.CdPlacaVeiculo
								INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO_UNIDADE gu WITH (NOLOCK)
								ON gu.CdUnidadeNegocio = r.CdUnidadeNegocio
								INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO g WITH (NOLOCK)
								ON g.CdGrupoUnidadeNegocio = gu.CdGrupoUnidadeNegocio
								WHERE gu.CdGrupoUnidadeNegocio = @CodigoGrupo
									AND r.CdTipoSegmento = 1
									AND r.DtRota BETWEEN @dataIniAderencia AND @dataFimAderencia
									AND r.CdPlacaVeiculo NOT IN ('REC0001', 'REC0003')
									AND r.IdExpurgada = 0
									AND v.IdRastreado = 1
									and r.DtSaidaDeposito is not null
							)
							ELSE
								(SELECT 0)
							END
						)
	SET @QtEntrega = (
							SELECT COUNT(isnull(e.CdEntrega, 0))
							FROM TB_ENTREGA e WITH (NOLOCK)
							INNER JOIN TB_ROTA r WITH (NOLOCK)
							ON e.CdRota = r.CdRota
							INNER JOIN #VeiculosRotasIniciadas v
							ON r.CdPlacaVeiculo = v.CdPlacaVeiculo
							INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO_UNIDADE gu WITH (NOLOCK)
							ON gu.CdUnidadeNegocio = r.CdUnidadeNegocio
							INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO g WITH (NOLOCK)
							ON g.CdGrupoUnidadeNegocio = gu.CdGrupoUnidadeNegocio
							WHERE gu.CdGrupoUnidadeNegocio = @CodigoGrupo
								AND r.CdTipoSegmento = 1
								AND r.IdTipoRota = 0
								AND r.DtRota = @dataFimAderencia
								AND r.IdExpurgada = 0
								AND v.IdRastreado = 1
								and r.DtSaidaDeposito is not null
						
						)
	SET @QtAderencia = (
							SELECT COUNT(isnull(e.CdEntrega, 0))
							FROM TB_ENTREGA e WITH (NOLOCK)
							INNER JOIN TB_ROTA r WITH (NOLOCK)
							ON e.CdRota = r.CdRota
							INNER JOIN #VeiculosRotasIniciadas v
							ON r.CdPlacaVeiculo = v.CdPlacaVeiculo
							INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO_UNIDADE gu WITH (NOLOCK)
							ON gu.CdUnidadeNegocio = r.CdUnidadeNegocio
							INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO g WITH (NOLOCK)
							ON g.CdGrupoUnidadeNegocio = gu.CdGrupoUnidadeNegocio
							WHERE gu.CdGrupoUnidadeNegocio = @CodigoGrupo
								AND r.CdTipoSegmento = 1
								AND r.IdTipoRota = 0
								AND r.DtRota = @dataFimAderencia
								AND r.IdExpurgada = 0
								AND e.IdPosicaoCorreta = 1
								AND v.IdRastreado = 1
								and r.DtSaidaDeposito is not null
						)	
	SET @QtEntregaMes =	(
							SELECT
							CASE WHEN
							/* Verifica se o n�mero de rotas � maior que ZERO */
								@teveRotaOntem > 0 OR @temRotaHoje > 0
							THEN
							/* Obt�m ader�ncia da Unidade */
							(
								SELECT  COUNT(e.CdEntrega)
								FROM TB_ROTA r WITH (NOLOCK)
								INNER JOIN TB_ENTREGA e WITH (NOLOCK)
								ON r.CdRota = e.CdRota
								INNER JOIN #VeiculosRotasIniciadas v
								ON r.CdPlacaVeiculo = v.CdPlacaVeiculo
								INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO_UNIDADE gu WITH (NOLOCK)
								ON gu.CdUnidadeNegocio = r.CdUnidadeNegocio
								INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO g WITH (NOLOCK)
								ON g.CdGrupoUnidadeNegocio = gu.CdGrupoUnidadeNegocio
								WHERE gu.CdGrupoUnidadeNegocio = @CodigoGrupo
									AND r.CdTipoSegmento = 1
									AND r.DtRota BETWEEN @dataIni AND @dataFimAderencia
									AND r.CdPlacaVeiculo NOT IN ('REC0001', 'REC0003')
									AND r.IdExpurgada = 0
									AND v.IdRastreado = 1
									and r.DtSaidaDeposito is not null
							
							)
							ELSE
								(SELECT 0)
							END
						)
	SET @QtAderenciaMes =	(
								SELECT
								CASE WHEN
								/* Verifica se o n�mero de rotas � maior que ZERO */
									@teveRotaOntem > 0 OR @temRotaHoje > 0
								THEN
								/* Obt�m ader�ncia da Unidade */
								(
									SELECT  COUNT(e.CdEntrega)
									FROM TB_ROTA r WITH (NOLOCK)
									INNER JOIN TB_ENTREGA e WITH (NOLOCK)
									ON r.CdRota = e.CdRota
									INNER JOIN #VeiculosRotasIniciadas v
									ON r.CdPlacaVeiculo = v.CdPlacaVeiculo
									INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO_UNIDADE gu WITH (NOLOCK)
									ON gu.CdUnidadeNegocio = r.CdUnidadeNegocio
									INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO g WITH (NOLOCK)
									ON g.CdGrupoUnidadeNegocio = gu.CdGrupoUnidadeNegocio
									WHERE gu.CdGrupoUnidadeNegocio = @CodigoGrupo
										AND r.CdTipoSegmento = 1
										AND r.DtRota BETWEEN @dataIni AND @dataFimAderencia
										AND r.CdPlacaVeiculo NOT IN ('REC0001', 'REC0003')
										AND r.IdExpurgada = 0
										AND e.IdPosicaoCorreta = 1
										AND v.IdRastreado = 1
										and r.DtSaidaDeposito is not null
								)
								ELSE
									(SELECT 0)
								END
						)	
	SET @QtEntregaAno = (
								SELECT
								CASE WHEN
								/* Verifica se o n�mero de rotas � maior que ZERO */
									@teveRotaOntem > 0 OR @temRotaHoje > 0
								THEN
								/* Obt�m ader�ncia da Unidade durante o ano */
								(
									SELECT COUNT(e.CdEntrega)
									FROM TB_ROTA r WITH (NOLOCK)
									INNER JOIN TB_ENTREGA e WITH (NOLOCK)
									ON r.CdRota = e.CdRota
									INNER JOIN #VeiculosRotasIniciadas v
									ON r.CdPlacaVeiculo = v.CdPlacaVeiculo
									INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO_UNIDADE gu WITH (NOLOCK)
									ON gu.CdUnidadeNegocio = r.CdUnidadeNegocio
									INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO g WITH (NOLOCK)
									ON g.CdGrupoUnidadeNegocio = gu.CdGrupoUnidadeNegocio
									WHERE gu.CdGrupoUnidadeNegocio = @CodigoGrupo
										AND r.CdTipoSegmento = 1
										AND r.DtRota BETWEEN @dataIniAderencia AND @dataFimAderencia
										AND r.CdPlacaVeiculo NOT IN ('REC0001', 'REC0003')
										AND r.IdExpurgada = 0
										AND v.IdRastreado = 1
										and r.DtSaidaDeposito is not null
								)
								ELSE
									(SELECT 0)
								END
						)
	SET @QtAderenciaAno = (
								SELECT
								CASE WHEN
								/* Verifica se o n�mero de rotas � maior que ZERO */
									@teveRotaOntem > 0 OR @temRotaHoje > 0
								THEN
								/* Obt�m ader�ncia da Unidade durante o ano */
								(
									SELECT COUNT(e.CdEntrega)
									FROM TB_ROTA r WITH (NOLOCK)
									INNER JOIN TB_ENTREGA e WITH (NOLOCK)
									ON r.CdRota = e.CdRota
									INNER JOIN #VeiculosRotasIniciadas v
									ON r.CdPlacaVeiculo = v.CdPlacaVeiculo
									INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO_UNIDADE gu WITH (NOLOCK)
									ON gu.CdUnidadeNegocio = r.CdUnidadeNegocio
									INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO g WITH (NOLOCK)
									ON g.CdGrupoUnidadeNegocio = gu.CdGrupoUnidadeNegocio
									WHERE gu.CdGrupoUnidadeNegocio = @CodigoGrupo
										AND r.CdTipoSegmento = 1
										AND r.DtRota BETWEEN @dataIniAderencia AND @dataFimAderencia
										AND r.CdPlacaVeiculo NOT IN ('REC0001', 'REC0003')
										AND r.IdExpurgada = 0
										AND e.IdPosicaoCorreta = 1
										AND v.IdRastreado = 1
										and r.DtSaidaDeposito is not null
								)
								ELSE
									(SELECT 0)
								END
						)
	PRINT @NomeGrupo
	PRINT @dataIniAderencia
	PRINT @dataFimAderencia

	INSERT INTO #rotasNaoIniciadas
	VALUES (@CodigoGrupo, @NomeGrupo, @total, @iniciadas,  @finalizadas, @naoIniciadas,
			@percentual, @aderenciaMes, @aderenciaDMenos1, @aderenciaAno, @QtEntrega, @QtAderencia, @QtEntregaMes, @QtAderenciaMes,
		    @QtEntregaAno, @QtAderenciaAno)
	FETCH NEXT FROM gruposUnidades INTO @CodigoGrupo, @NomeGrupo

END

DECLARE @DataCriacao DATE
SET @DataCriacao = CAST(GETDATE() AS DATE)

INSERT INTO TB_FAROL_ROTAS_GEO (DsGrupoUnidadeNegocio, QtTotalRota, QtIniciadas, QtFinalizadas,
									  QtNaoIniciadas, VlPercentual,
									  VlAderenciaDMenos1,QtEntrega, QtAderencia,
									  VlAderenciaMes,QtEntregaMes,QtAderenciaMes,
									  VlAderenciaAno,QtEntregaAno,QtAderenciaAno, DtCriacao)
SELECT	NmUnidade, QtTotalRota, QtIniciadas, QtFinalizadas, QtNaoIniciadas, VlPercentual,
		VlAderenciaDMenos1,QtEntrega, QtAderencia,
		VlAderenciaMes,QtEntregaMes,QtAderenciaMes,
	    VlAderenciaAno,QtEntregaAno,QtAderenciaAno, DtCriacao = @DataCriacao
FROM #rotasNaoIniciadas r
ORDER BY VlPercentual DESC, QtTotalRota DESC, VlAderenciaMes DESC


CLOSE gruposUnidades;
DEALLOCATE gruposUnidades;
PRINT @dataIni
PRINT @dataFim


DROP TABLE #rotasNaoIniciadas
DROP TABLE #VeiculosRotasIniciadas

GO