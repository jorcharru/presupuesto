import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PresupuestoUsaScreen extends StatefulWidget {
  @override
  _PresupuestoUsaScreenState createState() => _PresupuestoUsaScreenState();
}

class _PresupuestoUsaScreenState extends State<PresupuestoUsaScreen> {
  List<Map<String, dynamic>> data = [];
  double total = 0;
  double pago = 0;
  double pendiente = 0;
  String _selectedMonth = 'Enero'; // Mes seleccionado por defecto
  final List<String> _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  // Controladores para los campos de texto
  List<TextEditingController> _conceptoControllers = [];
  List<TextEditingController> _valorControllers = [];

  // Valores predeterminados para la columna "Concepto" y "Valor"
  final List<String> _defaultConceptos = [
    "Cuota Carro", "Seguro Carros", "Tarjetas", "Gas", "Seguro Vida", "Carwash", "Spotify y Otros"
  ];
  final List<double> _defaultValores = [480, 280, 120, 300, 40, 30, 40];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('usa_data_$_selectedMonth');
    if (savedData != null) {
      setState(() {
        data = List<Map<String, dynamic>>.from(json.decode(savedData));
        _initializeControllers(); // Inicializar controladores con los datos cargados
        calcularTotales();
      });
    } else {
      setState(() {
        data = List.generate(_defaultConceptos.length, (index) {
          return {
            'concepto': _defaultConceptos[index],
            'valor': _defaultValores[index],
            'verf': false,
            'estado': 'PENDIENTE',
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
      return TextEditingController(text: item['valor']?.toString() ?? '');
    }).toList();
  }

  void _saveData() async {
    // Actualizar la lista `data` con los valores de los controladores
    for (int i = 0; i < data.length; i++) {
      data[i]['concepto'] = _conceptoControllers[i].text;
      data[i]['valor'] = double.tryParse(_valorControllers[i].text) ?? 0;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('usa_data_$_selectedMonth', json.encode(data));
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
    final formatter = NumberFormat('#,##0', 'en_US');
    return '\$${formatter.format(valor)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PRESUPUESTO USA'),
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
              // Cuadro de datos con bordes (cambiamos el color a azul claro)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    color: Colors.blue[100], // Azul claro
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
                                style: TextStyle(
                                  color: item['estado'] == 'PENDIENTE' ? Colors.red : Colors.black,
                                ),
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
                                decoration: InputDecoration(
                                  prefixText: '\$',
                                ),
                                onChanged: (value) {
                                  item['valor'] = double.tryParse(value) ?? 0;
                                  calcularTotales();
                                },
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
                        });
                        _conceptoControllers.add(TextEditingController());
                        _valorControllers.add(TextEditingController());
                      });
                    },
                    child: Text('Agregar línea'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (data.length > 8) {
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
                          Expanded(child: Text('VALOR')), // Cambiamos "PESOS" por "VALOR"
                        ],
                      ),
                      Divider(),
                      Row(
                        children: [
                          Expanded(child: Text('TOTAL')),
                          Expanded(child: Text(formatoMoneda(total))),
                        ],
                      ),
                      Divider(),
                      Row(
                        children: [
                          Expanded(child: Text('PAGO')),
                          Expanded(child: Text(formatoMoneda(pago))),
                        ],
                      ),
                      Divider(),
                      Row(
                        children: [
                          Expanded(child: Text('PENDIENTE')),
                          Expanded(child: Text(formatoMoneda(pendiente))),
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