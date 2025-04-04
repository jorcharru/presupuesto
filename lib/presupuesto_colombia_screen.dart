import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PresupuestoColombiaScreen extends StatefulWidget {
  @override
  _PresupuestoColombiaScreenState createState() =>
      _PresupuestoColombiaScreenState();
}

class _PresupuestoColombiaScreenState
    extends State<PresupuestoColombiaScreen> {
  List<Map<String, dynamic>> data = [];
  double total = 0;
  double pago = 0;
  double pendiente = 0;
  double precioDolar = 1;
  String _selectedMonth = 'Enero'; // Mes seleccionado por defecto
  final List<String> _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  // Controladores para los campos de texto
  List<TextEditingController> _conceptoControllers = [];
  List<TextEditingController> _valorControllers = [];
  TextEditingController _precioDolarController = TextEditingController();

  // Valores predeterminados para la columna "Concepto"
  final List<String> _defaultConceptos = [
    "Daniel", "Pensión Jenny", "Pensión Jorge", "Cuota Apto", "Servicios Apto",
    "Admon Apto", "Celular", "Icetex", "Arrendo Cartagena", "Servicios Cartagena",
    "Keren 1 Q.", "Keren 2 Q.", "Cristian 1 Q", "Cristian 2 Q"
  ];

  // Valores predeterminados para la columna "Valor"
  final List<String> _defaultValores = [
    "350000", "450000", "230000", "2450000", "100000", "300000", "100000", "280000",
    "700000", "150000", "350000", "350000", "150000", "150000"
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('colombia_data_$_selectedMonth');
    double? savedPrecioDolar = prefs.getDouble('precio_dolar_$_selectedMonth');
    if (savedData != null) {
      setState(() {
        data = List<Map<String, dynamic>>.from(json.decode(savedData));
        precioDolar = savedPrecioDolar ?? 1;
        _initializeControllers(); // Inicializar controladores con los datos cargados
        calcularTotales();
      });
    } else {
      setState(() {
        data = List.generate(_defaultConceptos.length, (index) {
          return {
            'concepto': _defaultConceptos[index],
            'valor': double.tryParse(_defaultValores[index]) ?? 0,
            'verf': false,
            'estado': 'PENDIENTE',
            'valorDolar': null,
          };
        });
        _initializeControllers(); // Inicializar controladores con datos predeterminados
      });
    }
  }

  void _initializeControllers() {
    _conceptoControllers = data.map((item) {
      return TextEditingController(text: item['concepto']?.toString() ?? '');
    }).toList();

    _valorControllers = data.map((item) {
      // Formatear el valor predeterminado con el símbolo "$" y el formato de miles
      return TextEditingController(text: formatoMoneda(item['valor'] ?? 0));
    }).toList();

    _precioDolarController = TextEditingController(text: precioDolar.toString());
  }

  void _saveData() async {
    // Actualizar la lista `data` con los valores de los controladores
    for (int i = 0; i < data.length; i++) {
      data[i]['concepto'] = _conceptoControllers[i].text;
      // Eliminar el símbolo "$" y los puntos antes de guardar el valor
      String valorSinFormato = _valorControllers[i].text.replaceAll('\$', '').replaceAll('.', '');
      data[i]['valor'] = double.tryParse(valorSinFormato) ?? 0;
    }

    precioDolar = double.tryParse(_precioDolarController.text) ?? 1;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('colombia_data_$_selectedMonth', json.encode(data));
    prefs.setDouble('precio_dolar_$_selectedMonth', precioDolar);
    calcularTotales();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Datos guardados para $_selectedMonth')),
    );
  }

  void calcularTotales() {
    setState(() {
      total = data.fold(0, (sum, item) => sum + (item['valor'] ?? 0));
      pago = data
          .where((item) => item['estado'] == 'PAGO')
          .fold(0, (sum, item) => sum + (item['valor'] ?? 0));
      pendiente = data
          .where((item) => item['estado'] == 'PENDIENTE')
          .fold(0, (sum, item) => sum + (item['valor'] ?? 0));
    });
  }

  String formatoMoneda(double valor) {
    if (valor == null) return '';
    final formatter = NumberFormat('#,##0', 'es_CO'); // Sin decimales
    return '\$${formatter.format(valor)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PRESUPUESTO COLOMBIA'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lista desplegable para seleccionar el mes
              DropdownButton<String>(
                value: _selectedMonth,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedMonth = newValue!;
                    _loadData(); // Cargar datos del mes seleccionado
                  });
                },
                items: _months.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              // Precio del dólar con fondo azul claro
              Container(
                color: Colors.blue[50], // Color azul claro
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    Text('Precio del dólar:'),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _precioDolarController,
                        keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          setState(() {
                            precioDolar =
                            value.isEmpty ? 1 : double.tryParse(value) ?? 1;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Cuadro de datos con bordes
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    color: Colors.yellow[100],
                  ),
                  child: Table(
                    defaultColumnWidth: IntrinsicColumnWidth(), // Ajusta el ancho al contenido
                    border: TableBorder(
                      verticalInside: BorderSide(width: 2, color: Colors.black),
                      horizontalInside: BorderSide(width: 1, color: Colors.black),
                    ),
                    children: [
                      // Encabezados
                      TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8), // Espacio horizontal
                            child: Text('CONCEPTO', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8), // Espacio horizontal
                            child: Text('VALOR', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8), // Espacio horizontal
                            child: Center( // Centrar el texto
                              child: Text('DOLAR', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8), // Espacio horizontal
                            child: Text('VERF', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8), // Espacio horizontal
                            child: Text('ESTADO', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      // Filas de datos
                      ...data.asMap().entries.map((entry) {
                        int index = entry.key;
                        var item = entry.value;
                        return TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8), // Espacio horizontal
                              child: TextFormField(
                                controller: _conceptoControllers[index],
                                onChanged: (value) {
                                  item['concepto'] = value;
                                },
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8), // Espacio horizontal
                              child: TextFormField(
                                controller: _valorControllers[index],
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  // Formatear el valor ingresado
                                  String formattedValue = value.replaceAll('\$', '').replaceAll('.', '');
                                  double parsedValue = double.tryParse(formattedValue) ?? 0;
                                  _valorControllers[index].text = formatoMoneda(parsedValue);
                                  item['valor'] = parsedValue;
                                  calcularTotales();
                                },
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8), // Espacio horizontal
                              child: Center( // Centrar el texto
                                child: Text(
                                  item['valor'] != null
                                      ? '\$${(item['valor']! / precioDolar).toStringAsFixed(2)}'
                                      : '\$0.00', // Dos decimales
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8), // Espacio horizontal
                              child: Checkbox(
                                value: item['verf'] ?? false,
                                onChanged: (value) {
                                  setState(() {
                                    item['verf'] = value ?? false;
                                    item['estado'] =
                                    (value ?? false) ? 'PAGO' : 'PENDIENTE';
                                    calcularTotales();
                                  });
                                },
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8), // Espacio horizontal
                              child: Text(item['estado'] ?? 'PENDIENTE'),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Botones para agregar y eliminar línea
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        data.add({
                          'concepto': '',
                          'valor': null,
                          'verf': false,
                          'estado': 'PENDIENTE',
                          'valorDolar': null,
                        });
                        _conceptoControllers.add(TextEditingController());
                        _valorControllers.add(TextEditingController(text: '\$0'));
                      });
                    },
                    child: Text('Agregar línea'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (data.length > 10) {
                        setState(() {
                          data.removeLast();
                          _conceptoControllers.removeLast();
                          _valorControllers.removeLast();
                          calcularTotales();
                        });
                      }
                    },
                    child: Text('Eliminar última línea'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // Botón para guardar los datos
              Center(
                child: ElevatedButton(
                  onPressed: _saveData,
                  child: Text('Guardar'),
                ),
              ),
              SizedBox(height: 20),
              // Cuadro de totales con borde rojo claro y centrado
              Center(
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 2),
                    color: Colors.red[100],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: SizedBox()),
                          Expanded(child: Text('PESOS')),
                          Expanded(child: Text('DOLAR')),
                        ],
                      ),
                      Divider(),
                      Row(
                        children: [
                          Expanded(child: Text('TOTAL')),
                          Expanded(child: Text(formatoMoneda(total))),
                          Expanded(child: Text('\$${(total / precioDolar).toStringAsFixed(2)}')),
                        ],
                      ),
                      Divider(),
                      Row(
                        children: [
                          Expanded(child: Text('PAGO')),
                          Expanded(child: Text(formatoMoneda(pago))),
                          Expanded(child: Text('\$${(pago / precioDolar).toStringAsFixed(2)}')),
                        ],
                      ),
                      Divider(),
                      Row(
                        children: [
                          Expanded(child: Text('PENDIENTE')),
                          Expanded(child: Text(formatoMoneda(pendiente))),
                          Expanded(child: Text('\$${(pendiente / precioDolar).toStringAsFixed(2)}')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}