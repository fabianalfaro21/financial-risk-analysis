-- =====================================================================
-- MÓDULO: Análisis de Riesgo Geográfico
-- PREGUNTA DE NEGOCIO: ¿Qué países concentran la mayor cantidad de 
-- clientes con historial de pago deficiente ('Poor')?
-- OBJETIVO: Evaluar si se deben endurecer los criterios de aprobación 
-- de créditos o investigar factores socioeconómicos en regiones específicas.
-- =====================================================================

SELECT 
    f.Country,
    COUNT(*) AS "Total Clientes en País",
    SUM(CASE WHEN f."Payment History" = 'Poor' THEN 1 ELSE 0 END) AS "Total Morosos",
    ROUND(
        (SUM(CASE WHEN f."Payment History" = 'Poor' THEN 1.0 ELSE 0 END) / COUNT(*)) * 100, 
        2
    ) AS "Tasa de Morosidad (%)"
FROM financial_risk_assessment f
GROUP BY f.Country
ORDER BY "Tasa de Morosidad (%)" DESC
LIMIT 10;

-- =====================================================================
-- MÓDULO: Análisis de Estrés Financiero por Cargas Familiares
-- PREGUNTA DE NEGOCIO: ¿Tienen los clientes con 2 o más dependientes un 
-- ratio de endeudamiento (Debt-to-Income) que rebase los límites de tolerancia al riesgo?
-- OBJETIVO: Evaluar el impacto de las cargas familiares en la capacidad de 
-- pago para fundamentar una decisión de negocio: limitar el cupo máximo de 
-- crédito o exigir garantías adicionales en este segmento.
-- =====================================================================

SELECT 
    COUNT(*) AS "Total Clientes con >= 2 Dependientes",
    ROUND(AVG(f."Debt-to-Income Ratio") * 100, 2) AS "DTI Promedio (%)",
    
    -- Cuántos superan un DTI de riesgo (ej. 45% o 0.45)
    SUM(CASE WHEN f."Debt-to-Income Ratio" > 0.45 THEN 1 ELSE 0 END) AS "Clientes en Zona de Riesgo (DTI > 45%)",
    
    -- Porcentaje del segmento que está en riesgo
    ROUND(
        (SUM(CASE WHEN f."Debt-to-Income Ratio" > 0.45 THEN 1.0 ELSE 0 END) / COUNT(*)) * 100, 
        2
    ) AS "Porcentaje del Segmento en Riesgo (%)"
FROM financial_risk_assessment f
WHERE f."Number of Dependents" >= 2.0;

-- =====================================================================
-- MÓDULO: Análisis de Préstamos por Desempleo
-- PREGUNTA DE NEGOCIO: ¿Para qué solicitan préstamos las personas desempleadas 
-- y cuál es el volumen de solicitudes por cada destino?
-- =====================================================================

SELECT 
    f."Loan Purpose",
    COUNT(*) AS "Cantidad de Préstamos",
    ROUND(AVG(f."Loan Amount"), 2) AS "Monto Promedio ($)"
FROM financial_risk_assessment f
WHERE f."Employment Status" = 'Unemployed'
GROUP BY f."Loan Purpose"
ORDER BY "Cantidad de Préstamos" DESC;

-- =====================================================================
-- MÓDULO: Análisis Multidimensional de Perfil Financiero y Estabilidad
-- PREGUNTA DE NEGOCIO: ¿Los clientes con historial 'Poor' se caracterizan 
-- por menores ingresos, mayor endeudamiento o menor estabilidad laboral?
-- OBJETIVO: Comparar la brecha de ingresos, ratio de deuda (DTI) y antigüedad 
-- laboral entre clientes de excelente y bajo desempeño de pago.
-- =====================================================================

SELECT 
    f."Payment History",
    ROUND(AVG(f.Income), 2) AS "Promedio de Ingresos",
    ROUND(AVG(f."Debt-to-Income Ratio") * 100, 2) AS "Porcentaje de Deuda (%)",
    ROUND(AVG(f."Years at Current Job"), 2) AS "Promedio de Años con Empleador Actual",
    COUNT(*) AS "Total de Clientes"
FROM financial_risk_assessment f
WHERE f."Payment History" IN ('Excellent', 'Poor')
GROUP BY f."Payment History";

-- =====================================================================
-- MÓDULO: Perfilamiento Demográfico de Riesgo
-- PREGUNTA DE NEGOCIO: ¿Qué rango de edad presenta el mayor porcentaje de 
-- morosidad y cómo se compara su volumen de préstamo promedio con el resto de la cartera?
-- OBJETIVO: Identificar segmentos etarios vulnerables para ajustar políticas 
-- de crédito o integrar programas de educación financiera.
-- =====================================================================

SELECT 
    CASE 
        WHEN f.Age < 30 THEN 'Joven (< 30)'
        WHEN f.Age BETWEEN 30 AND 45 THEN 'Adulto Joven (30 - 45)'
        WHEN f.Age BETWEEN 46 AND 60 THEN 'Adulto (46 - 60)'
        ELSE 'Senior (> 60)'
    END AS "Rango de Edad",
    
    COUNT(*) AS "Total Clientes",
    
    -- Cuenta cuántos clientes en el grupo tienen historial 'Poor'
    SUM(CASE WHEN f."Payment History" = 'Poor' THEN 1 ELSE 0 END) AS "Clientes Morosos",
    
    -- Calcula el porcentaje de morosidad dentro del rango
    ROUND(
        (SUM(CASE WHEN f."Payment History" = 'Poor' THEN 1.0 ELSE 0 END) / COUNT(*)) * 100, 
        2
    ) AS "Tasa Morosidad (%)",
    
    -- Volumen de préstamo promedio del segmento
    ROUND(AVG(f."Loan Amount"), 2) AS "Préstamo Promedio ($)"

FROM financial_risk_assessment f
GROUP BY "Rango de Edad"
ORDER BY "Tasa Morosidad (%)" DESC;

-- =====================================================================
-- MÓDULO: Relación Préstamo vs. Ingreso Anual (Loan-to-Income Ratio)
-- PREGUNTA DE NEGOCIO: ¿Cuál es el ratio Loan-to-Income promedio por historial 
-- de pago y cuántas veces su salario anual representa el préstamo para 'Poor'?
-- =====================================================================

SELECT 
    f."Payment History" AS "Historial de Pago",
    ROUND(AVG(f."Loan Amount"), 2) AS "Promedio Préstamo ($)",
    ROUND(AVG(f.Income), 2) AS "Promedio Ingreso Anual ($)",
    
    ROUND(AVG(CAST(f."Loan Amount" AS FLOAT) / f.Income), 2) AS "Loan-to-Income Promedio (Veces Salario)",
    
    ROUND(MAX(CAST(f."Loan Amount" AS FLOAT) / f.Income), 2) AS "Ratio Máximo (Veces Salario)"

FROM financial_risk_assessment f
WHERE f."Payment History" IN ('Excellent', 'Good', 'Fair', 'Poor')
GROUP BY f."Payment History"
ORDER BY "Loan-to-Income Promedio (Veces Salario)" DESC;

