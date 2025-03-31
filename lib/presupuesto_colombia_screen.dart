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
  double totalPesos = 0;
  double pagoPesos = 0;
  double pendientePesos = 0;
  String _selectedMonth = 'Enero';
  String _selectedEstadoFilter = 'Todo';
  final List<String> _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  List<TextEditingController> _conceptoControllers = [];
  List<TextEditingController> _valorControllers = [];
  TextEditingController _disponibleController = TextEditingController();
  double faltante = 0;

  final List<String> _defaultConceptos = [
    "Arrendo", "Comida", "Servicios"
  ];
  // Valores predeterminados para la columna "Valor"
  final List<String> _defaultValores = [
    "700000", "600000", "150000"
  ];

  @override
  void initState() {
    super.initState();
    _loadLastSelectedMonth();
    _loadData();
  }

  void _loadLastSelectedMonth() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastMonth = prefs.getString('last_selected_month');
    if (lastMonth != null) {
      setState(() {
        _selectedMonth = lastMonth;
      });
      _loadData(); // Cargar los datos del mes seleccionado inmediatamente
    }
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('colombia_data_$_selectedMonth');
    double? savedDisponible = prefs.getDouble('disponible_$_selectedMonth');
    double? savedFaltante = prefs.getDouble('faltante_$_selectedMonth');

    if (savedData != null) {
      setState(() {
        data = List<Map<String, dynamic>>.from(json.decode(savedData));
        _initializeControllers();
        calcularTotales();
        _disponibleController.text = formatoMoneda(savedDisponible ?? 0);
        faltante = savedFaltante ?? 0;
      });
    } else {
      setState(() {
        data = List.generate(_defaultConceptos.length, (index) {
          return {
            'concepto': _defaultConceptos[index],
            'valor': double.tryParse(_defaultValores[index]) ?? 0,
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
      // Formatear el valor predeterminado con el símbolo "$" y el formato de miles
      return TextEditingController(text: formatoMoneda(item['valor'] ?? 0));
    }).toList();

    _disponibleController = TextEditingController();
  }

  void _saveData() async {
    for (int i = 0; i < data.length; i++) {
      data[i]['concepto'] = _conceptoControllers[i].text;
      String valorSinFormato = _valorControllers[i].text.replaceAll('\$', '').replaceAll('.', '');
      data[i]['valor'] = double.tryParse(valorSinFormato) ?? 0;
    }

    double disponible = double.tryParse(_disponibleController.text.replaceAll('\$', '').replaceAll('.', '')) ?? 0;
    double faltante = pendientePesos - disponible;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('colombia_data_$_selectedMonth', json.encode(data));
    prefs.setDouble('disponible_$_selectedMonth', disponible);
    prefs.setDouble('faltante_$_selectedMonth', faltante);
    prefs.setString('last_selected_month', _selectedMonth);

    setState(() {
      calcularTotales();
    });
  }

  void calcularTotales() {
    setState(() {
      totalPesos = data.fold(0, (sum, item) => sum + (item['valor'] ?? 0));

      pagoPesos = data
          .where((item) => item['estado'] == 'PAGO')
          .fold(0, (sum, item) => sum + (item['valor'] ?? 0));

      pendientePesos = data
          .where((item) => item['estado'] == 'PENDIENTE')
          .fold(0, (sum, item) => sum + (item['valor'] ?? 0));

      double disponible = double.tryParse(_disponibleController.text.replaceAll('\$', '').replaceAll('.', '')) ?? 0;
      faltante = pendientePesos - disponible;
    });
  }

  String formatoMoneda(double valor) {
    if (valor == null) return '';
    final formatter = NumberFormat('#,##0', 'es_CO');
    return '\$${formatter.format(valor)}';
  }

  String formatoMonedaConDecimales(double valor) {
    if (valor == null) return '';
    final formatter = NumberFormat('#,##0.00', 'es_CO');
    return '\$${formatter.format(valor)}';
  }

  List<Map<String, dynamic>> getFilteredData() {
    List<Map<String, dynamic>> filteredData = data;

    if (_selectedEstadoFilter == 'Pago') {
      filteredData = filteredData.where((item) => item['estado'] == 'PAGO').toList();
    } else if (_selectedEstadoFilter == 'Pendiente') {
      filteredData = filteredData.where((item) => item['estado'] == 'PENDIENTE').toList();
    }

    return filteredData;
  }

  // Función para calcular el total de los datos visibles (filtrados)
  double calcularTotalVisible() {
    List<Map<String, dynamic>> filteredData = getFilteredData();
    return filteredData.fold(0, (sum, item) => sum + (item['valor'] ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredData = getFilteredData();
    double totalVisible = calcularTotalVisible();

    return Scaffold(
      appBar: AppBar(
        title: Text('MI PRESUPUESTO'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.green], // Colores de la barra
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila con los filtros de mes y estado
              Row(
                children: [
                  // Filtro de mes
                  DropdownButton<String>(
                    value: _selectedMonth,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedMonth = newValue!;
                        _loadData();
                      });
                    },
                    items: _months.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  SizedBox(width: 10), // Espacio entre los filtros
                  // Filtro de estado (Todo, Pago, Pendiente)
                  DropdownButton<String>(
                    value: _selectedEstadoFilter,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedEstadoFilter = newValue!;
                      });
                    },
                    items: ['Todo', 'Pago', 'Pendiente'].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    color: Colors.yellow[100],
                  ),
                  child: Table(
                    defaultColumnWidth: IntrinsicColumnWidth(),
                    border: TableBorder(
                      verticalInside: BorderSide(width: 2, color: Colors.black),
                      horizontalInside: BorderSide(width: 1, color: Colors.black),
                    ),
                    children: [
                      TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('CONCEPTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('VALOR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('VERF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('ESTADO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ],
                      ),
                      ...filteredData.map((item) {
                        int index = data.indexOf(item);
                        return TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: TextFormField(
                                controller: _conceptoControllers[index],
                                onChanged: (value) {
                                  setState(() {
                                    item['concepto'] = value;
                                    _saveData(); // Guardar automáticamente
                                  });
                                },
                                style: TextStyle(
                                  color: item['verf'] == false ? Colors.red : null,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: TextFormField(
                                controller: _valorControllers[index],
                                keyboardType: TextInputType.number,
                                style: TextStyle(fontSize: 14),
                                onChanged: (value) {
                                  String formattedValue = value.replaceAll('\$', '').replaceAll('.', '');
                                  double parsedValue = double.tryParse(formattedValue) ?? 0;
                                  _valorControllers[index].value = TextEditingValue(
                                    text: formatoMoneda(parsedValue),
                                    selection: TextSelection.collapsed(offset: formatoMoneda(parsedValue).length),
                                  );
                                  item['valor'] = parsedValue;
                                  calcularTotales();
                                  _saveData(); // Guardar automáticamente
                                },
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Checkbox(
                                value: item['verf'] ?? false,
                                onChanged: (value) {
                                  setState(() {
                                    item['verf'] = value ?? false;
                                    item['estado'] =
                                    (value ?? false) ? 'PAGO' : 'PENDIENTE';
                                    calcularTotales();
                                    _saveData(); // Guardar automáticamente
                                  });
                                },
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                item['estado'] ?? 'PENDIENTE',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      // Fila de totales que se actualiza con los filtros
                      TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(
                              'TOTAL PARCIAL',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(
                              formatoMoneda(totalVisible),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: SizedBox(), // Celda vacía para VERF
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: SizedBox(), // Celda vacía para ESTADO
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        data.add({
                          'concepto': '',
                          'valor': 0,
                          'verf': false,
                          'estado': 'PENDIENTE',
                        });
                        _conceptoControllers.add(TextEditingController());
                        _valorControllers.add(TextEditingController(text: formatoMoneda(0)));
                        _saveData(); // Guardar automáticamente
                      });
                    },
                    child: Text('Agregar línea'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (data.length > 2) {
                        setState(() {
                          data.removeLast();
                          _conceptoControllers.removeLast();
                          _valorControllers.removeLast();
                          calcularTotales();
                          _saveData(); // Guardar automáticamente
                        });
                      }
                    },
                    child: Text('Eliminar última línea'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 2),
                    color: Colors.red[50],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: SizedBox()),
                          Expanded(child: Text('PESOS', style: TextStyle(fontSize: 14))),
                        ],
                      ),
                      Divider(),
                      Row(
                        children: [
                          Expanded(child: Text('TOTAL', style: TextStyle(fontSize: 14))),
                          Expanded(child: Text(formatoMoneda(totalPesos), style: TextStyle(fontSize: 14))),
                        ],
                      ),
                      Divider(),
                      Row(
                        children: [
                          Expanded(child: Text('PAGO', style: TextStyle(fontSize: 14))),
                          Expanded(child: Text(formatoMoneda(pagoPesos), style: TextStyle(fontSize: 14))),
                        ],
                      ),
                      Divider(),
                      Row(
                        children: [
                          Expanded(child: Text('PENDIENTE', style: TextStyle(fontSize: 16))),
                          Expanded(
                            child: Text(
                              formatoMoneda(pendientePesos),
                              style: TextStyle(
                                fontSize: 16,
                                color: pendientePesos != 0 ? Colors.red : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 1),
                  color: Colors.grey[200],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _disponibleController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Disponible',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          String formattedValue = value.replaceAll('\$', '').replaceAll('.', '');
                          double parsedValue = double.tryParse(formattedValue) ?? 0;
                          _disponibleController.value = TextEditingValue(
                            text: formatoMoneda(parsedValue),
                            selection: TextSelection.collapsed(offset: formatoMoneda(parsedValue).length),
                          );
                          calcularTotales();
                          _saveData(); // Guardar automáticamente
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pendiente: ${formatoMoneda(pendientePesos)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: pendientePesos != 0 ? Colors.red : null,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Faltante: ${formatoMoneda(faltante)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: faltante != 0 ? FontWeight.bold : FontWeight.normal,
                          color: faltante != 0 ? Colors.red : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}