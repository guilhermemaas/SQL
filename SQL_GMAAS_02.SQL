DECLARE @Geo                    VARCHAR(MAX);
DECLARE @CDD                    VARCHAR(MAX);
DECLARE @DtRota                 DATE;
DECLARE @QtTotalEntregas        INTEGER;
DECLARE @QtTotalTravadas        INTEGER;
DECLARE @PercentualTravadas     FLOAT;

SET @DtRota = '2017-10-10'

SELECT DsGrupoUnidadeNegocio,COUNT(CdEntrega) AS QtTotalTravadas
INTO #TOTAL_TRAVADAS_GEO
    FROM TB_X_TRAVADO_DETALHADO_LOG WITH(NOLOCK)
WHERE DtRota = @DtRota  
GROUP BY DsGrupoUnidadeNegocio
ORDER BY DsGrupoUnidadeNegocio

SELECT NmUnidadeNegocio,DsGrupoUnidadeNegocio,COUNT(CdEntrega) AS QtTotalTravadas
INTO #TOTAL_TRAVADAS_CDD
    FROM TB_X_TRAVADO_DETALHADO_LOG WITH(NOLOCK)
WHERE DtRota = @DtRota  
GROUP BY NmUnidadeNegocio, DsGrupoUnidadeNegocio
ORDER BY NmUnidadeNegocio

SELECT GUNU.CdUnidadeNegocio, GUN.DsGrupoUnidadeNegocio
	INTO #UNIDADE_TEMP
	FROM TB_GRUPO_UNIDADE_NEGOCIO_UNIDADE GUNU WITH(NOLOCK)
		INNER JOIN TB_GRUPO_UNIDADE_NEGOCIO GUN WITH(NOLOCK)
			ON GUNU.CdGrupoUnidadeNegocio = GUN.CdGrupoUnidadeNegocio
	WHERE GUN.DsGrupoUnidadeNegocio <> 'BRASIL'
ORDER BY GUNU.CdUnidadeNegocio

SELECT U.NmUnidadeNegocio,U.CdUnidadeNegocio, UT.DsGrupoUnidadeNegocio, R.CdRota
INTO #UNIDADE_ROTA_TEMP
    FROM TB_ROTA R 
        INNER JOIN TB_UNIDADE_NEGOCIO U 
            ON R.CdUnidadeNegocio = U.CdUnidadeNegocio
        INNER JOIN #UNIDADE_TEMP UT
            ON R.CdUnidadeNegocio = UT.CdUnidadeNegocio
    WHERE R.DtRota = @DtRota

SELECT U.DsGrupoUnidadeNegocio,U.NmUnidadeNegocio,COUNT(E.CdEntrega) AS QtTotalEntregas
INTO #TOTAL_ENTREGAS_CDD
    FROM TB_ENTREGA E WITH(NOLOCK)
		INNER JOIN TB_ROTA R WITH(NOLOCK)
			ON E.CdRota = R.CdRota
		INNER JOIN #UNIDADE_ROTA_TEMP U WITH(NOLOCK)
			ON E.CdRota = U.CdRota
WHERE E.DtEntrega = @DtRota   
AND R.DtSaidaDeposito IS NOT NULL
AND R.IdTipoRota <> 1
AND U.CdUnidadeNegocio NOT LIKE '%BR%'
GROUP BY U.DsGrupoUnidadeNegocio, U.NmUnidadeNegocio
ORDER BY U.NmUnidadeNegocio

SELECT 
	U.DsGrupoUnidadeNegocio,
	COUNT(E.CdEntrega) AS QtTotalEntregas
INTO #TOTAL_ENTREGAS_GEO
    FROM TB_ENTREGA E WITH(NOLOCK)
    INNER JOIN #UNIDADE_TEMP U WITH(NOLOCK)
        ON E.CdUnidadeNegocio = U.CdUnidadeNegocio
    INNER JOIN TB_ROTA R
        ON E.CdRota = R.CdRota
WHERE E.DtEntrega = @DtRota   
AND R.DtSaidaDeposito IS NOT NULL
AND R.IdTipoRota <> 1
AND U.CdUnidadeNegocio NOT LIKE '%BR%'
GROUP BY 
	U.DsGrupoUnidadeNegocio
ORDER BY 
	U.DsGrupoUnidadeNegocio

--- Insere na tabela de farol, o valor de 100% para o dia e Geos    

DECLARE InsertFarolGEO_100 CURSOR FOR

SELECT TEG.DsGrupoUnidadeNegocio AS Geo, TEG.QtTotalEntregas AS QtTotalEntregas, TTG.QtTotalTravadas AS QtTotalTravadas
    FROM #TOTAL_ENTREGAS_GEO TEG
    INNER JOIN #TOTAL_TRAVADAS_GEO TTG
        ON TEG.DsGrupoUnidadeNegocio = TTG.DsGrupoUnidadeNegocio
    ORDER BY TEG.DsGrupoUnidadeNegocio

OPEN InsertFarolGEO_100;

FETCH NEXT FROM InsertFarolGEO_100 INTO
    @Geo,                                     
    @QtTotalEntregas,
    @QtTotalTravadas;


WHILE @@FETCH_STATUS = 0

BEGIN

    INSERT INTO TB_FAROL_X_GEO (
        GEO,
        Data,
        TotalEntregas,
        TotalTravadas,
        PercentualTravadas
    ) VALUES(
        @Geo,
        @DtRota,
        @QtTotalEntregas,
        @QtTotalTravadas,
        100
    )

    FETCH NEXT FROM InsertFarolGEO_100 INTO
    @Geo,                                     
    @QtTotalEntregas,
    @QtTotalTravadas;

END

CLOSE InsertFarolGEO_100
DEALLOCATE InsertFarolGEO_100

--- Atualiza dados do farol, Corrige % conforme travamentos por Geo 

DECLARE InsertFarolGEO CURSOR FOR
 
SELECT TEG.DsGrupoUnidadeNegocio AS Geo, CAST(TTG.QtTotalTravadas AS DECIMAL(10,5))/CAST(TEG.QtTotalEntregas AS DECIMAL(10,5))*100 AS PercentualTravadas
    FROM #TOTAL_ENTREGAS_GEO TEG
    INNER JOIN #TOTAL_TRAVADAS_GEO TTG
        ON TEG.DsGrupoUnidadeNegocio = TTG.DsGrupoUnidadeNegocio
    ORDER BY TEG.DsGrupoUnidadeNegocio

OPEN InsertFarolGEO;

FETCH NEXT FROM InsertFarolGEO INTO
    @Geo,                                     
    @PercentualTravadas;

WHILE @@FETCH_STATUS = 0

BEGIN

    UPDATE TB_FAROL_X_GEO SET
        PercentualTravadas = PercentualTravadas - @PercentualTravadas
    WHERE 
    Data = @DtRota
    AND Geo = @Geo

    FETCH NEXT FROM InsertFarolGEO INTO
    @Geo,                                     
    @PercentualTravadas;

END

CLOSE InsertFarolGEO
DEALLOCATE InsertFarolGEO


---CDD INSERIR DADOS DO DIA, % 100

DECLARE InsertFarolCDD_100 CURSOR FOR

SELECT TECDD.NmUnidadeNegocio AS CDD, TECDD.DsGrupoUnidadeNegocio, TECDD.QtTotalEntregas AS QtTotalEntregas
    FROM #TOTAL_ENTREGAS_CDD TECDD
    ORDER BY TECDD.NmUnidadeNegocio

OPEN InsertFarolCDD_100 ;

FETCH NEXT FROM InsertFarolCDD_100  INTO
    @CDD,
    @Geo,                                
    @QtTotalEntregas;

WHILE @@FETCH_STATUS = 0

BEGIN

    INSERT INTO TB_FAROL_X_CDD (
        CDD,
        Geo,
        Data,
        TotalEntregas,
        TotalTravadas,
        PercentualTravadas
    ) VALUES(
        @CDD,
        @Geo,
        @DtRota,
        @QtTotalEntregas,
        0,
        100
    )

    FETCH NEXT FROM InsertFarolCDD_100  INTO
    @CDD,
    @Geo,                                     
    @QtTotalEntregas;

END

CLOSE InsertFarolCDD_100 
DEALLOCATE InsertFarolCDD_100 

-- ATUALIZA VALOR DE % POR CDD E DATA

DECLARE InsertFarolCDD CURSOR FOR

SELECT TTCDD.NmUnidadeNegocio AS CDD, TTCDD.QtTotalTravadas AS QtTotalTravadas, CAST(TTCDD.QtTotalTravadas AS DECIMAL(10,5))/CAST(TECDD.QtTotalEntregas AS DECIMAL(10,5))*100 AS PercentualTravadas
    FROM #TOTAL_ENTREGAS_CDD TECDD
    INNER JOIN #TOTAL_TRAVADAS_CDD TTCDD
        ON TECDD.NmUnidadeNegocio = TTCDD.NmUnidadeNegocio
    ORDER BY TTCDD.NmUnidadeNegocio

OPEN InsertFarolCDD;

FETCH NEXT FROM InsertFarolCDD INTO
    @CDD,                                    
    @QtTotalTravadas,  
    @PercentualTravadas;

WHILE @@FETCH_STATUS = 0

BEGIN

    UPDATE TB_FAROL_X_CDD SET
        TotalTravadas = @QtTotalTravadas,
        PercentualTravadas = PercentualTravadas - @PercentualTravadas
    WHERE
        CDD = @CDD
        AND Data = @DtRota

    FETCH NEXT FROM InsertFarolCDD  INTO
    @CDD,                                    
    @QtTotalTravadas,  
    @PercentualTravadas;

END

CLOSE InsertFarolCDD 
DEALLOCATE InsertFarolCDD 

DROP TABLE #UNIDADE_TEMP
DROP TABLE #UNIDADE_ROTA_TEMP
DROP TABLE #TOTAL_ENTREGAS_CDD
DROP TABLE #TOTAL_ENTREGAS_GEO
DROP TABLE #TOTAL_TRAVADAS_CDD
DROP TABLE #TOTAL_TRAVADAS_GEO

