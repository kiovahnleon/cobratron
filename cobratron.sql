CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    fecha_inicial DATE NOT NULL,
    fecha_final DATE NOT NULL,
    monto_pago NUMERIC(10, 2) NOT NULL,
    frecuencia_pago VARCHAR(20) NOT NULL
);

CREATE TABLE cobros (
    id SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
    fecha_cobro DATE NOT NULL,
    monto NUMERIC(10, 2) NOT NULL,
    pagado BOOLEAN DEFAULT FALSE
);

CREATE OR REPLACE FUNCTION calcular_cobros(cliente_id INT) RETURNS VOID AS $$
DECLARE
    fecha_actual DATE;
    fecha_limite DATE;
    frecuencia INTERVAL;
    monto NUMERIC(10, 2);
    frecuencia_pago_local VARCHAR(20);
BEGIN
    SELECT fecha_inicial, fecha_final, monto_pago, frecuencia_pago
    INTO fecha_actual, fecha_limite, monto, frecuencia_pago_local
    FROM clientes
    WHERE id = cliente_id;

    IF frecuencia_pago_local = 'Semanal' THEN
        frecuencia := '7 days';
    ELSIF frecuencia_pago_local = 'Mensual' THEN
        frecuencia := '1 month';
    ELSIF frecuencia_pago_local = 'Trimestral' THEN
        frecuencia := '3 months';
    ELSIF frecuencia_pago_local = 'Semestral' THEN
        frecuencia := '6 months';
    ELSIF frecuencia_pago_local = 'Anual' THEN
        frecuencia := '1 year';
    ELSE
        RAISE EXCEPTION 'Frecuencia de pago inválida: %', frecuencia_pago_local;
    END IF;

    WHILE fecha_actual <= fecha_limite LOOP
        -- x si cae en domingo
        IF EXTRACT(DOW FROM fecha_actual) = 0 THEN
            fecha_actual := fecha_actual + INTERVAL '1 day';
        END IF;

        INSERT INTO cobros (cliente_id, fecha_cobro, monto)
        VALUES (cliente_id, fecha_actual, monto);

        fecha_actual := fecha_actual + frecuencia;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION crear_cliente(
    nombre_cliente VARCHAR,
    fecha_inicial_cliente DATE,
    fecha_final_cliente DATE,
    monto_pago_cliente NUMERIC,
    frecuencia_pago_cliente VARCHAR
) RETURNS VOID AS $$
DECLARE
    cliente_id INT;
BEGIN
    INSERT INTO clientes (nombre, fecha_inicial, fecha_final, monto_pago, frecuencia_pago)
    VALUES (nombre_cliente, fecha_inicial_cliente, fecha_final_cliente, monto_pago_cliente, frecuencia_pago_cliente)
    RETURNING id INTO cliente_id;

    PERFORM calcular_cobros(cliente_id);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION reporte_cobros(p_cliente_id INT) RETURNS TABLE (
    fecha_cobro DATE,
    monto NUMERIC,
    pagado BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT c.fecha_cobro, c.monto, c.pagado
    FROM cobros AS c
    WHERE c.cliente_id = p_cliente_id
    ORDER BY c.fecha_cobro;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION aplicar_pago(p_cobro_id INT) RETURNS VOID AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM cobros WHERE id = p_cobro_id AND pagado = TRUE) THEN
        RAISE NOTICE 'El cobro con ID % ya fue pagado.', p_cobro_id;
        RETURN;
    END IF;

    UPDATE cobros
    SET pagado = TRUE
    WHERE id = p_cobro_id;

    RAISE NOTICE 'Pago aplicado correctamente al cobro con ID %.', p_cobro_id;
END;
$$ LANGUAGE plpgsql;


