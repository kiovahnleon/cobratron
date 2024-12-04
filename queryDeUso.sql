SELECT crear_cliente('Anselmo Vizcarraga', '2024-01-01', '2024-12-31', 100.00, 'Mensual');

SELECT crear_cliente('Guandolar Batman', '2024-02-01', '2024-08-01', 150.00, 'Semestral');

SELECT aplicar_pago(1);

SELECT aplicar_pago(2);

SELECT * FROM reporte_cobros(1);

SELECT * FROM reporte_cobros(2);


